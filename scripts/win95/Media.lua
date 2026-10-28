-- SPDX-License-Identifier: MIT
local Base=require("win95.Base")
local D=require("win95.Draw")
local M={}
local function release(w)
    local e=w.image_;if not e then return end
    w.image_=nil;e.refs=e.refs-1
    if e.refs==0 then
        if e.handle and e.handle>0 then
            if e.texture then nvgDeleteVideo(e.nvg,e.handle) else nvgDeleteImage(e.nvg,e.handle) end
        end
        w.ctx_.images_[e.key]=nil;e.texture=nil;e.handle=nil;e.nvg=nil
    end
end
local Image=Base:Extend("Win95ImageViewer");M.ImageViewer=Image
function Image:Init(p)
    p.width=p.width or 240;p.height=p.height or 150;p.pointerEvents=p.pointerEvents or "none"
    Base.Init(self,p);self.source_=p.src;self.texture_=p.texture;self.ready_=p.ready~=false
end
function Image:SetSource(src)
    release(self);self.source_=src;self.texture_=nil;self.props.src=src;self.props.texture=nil;self.status_="pending";self.notified_=false;return self
end
function Image:SetTexture(texture,ready)
    release(self);self.source_=nil;self.props.src=nil;self.texture_=texture;self.props.texture=texture;self.ready_=ready~=false
    self.status_="pending";self.notified_=false;return self
end
function Image:SetReady(ready) self.ready_=ready==true;return self end
function Image:GetStatus() return self.status_ or "pending" end
function Image:SetFit(fit) assert(fit=="contain" or fit=="cover","fit must be contain or cover");self.props.fit=fit;return self end
function Image:Load(n)
    if self.image_ or not self.ready_ then return end
    local key=self.texture_ or self.source_;if not key then return end
    self.ctx_.images_=self.ctx_.images_ or {}
    local e=self.ctx_.images_[key]
    if not e then
        local handle=self.texture_ and nvgCreateVideo(n,self.texture_) or nvgCreateImage(n,self.source_,0)
        local w,h=0,0;if handle and handle>0 then w,h=nvgImageSize(n,handle) end
        e={key=key,handle=handle or 0,width=w,height=h,nvg=n,refs=0,texture=self.texture_};self.ctx_.images_[key]=e
    end
    e.refs=e.refs+1;self.image_=e;self.status_=e.handle>0 and "ready" or "error"
end
function Image:Update()
    if self.status_ and self.status_~="pending" and not self.notified_ then
        self.notified_=true
        if self.status_=="ready" then self:Emit("ready",{width=self.image_.width,height=self.image_.height})
        else self:Emit("error",{code="image-load",source=self.source_,message="Image or texture bridge could not be loaded"}) end
    end
end
function Image:Render(n)
    local l=self:GetAbsoluteLayout();local t=self:Theme();local p=self.props
    if p.frame~=false then D.bevel(n,l,t,true,p.backgroundColor or t.paper) end
    self:Load(n);local e=self.image_
    if not self.ready_ or not e or e.handle<=0 then
        D.text(n,self.status_=="error" and (p.errorText or "Image unavailable") or (p.loadingText or "Loading..."),l.x+l.w/2,l.y+l.h/2,t,t.shadow,NVG_ALIGN_CENTER+NVG_ALIGN_MIDDLE);return
    end
    local pad=p.frame==false and 0 or 3;local box={x=l.x+pad,y=l.y+pad,w=l.w-pad*2,h=l.h-pad*2}
    local crop=p.crop or {x=0,y=0,w=e.width,h=e.height}
    if crop.w<=0 or crop.h<=0 or box.w<=0 or box.h<=0 then return end
    local scale=(p.fit=="cover" and math.max or math.min)(box.w/crop.w,box.h/crop.h)
    local w,h=crop.w*scale,crop.h*scale;local x,y=box.x+(box.w-w)/2,box.y+(box.h-h)/2
    D.clip(n,box,function()
        nvgBeginPath(n);nvgRect(n,x,y,w,h)
        nvgFillPaint(n,nvgImagePattern(n,x-crop.x*scale,y-crop.y*scale,e.width*scale,e.height*scale,0,e.handle,1));nvgFill(n)
    end)
end
function Image:Destroy()
    if self.dead_ then return end;release(self);self.texture_=nil;self.source_=nil;self.props.texture=nil;self.props.src=nil;Base.Destroy(self)
end
local Thumbnails=Base:Extend("Win95Thumbnails");M.Thumbnails=Thumbnails
function Thumbnails:Init(p)
    p.flexDirection="row";p.flexWrap="wrap";p.gap=p.gap or 6;Base.Init(self,p);self.buttons_={};self:SetItems(p.items or {})
end
function Thumbnails:SetItems(items)
    for i=#self.children,1,-1 do self.children[i]:Destroy() end
    self.props.items=items;self.buttons_={}
    for i,item in ipairs(items) do
        local key=item.id or i
        local button=self.ctx_:Button{width=self.props.itemWidth or 100,height=self.props.itemHeight or 84,text="",padding=4,disabled=item.disabled,
            onClick=function()self:SetValue(key)end}
        button:AddChild(self.ctx_:ImageViewer{src=item.src,texture=item.texture,ready=item.ready,width="100%",height="100%",fit="cover",frame=false})
        self:AddChild(button);self.buttons_[key]=button
    end
    if self.props.value then self:SetValue(self.props.value) end
end
function Thumbnails:SetValue(value)
    if not self.buttons_[value] or self.buttons_[value]:IsDisabled() then return false end
    for id,b in pairs(self.buttons_) do b.props.selected=id==value end
    Base.SetValue(self,value);return true
end
function M.stats(ctx)
    local count,refs=0,0
    for _,e in pairs(ctx.images_ or {}) do count=count+1;refs=refs+e.refs end
    return {handles=count,references=refs}
end
return M
