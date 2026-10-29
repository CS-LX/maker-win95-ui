-- SPDX-License-Identifier: MIT
local UI=require("urhox-libs/UI")
local Base=require("win95.Base")
local C=require("win95.Controls")
local D=require("win95.Draw")
local Icons=require("win95.Icons")
local M={}
local function notify(ctx)
    if ctx.taskbar_ and not ctx.taskbar_.dead_ then ctx.taskbar_:Sync() end
    if ctx.options.onWindowsChanged then ctx.options.onWindowsChanged(ctx.windows_,ctx.active_) end
end
local Drag=Base:Extend("Win95WindowDrag")
function Drag:Init(p) p.focusable=false;Base.Init(self,p);self.win95PanTarget_=true end
function Drag:Begin(x,y)
    if not self:Alive() or self.props.window.maximized_ then return false end
    local w=self.props.window;self.origin_={x=x,y=y,left=w.rect_.x,top=w.rect_.y,w=w.rect_.w,h=w.rect_.h};return true
end
function Drag:OnPointerDown(e)
    Base.OnPointerDown(self,e);if self.pointer_==e.pointerId then self:Begin(e.x,e.y) end;return true
end
function Drag:Apply(x,y)
    if not self.origin_ or not self:Alive() then return end
    local w=self.props.window;local o=self.origin_;local dx,dy=x-o.x,y-o.y
    if self.props.resize then w:SetRect(o.left,o.top,o.w+dx,o.h+dy)
    else w:SetRect(o.left+dx,o.top+dy,o.w,o.h) end
end
function Drag:OnPointerMove(e) if self.pointer_==e.pointerId then self:Apply(e.x,e.y) end end
function Drag:OnPointerCancel(e)
    if self.pointer_~=nil and self.pointer_~=e.pointerId then return true end
    Base.OnPointerCancel(self,e);self.origin_=nil
end
function Drag:OnPointerUp(e) Base.OnPointerUp(self,e);if not self.state.dragging then self.origin_=nil end end
function Drag:OnPanStart(e)
    if self.panPointer_ and self.panPointer_~=e.pointerId then return true end
    if self:Begin(e.x-e.totalDeltaX,e.y-e.totalDeltaY) then self.state.dragging=true;self.panPointer_=e.pointerId;return true end
    return true
end
function Drag:OnPanMove(e) if self.state.dragging and self.panPointer_==e.pointerId then self:Apply(e.x,e.y) end end
function Drag:OnPanEnd(e) if e and self.panPointer_~=e.pointerId then return end;self.state.dragging=false;self.panPointer_=nil;self.origin_=nil end
function Drag:Render(n)
    local l=self:GetAbsoluteLayout();local t=self:Theme();local w=self.props.window
    if self.props.resize then
        for length=3,11,4 do for step=0,length do
            D.rect(n,l.x+l.w-3-step,l.y+l.h-3-length+step,1,1,t.shadow)
            D.rect(n,l.x+l.w-2-step,l.y+l.h-3-length+step,1,1,t.white)
        end end
    else
        Icons.draw(n,w.props.icon or "computer",l.x+2,math.floor(l.y+(l.h-16)/2),16,false)
        D.clip(n,{x=l.x+22,y=l.y,w=math.max(0,l.w-24),h=l.h},function()D.text(n,w.props.title or "Window",l.x+22,l.y+l.h/2,t,w.active_ and t.titleText or t.inactiveTitleText,nil,nil,true)end)
    end
end
local Window=C.Frame:Extend("Win95Window")
function Window:Init(p)
    p.position="absolute";p.padding=2;p.gap=0;p.overflow="hidden";C.Frame.Init(self,p)
    self.win95Window_=true;self.active_=false;self.minimized_=false;self.maximized_=false
    self.rect_={x=p.x or 24,y=p.y or 24,w=p.width or 460,h=p.height or 320}
    local t=self:Theme();local row=self.ctx_:Panel{height=t.titleHeight,flexShrink=0,flexDirection="row",gap=2,paddingRight=t.density=='touch' and 0 or 2,alignItems='center',backgroundColor=t.inactiveTitle}
    self.titleRow_=row
    self.titlebar_=Drag{context=self.ctx_,window=self,flexGrow=1,flexShrink=1,height='100%'};row:AddChild(self.titlebar_)
    local function control(icon,callback)
        local b=self.ctx_:IconButton{icon=icon,width=t.titleButtonWidth,height=t.titleButtonHeight,minWidth=t.titleButtonWidth,iconSize=12,paddingHorizontal=0,titleControl=true,onClick=callback};row:AddChild(b);return b
    end
    if p.minimizable==true or (p.minimizable~=false and self.ctx_.taskbar_) then self.minButton_=control("minimize",function()self:Minimize()end) end
    if p.maximizable~=false then self.maxButton_=control("maximize",function()if self.maximized_ then self:Restore() else self:Maximize() end end) end
    if p.closable~=false then self.closeButton_=control("close",function()self:Close()end) end
    self:AddChild(row)
    self.content=self.ctx_:ScrollView{width="100%",flexGrow=1,flexBasis=0,backgroundColor=t.face,padding=p.contentPadding or 6,gap=t.gap,chrome=false}
    self:AddChild(self.content)
    if p.resizable~=false then
        self.grip_=Drag{context=self.ctx_,window=self,resize=true,position="absolute",right=0,bottom=0,width=t.density=="touch" and 44 or 20,height=t.density=="touch" and 44 or 20}
        self:AddChild(self.grip_)
    end
    if p.content then self.content:AddChild(p.content) end
