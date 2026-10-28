-- SPDX-License-Identifier: MIT
local UI=require("urhox-libs/UI")
local Base=require("win95.Base")
local D=require("win95.Draw")
local M={}
local Assistant=Base:Extend("Win95Assistant")
function Assistant:Init(p)
    local character=p.character
    if not character then
        character={};for k,v in pairs(require("win95.characters.Byte")) do character[k]=v end
        character.sheet=p.context:Resource("assistant/byte.png")
    end
    p.position="absolute";p.left=p.x or 10;p.top=p.y or 10;p.width=p.width or character.width;p.height=p.height or character.height
    p.pointerEvents="box-none";p.zIndex=8000;Base.Init(self,p)
    self.queue_={};self.elapsed_=0;self.frame_=1;self.character_=character;self.stopped_=false
    self.sprite_=self.ctx_:ImageViewer{src=character.sheet,width="100%",height="100%",frame=false,fit="contain",pointerEvents="none"}
    self:AddChild(self.sprite_);self:SetCharacter(character)
end
function Assistant:SetCharacter(character)
    assert(type(character)=="table" and type(character.animations)=="table","character animations required")
    for name,action in pairs(character.animations) do
        assert(type(action.frames)=="table" and #action.frames>0,"empty animation: "..name)
        for _,f in ipairs(action.frames) do assert(f.duration and f.duration>0 and (f.src or (f.w and f.h and f.w>0 and f.h>0)),"frame needs duration and src or crop rectangle") end
    end
    self:stop();self.character_=character;self.sprite_:SetSource(character.sheet);self.stopped_=false
    if character.idle then self:play(character.idle,{loop=true}) end;return self
end
function Assistant:show()
    self:SetVisible(true);self.stopped_=false
    if not self.action_ and self.character_.idle then self:play(self.character_.idle,{loop=true}) end
    return self
end
function Assistant:hide()
    self:stop();self:SetVisible(false);self:DismissSpeech();return self
end
function Assistant:moveTo(x,y,duration,callback)
    local b=self.ctx_:Bounds();local l=self:GetLayout()
    return self.ctx_:Tween(self,{x=D.clamp(x,0,b.w-l.w),y=D.clamp(y,0,b.h-l.h)},duration,callback)
end
function Assistant:Finish(success,reason)
    local current=self.current_;self.current_=nil;self.action_=nil
    if current and current.onComplete then current.onComplete(success,reason) end
end
function Assistant:StartAction(request)
    self.current_=request;self.action_=self.character_.animations[request.name];self.frame_=1;self.elapsed_=0
    self:ApplyFrame();return self
end
function Assistant:play(name,options)
    options=options or {};assert(self.character_.animations[name],"unknown assistant action: "..tostring(name))
    local request={name=name,loop=options.loop,onComplete=options.onComplete}
    if options.queue and self.action_ and not self.current_.loop then self.queue_[#self.queue_+1]=request
    else
        self:Finish(false,"interrupted")
        local queued=self.queue_;self.queue_={}
        for _,r in ipairs(queued) do if r.onComplete then r.onComplete(false,"interrupted") end end
        self.stopped_=false;self:StartAction(request)
    end
    return self
end
function Assistant:ApplyFrame()
    local f=self.action_.frames[self.frame_]
    if f.src then
        if self.sprite_.source_~=f.src then self.sprite_:SetSource(f.src) end;self.sprite_.props.crop=nil
    else
        if self.sprite_.source_~=self.character_.sheet then self.sprite_:SetSource(self.character_.sheet) end
        self.sprite_.props.crop={x=f.x or 0,y=f.y or 0,w=f.w,h=f.h}
    end
end
function Assistant:stop()
    self.stopped_=true;self:Finish(false,"stopped")
    local queued=self.queue_ or {};self.queue_={}
    for _,r in ipairs(queued) do if r.onComplete then r.onComplete(false,"cancelled") end end
    if self.tween_ then self.tween_:cancel("stopped") end
    return self
end
function Assistant:DismissSpeech()
    if self.bubble_ then local bubble=self.bubble_;self.bubble_=nil;bubble:Destroy() end
    local cb=self.speechCallback_;self.speechCallback_=nil
    if cb then cb() end
end
function Assistant:speak(text,options)
    options=options or {};self:DismissSpeech()
    self.speechCallback_=options.onComplete;self.speechUntil_=options.duration and self.ctx_.clock_+options.duration or nil
    local b=self.ctx_:Bounds();local width=math.min(options.width or 240,math.max(80,b.w-8))
    local bubble=self.ctx_:Frame{position="absolute",width=width,padding=8,gap=4,backgroundColor=self:Theme().tooltip,zIndex=8500}
    local scroll=self.ctx_:ScrollView{width="100%",flexGrow=1,flexBasis=0,backgroundColor=self:Theme().tooltip}
    local label=self.ctx_:Label{text=tostring(text),wrap=true};scroll:AddChild(label);bubble:AddChild(scroll)
    bubble:AddChild(self.ctx_:Button{text=options.closeText or "OK",width="100%",onClick=function()self:DismissSpeech()end})
    self.ctx_.root:AddChild(bubble);self.bubble_=bubble;self.bubbleText_=tostring(text);self.bubbleWidth_=options.width or 240;self.bubbleKey_=nil;self:PositionBubble();return self
end
function Assistant:PositionBubble()
    if not self.bubble_ then return end
    local b=self.ctx_:Bounds();local l=self:GetLayout();local width=math.min(self.bubbleWidth_,math.max(44,b.w-8))
    local key=table.concat({b.w,b.h,l.x,l.y,width},":");if key==self.bubbleKey_ then return end;self.bubbleKey_=key
    local text=self.bubbleText_;local t=self:Theme()
    local lines=D.lines(text,width-16,function(s)return UI.MeasureTextWidth(s,t.fontSize,t.font)end)
    local height=math.min(b.h-8,#lines*(t.fontSize+5)+t.controlHeight+24)
    self.bubble_:SetStyle{width=width,height=height,left=D.clamp(l.x-width/2,4,b.w-width-4),top=D.clamp(l.y-height-5,4,b.h-height-4)}
end
function Assistant:Update(dt)
    if self.dead_ or self.props.visible==false then return end
    if self.action_ and not self.stopped_ then
        self.elapsed_=self.elapsed_+dt;local steps=0
        while self.action_ and self.elapsed_>=self.action_.frames[self.frame_].duration and steps<100 do
            self.elapsed_=self.elapsed_-self.action_.frames[self.frame_].duration;self.frame_=self.frame_+1;steps=steps+1
            if self.frame_>#self.action_.frames then
                local loop=self.current_.loop
                if loop==nil then loop=self.action_.loop end
                if loop then self.frame_=1
                else
                    self:Finish(true,"completed")
                    if #self.queue_>0 then self:StartAction(table.remove(self.queue_,1))
                    elseif self.character_.idle then self:StartAction{name=self.character_.idle,loop=true} end
                end
            end
            if self.action_ then self:ApplyFrame() end
        end
    end
    local b=self.ctx_:Bounds();local l=self:GetLayout()
    if l.x+l.w>b.w or l.y+l.h>b.h then self:SetStyle{left=D.clamp(l.x,0,b.w-l.w),top=D.clamp(l.y,0,b.h-l.h)} end
    if self.bubble_ then
        self:PositionBubble()
        if self.speechUntil_ and self.ctx_.clock_>=self.speechUntil_ then self:DismissSpeech() end
    end
end
function Assistant:Destroy()
    if self.dead_ then return end;self:stop();self:DismissSpeech();Base.Destroy(self);self.character_=nil;self.sprite_=nil
end
function M.new(ctx,p)
    local props={};for k,v in pairs(p) do props[k]=v end;props.context=ctx
    local a=Assistant(props);ctx.root:AddChild(a);return a
end
return M
