-- SPDX-License-Identifier: MIT
local UI=require("urhox-libs/UI")
local D=require("win95.Draw")
local Base=UI.Widget:Extend("Win95Base")
function Base.adopt(w,p)
    w.ctx_=assert(p.context,"use a win95 context factory")
    w.focusable=p.focusable==true
    w.ctx_.widgets_[w]=true
    w.dead_=false
end
function Base:Init(p)
    Base.adopt(self,p);UI.Widget.Init(self,p)
end
function Base:Theme() return self.ctx_.theme end
function Base:Alive()
    if self.dead_ or not self.ctx_ or self.ctx_.dead_ then return false end
    local w=self
    while w do
        if w.dead_ or w.props.visible==false or w.props.disabled then return false end
        w=w.parent
    end
    return true
end
function Base:IsDisabled() return not self:Alive() end
function Base:Emit(name,...)
    self:DispatchEvent(name,self,...)
    local cb=self.props["on"..name:sub(1,1):upper()..name:sub(2)]
    if cb then cb(self,...) end
end
function Base:SetDisabled(v)
    self.props.disabled=v==true
    if v then self.ctx_:Release(self) end
    return self
end
function Base:SetVisible(v)
    if not v and self.ctx_ then self.ctx_:Release(self) end
    UI.Widget.SetVisible(self,v);return self
end
function Base:SetText(v) self.props.text=tostring(v or "");return self end
function Base:GetText() return self.props.text or "" end
function Base:SetValue(v)
    if v~=self.props.value then self.props.value=v;self:Emit("change",v) end
    return self
end
function Base:GetValue() return self.props.value end
function Base:Focus()
    if self:Alive() and self.focusable then UI.SetFocus(self) end
    return self
end
function Base:OnFocus() self.state.focused=true;self.ctx_:ActivateOwner(self);self:Emit("focus") end
function Base:OnBlur() self.state.focused=false;self.state.pressed=false;self:Emit("blur") end
function Base:OnPointerEnter(e) self.state.hovered=true;if self.props.tooltip then self.ctx_:ShowTooltip(self,self.props.tooltip) end end
function Base:OnPointerLeave(e) self.state.hovered=false;if self.ctx_ then self.ctx_:HideTooltip(self) end end
function Base:OnPointerDown(e)
    if not self:Alive() then return true end
    self.ctx_:ActivateOwner(self)
    if e.button==MOUSEB_RIGHT and self.props.contextMenu then
        self.ctx_:PopupMenu{items=self.props.contextMenu,anchor=self};return true
    end
    if not e:IsPrimaryAction() then return true end
    if self.pointer_~=nil then return true end
    -- Ignore synthetic mouse input immediately following a touch belonging to this context.
    if e.pointerType=="mouse" and self.ctx_.clock_<self.ctx_.touchUntil_ then return true end
    if e.pointerType=="touch" then self.ctx_.touchUntil_=self.ctx_.clock_+.6 end
    self.pointer_=e.pointerId;self.ctx_.captures_[e.pointerId]=self
    self.state.pressed=true;self.clickReady_=false
    self:Emit("press",e);return true
end
function Base:OnPointerUp(e)
    self.clickReady_=self.pointer_==e.pointerId and self:Alive()
    if self.pointer_==e.pointerId then
        self.ctx_.captures_[e.pointerId]=nil;self.pointer_=nil;self.state.pressed=false
    end
    return true
end
function Base:OnPointerCancel(e)
    if self.pointer_~=nil and e and e.pointerId~=self.pointer_ then return true end
    if self.pointer_~=nil and self.ctx_ then self.ctx_.captures_[self.pointer_]=nil end
    self.pointer_=nil;self.panPointer_=nil;self.clickReady_=false;self.state.pressed=false;self.state.dragging=false
    self:Emit("cancel",e);return true
end
function Base:OnClick(e)
    if not self:Alive() then return true end
    if e and (not self.clickReady_ or not e:IsPrimaryAction()) then return true end
    self.clickReady_=false;self:Emit("click",e);return true
end
function Base:OnKeyDown(key)
    if not self:Alive() then return true end
    if self.ctx_:Key(self,key) then return true end
    if self.focusable and (key==KEY_RETURN or key==KEY_KP_ENTER or key==KEY_SPACE) then self:OnClick();return true end
end
function Base:Render(n)
    if self.props.backgroundColor then local l=self:GetAbsoluteLayout();D.rect(n,l.x,l.y,l.w,l.h,self.props.backgroundColor) end
end
function Base.cleanup(w)
    if w.dead_ then return false end
    if w.ctx_ then w.ctx_:Release(w);w.ctx_.widgets_[w]=nil end
    w.dead_=true
    if w.tween_ then w.tween_:cancel("destroyed");w.tween_=nil end
    w.eventListeners_=nil
    return true
end
function Base:Destroy()
    if not Base.cleanup(self) then return end
    UI.Widget.Destroy(self)
    for k in pairs(self.props) do if type(self.props[k])=="function" then self.props[k]=nil end end
    self.props.children=nil;self.props.context=nil;self.ctx_=nil
end
return Base