end
function Window:Render(n)
    local t=self:Theme();D.window(n,self:GetAbsoluteLayout(),t)
    self.titleRow_.props.backgroundColor=self.active_ and t.title or t.inactiveTitle
end
function Window:SetRect(x,y,w,h)
    local b=self.ctx_:Bounds();if b.w<1 or b.h<1 then b={w=800,h=600} end
    local reserve=self.ctx_.taskbar_ and self.ctx_.theme.controlHeight+6 or 0
    local hmax=math.max(1,b.h-reserve)
    w=D.clamp(w,math.min(self.props.minWidth or 200,b.w),b.w)
    h=D.clamp(h,math.min(self.props.minHeight or 120,hmax),hmax)
    x=D.clamp(x,0,b.w-w);y=D.clamp(y,0,hmax-h)
    self.rect_={x=x,y=y,w=w,h=h};self:SetStyle{left=x,top=y,width=w,height=h}
    self:Emit("rect",self.rect_);return self
end
function Window:Constrain()
    if self.dead_ then return end
    if self.maximized_ then local b=self.ctx_:Bounds();self:SetRect(0,0,b.w,b.h)
    else local r=self.rect_;self:SetRect(r.x,r.y,r.w,r.h) end
end
function Window:SetTitle(title) self.props.title=title;notify(self.ctx_) end
function Window:GetWindowState()
    local r=self.rect_
    return {active=self.active_,minimized=self.minimized_,maximized=self.maximized_,visible=self.props.visible~=false,
        rect={x=r.x,y=r.y,w=r.w,h=r.h}}
end
function Window:Minimize()
    if self.modal_ then return end
    self.minimized_=true;self:SetVisible(false)
    if self.ctx_.active_==self then self.ctx_.active_=nil;self.active_=false end
    for i=#self.ctx_.windows_,1,-1 do local w=self.ctx_.windows_[i];if w~=self and not w.minimized_ and not w.dead_ then M.activate(self.ctx_,w);break end end
    notify(self.ctx_);self:Emit("minimize")
end
function Window:Restore()
    if self.maximized_ and not self.minimized_ then
        self.maximized_=false;local r=self.restoreRect_;if r then self:SetRect(r.x,r.y,r.w,r.h) end
    end
    self.minimized_=false;self:SetVisible(true);if self.maxButton_ then self.maxButton_.props.icon=self.maximized_ and "restore" or "maximize" end
    M.activate(self.ctx_,self);self:Emit("restore")
end
function Window:Maximize()
    if not self.maximized_ then self.restoreRect_=self.rect_ end
    self.maximized_=true;self.minimized_=false;self:SetVisible(true);self:Constrain()
    if self.maxButton_ then self.maxButton_.props.icon="restore" end;M.activate(self.ctx_,self);self:Emit("maximize")
end
function Window:Close()
    if self.dead_ then return end
    if self.props.beforeClose and self.props.beforeClose(self)==false then return end
    if self.modal_ then self.modal_.cancel();return end
    self:Emit("close");self:Destroy()
end
function Window:Destroy()
    if self.dead_ then return end
    local ctx=self.ctx_
    for i=#ctx.windows_,1,-1 do if ctx.windows_[i]==self then table.remove(ctx.windows_,i) end end
    if ctx.active_==self then ctx.active_=nil end
    C.Frame.Destroy(self)
    if not ctx.dead_ then
        for i=#ctx.windows_,1,-1 do local w=ctx.windows_[i];if not w.minimized_ and not w.dead_ then M.activate(ctx,w);break end end
        notify(ctx)
    end
end
function M.create(ctx,p)
    local props={};for k,v in pairs(p) do props[k]=v end;props.context=ctx
    local w=Window(props);ctx.windows_[#ctx.windows_+1]=w;ctx.windowLayer:AddChild(w)
    UI.Layout();w:Constrain();M.activate(ctx,w);notify(ctx);return w
end
function M.activate(ctx,w)
    if w.dead_ or w.minimized_ then return end
    local modal=ctx.modalStack_[#ctx.modalStack_];if modal and modal.window~=w then return end
    for _,other in ipairs(ctx.windows_) do other.active_=other==w end
    ctx.serial_=ctx.serial_+1;w:SetStyle{zIndex=ctx.serial_};ctx.active_=w;notify(ctx)
end
function M.modal(ctx,p)
    local previous=UI.GetFocus();local oldActive=ctx.active_;local b=ctx:Bounds()
    ctx:CloseMenu();ctx:CancelInput()
    local blocker=ctx:Panel{position="absolute",left=0,top=0,width="100%",height="100%",backgroundColor={0,0,0,64},zIndex=100+#ctx.modalStack_}
    ctx.overlayLayer:AddChild(blocker)
    local props={};for k,v in pairs(p) do props[k]=v end
    props.context=ctx;props.width=math.min(p.width or 360,b.w);props.height=math.min(p.height or 220,b.h)
    props.x=(b.w-props.width)/2;props.y=(b.h-props.height)/2;props.minimizable=false;props.maximizable=false;props.resizable=false
    local w=Window(props);blocker:AddChild(w);w.active_=true;w:Constrain()
    local modal={window=w,blocker=blocker,previous=previous};w.modal_=modal
    local function finish(value)
        if modal.closed then return end;modal.closed=true
        for i=#ctx.modalStack_,1,-1 do if ctx.modalStack_[i]==modal then table.remove(ctx.modalStack_,i) end end
        ctx:CloseMenu();blocker:Destroy()
        if oldActive and not oldActive.dead_ then M.activate(ctx,oldActive) end
        if previous and previous.node and (not previous.Alive or previous:Alive()) then UI.SetFocus(previous) end
        if p.onResult then p.onResult(value) end
    end
    modal.cancel=function()finish(false)end;modal.confirm=function()finish(true)end
    modal.close=finish;ctx.modalStack_[#ctx.modalStack_+1]=modal
    local focus=ctx:Focusables(w);UI.SetFocus(focus[1] or w)
    return modal
end
function M.message(ctx,p)
    local modal=M.modal(ctx,{title=p.title or "Message",width=p.width or 360,height=p.height or 220,onResult=p.onResult})
    local body=modal.window.content
    local row=ctx:Panel{flexDirection="row",gap=12,minHeight=70}
    row:AddChild(ctx:Icon{name=p.icon or "info",size=32})
    row:AddChild(ctx:Label{text=p.message or "",wrap=true,flexGrow=1,flexShrink=1,flexBasis=0})
    body:AddChild(row)
    local buttons=ctx:Panel{flexDirection="row",flexWrap="wrap",justifyContent="flex-end",gap=8}
    local ok=ctx:Button{text=p.confirmText or "OK",width=90,onClick=modal.confirm};buttons:AddChild(ok)
    if p.cancel~=false then buttons:AddChild(ctx:Button{text=p.cancelText or "Cancel",width=90,onClick=modal.cancel}) end
    body:AddChild(buttons);ok:Focus();return modal
end
local Taskbar=C.Frame:Extend("Win95Taskbar")
function Taskbar:Init(p)
    local ctx=p.context;p.position="absolute";p.bottom=0;p.left=0;p.width="100%";p.height=ctx.theme.controlHeight+6;p.flexDirection="row";p.gap=3;p.padding=3;p.zIndex=9000
    C.Frame.Init(self,p);self.tasks_={}
    self.start_=ctx:Button{text=p.text or "Start",icon="start",onClick=function(button)ctx:StartMenu{anchor=button,above=true,items=self.props.items or {}}end}
    self:AddChild(self.start_)
    self.list_=ctx:ScrollView{flexGrow=1,flexBasis=0,height="100%",scrollX=true,scrollY=false,flexDirection="row",gap=3,showScrollbar=false,backgroundColor=ctx.theme.face}
    self:AddChild(self.list_)
end
function Taskbar:Sync()
    local exists={}
    for _,w in ipairs(self.ctx_.windows_) do
        if not w.dead_ then
            exists[w]=true;local b=self.tasks_[w]
            if not b then
                b=self.ctx_:Button{width=128,icon=w.props.icon or "computer",onClick=function()
                    if w.minimized_ then w:Restore() elseif w.active_ then w:Minimize() else M.activate(self.ctx_,w);local f=self.ctx_:Focusables(w);if f[1] then f[1]:Focus() end end
                end}
                self.tasks_[w]=b;self.list_:AddChild(b)
            end
            b:SetText(w.props.title or "Window");b.props.selected=w.active_ and not w.minimized_
        end
    end
    for w,b in pairs(self.tasks_) do if not exists[w] then b:Destroy();self.tasks_[w]=nil end end
end
function Taskbar:Destroy()
    if self.dead_ then return end
    if self.ctx_.taskbar_==self then self.ctx_.taskbar_=nil end
    C.Frame.Destroy(self);self.tasks_={}
end
function M.taskbar(ctx,p)
    assert(not ctx.taskbar_,"one Taskbar per context")
    local props={};for k,v in pairs(p) do props[k]=v end;props.context=ctx
    local bar=Taskbar(props);ctx.taskbar_=bar;ctx.root:AddChild(bar);bar:Sync()
    for _,w in ipairs(ctx.windows_) do w:Constrain() end;return bar
end
function M.desktop(ctx,p)
    local desk=ctx:Panel{width="100%",height="100%",backgroundColor=p.backgroundColor or ctx.theme.desktop,padding=12,gap=8,flexWrap="wrap",alignContent="flex-start"}
    ctx:Add(desk)
    for _,app in ipairs(p.apps or {}) do
        desk:AddChild(ctx:DesktopIcon{text=app.label,icon=app.icon or "computer",width=p.iconWidth or 92,onClick=function()app.open(ctx)end,tooltip=app.description})
    end
    return desk
end
return M
