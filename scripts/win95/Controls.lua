-- SPDX-License-Identifier: MIT
local UI=require("urhox-libs/UI")
local Base=require("win95.Base")
local D=require("win95.Draw")
local Icons=require("win95.Icons")
local C={}
C.Panel=Base
local Frame=Base:Extend("Win95Frame");C.Frame=Frame
function Frame:Init(p) p.padding=p.padding or 2;Base.Init(self,p) end
function Frame:Render(n) D.bevel(n,self:GetAbsoluteLayout(),self:Theme(),self.props.inset,self.props.backgroundColor or self:Theme().face) end
local Label=Base:Extend("Win95Label");C.Label=Label
function Label:Init(p)
    p.pointerEvents=p.pointerEvents or "none";p.minHeight=p.minHeight or (p.context.theme.fontSize+5)
    Base.Init(self,p)
end
function Label:Update()
    if not self.props.wrap then return end
    local l=self:GetLayout();local text=self:GetText();local key=text..":"..l.w
    if self.wrapKey_~=key then
        self.wrapKey_=key
        local t=self:Theme();self.lines_=D.lines(text,math.max(1,l.w),function(s)return UI.MeasureTextWidth(s,t.fontSize,t.font)end)
        if not self.props.fixedHeight then self:SetHeight(#self.lines_*(t.fontSize+5)) end
    end
end
function Label:Render(n)
    local l=self:GetAbsoluteLayout();local t=self:Theme()
    D.clip(n,l,function()
        if self.props.wrap and self.lines_ then
            for i,line in ipairs(self.lines_) do D.text(n,line.text,l.x,l.y+(i-.5)*(t.fontSize+5),t,self.props.color) end
        else
            local x=l.x;local align=NVG_ALIGN_LEFT+NVG_ALIGN_MIDDLE
            if self.props.textAlign=="center" then x=l.x+l.w/2;align=NVG_ALIGN_CENTER+NVG_ALIGN_MIDDLE end
            if self:IsDisabled() then D.disabledText(n,self:GetText(),x,l.y+l.h/2,t,align)
            else D.text(n,self:GetText(),x,l.y+l.h/2,t,self.props.color,align,self.props.fontSize) end
        end
    end)
end
local Button=Base:Extend("Win95Button");C.Button=Button
function Button:Init(p)
    local t=p.context.theme;p.focusable=p.focusable~=false;p.height=p.height or t.controlHeight
    p.minWidth=p.minWidth or (t.density=="touch" and 44 or 26);p.paddingHorizontal=p.paddingHorizontal or 8
    p.width=p.width or math.max(p.minWidth,UI.MeasureTextWidth(p.text or "",t.fontSize,t.font)+20+(p.icon and 22 or 0))
    p.maxWidth=p.maxWidth or "100%"
    Base.Init(self,p)
end
function Button:Render(n)
    local t=self:Theme();local l=self:GetAbsoluteLayout();local down=self.state.pressed or self.props.selected
    local selected=self.props.menu and (self.state.hovered or self.state.focused or self.props.selected)
    if self.props.menu then D.rect(n,l.x,l.y,l.w,l.h,selected and t.selection or t.face)
    else D.bevel(n,l,t,down,self.props.backgroundColor or t.face) end
    local offset=down and 1 or 0;local x=l.x+l.w/2+offset;local align=NVG_ALIGN_CENTER+NVG_ALIGN_MIDDLE
    if self.props.icon then
        local size=self.props.iconSize or t.iconSize
        local ix=(self:GetText()=="") and (l.x+(l.w-size)/2) or (l.x+7)
        Icons.draw(n,self.props.icon,ix+offset,l.y+(l.h-size)/2+offset,size,self:IsDisabled())
        if self:GetText()~="" then x=l.x+size+13+offset;align=NVG_ALIGN_LEFT+NVG_ALIGN_MIDDLE end
    elseif self.props.menu then x=l.x+8;align=NVG_ALIGN_LEFT+NVG_ALIGN_MIDDLE end
    D.clip(n,{x=l.x+3,y=l.y+2,w=l.w-6,h=l.h-4},function()
        if self:IsDisabled() then D.disabledText(n,self:GetText(),x,l.y+l.h/2+offset,t,align)
        else D.text(n,self:GetText(),x,l.y+l.h/2+offset,t,selected and t.selectionText or t.text,align) end
    end)
    if self.state.focused and not self:IsDisabled() and not self.props.menu then D.focus(n,l,t) end
end
local IconButton=Button:Extend("Win95IconButton");C.IconButton=IconButton
function IconButton:Init(p) p.width=p.width or p.context.theme.controlHeight;Button.Init(self,p) end
local DesktopIcon=Button:Extend("Win95DesktopIcon");C.DesktopIcon=DesktopIcon
function DesktopIcon:Init(p) p.width=p.width or 92;p.height=p.height or 78;Button.Init(self,p) end
function DesktopIcon:Render(n)
    local l=self:GetAbsoluteLayout();local t=self:Theme();local size=self.props.iconSize or 32
    local selected=self.state.focused or self.props.selected or self.state.pressed
    Icons.draw(n,self.props.icon or "computer",l.x+(l.w-size)/2,l.y+4,size,self:IsDisabled())
    if selected then D.rect(n,l.x+2,l.y+size+9,l.w-4,l.h-size-12,t.selection) end
    D.clip(n,l,function()D.text(n,self:GetText(),l.x+l.w/2,l.y+size+22,t,self:IsDisabled() and t.disabled or t.white,NVG_ALIGN_CENTER+NVG_ALIGN_MIDDLE)end)
    if self.state.focused then D.focus(n,{x=l.x,y=l.y+size+8,w=l.w,h=l.h-size-8},t,3) end
end
local Icon=Base:Extend("Win95Icon");C.Icon=Icon
function Icon:Init(p) p.width=p.size or p.context.theme.iconSize;p.height=p.width;p.pointerEvents="none";Base.Init(self,p) end
function Icon:Render(n) local l=self:GetAbsoluteLayout();Icons.draw(n,self.props.name,l.x,l.y,math.min(l.w,l.h),self.props.disabled) end
local Separator=Base:Extend("Win95Separator");C.Separator=Separator
function Separator:Init(p) if p.vertical then p.width=p.width or 2 else p.height=p.height or 2 end;p.pointerEvents="none";Base.Init(self,p) end
function Separator:Render(n)
    local l=self:GetAbsoluteLayout();local t=self:Theme()
    if self.props.vertical then D.rect(n,l.x,l.y,1,l.h,t.shadow);D.rect(n,l.x+1,l.y,1,l.h,t.white)
    else D.rect(n,l.x,l.y,l.w,1,t.shadow);D.rect(n,l.x,l.y+1,l.w,1,t.white) end
end
local Group=Frame:Extend("Win95GroupBox");C.GroupBox=Group
function Group:Init(p) p.padding=p.padding or 10;p.paddingTop=p.paddingTop or 24;Frame.Init(self,p) end
function Group:Render(n)
    local t=self:Theme();local l=self:GetAbsoluteLayout()
    D.edge(n,l.x+1,l.y+8,l.w-2,l.h-9,t.shadow,t.white)
    local w=UI.MeasureTextWidth(self:GetText(),t.fontSize,t.font)+8
    D.rect(n,l.x+9,l.y,w,t.fontSize+2,t.face);D.text(n,self:GetText(),l.x+13,l.y+8,t)
end
local Progress=Frame:Extend("Win95ProgressBar");C.ProgressBar=Progress
function Progress:Init(p) p.height=p.height or 22;p.value=p.value or 0;p.inset=true;Frame.Init(self,p);self.phase_=0 end
function Progress:SetValue(v) Base.SetValue(self,D.clamp(tonumber(v) or 0,0,1));return self end
function Progress:Update(dt) if self.props.busy and self:Alive() then self.phase_=(self.phase_+dt*.5)%1 end end
function Progress:Render(n)
    Frame.Render(self,n);local l=self:GetAbsoluteLayout();local t=self:Theme();local w=l.w-6
    D.clip(n,{x=l.x+3,y=l.y+3,w=w,h=l.h-6},function()
        local start=self.props.busy and (self.phase_*(w+60)-60) or 0
        local finish=self.props.busy and (start+60) or w*D.clamp(self.props.value,0,1)
        for x=start,finish-6,9 do D.rect(n,l.x+3+x,l.y+3,6,l.h-6,t.selection) end
    end)
end
local Busy=Progress:Extend("Win95Busy");C.Busy=Busy
function Busy:Init(p) p.busy=true;Progress.Init(self,p) end
local Checkbox=Button:Extend("Win95Checkbox");C.Checkbox=Checkbox
function Checkbox:Init(p)
    p.value=p.value==true or p.checked==true
    p.width=p.width or UI.MeasureTextWidth(p.text or "",p.context.theme.fontSize,p.context.theme.font)+32
    Button.Init(self,p)
end
function Checkbox:OnClick(e)
    if not self:Alive() or (e and (not self.clickReady_ or not e:IsPrimaryAction())) then return true end
    self:SetValue(not self:GetValue());return Base.OnClick(self,e)
end
function Checkbox:SetChecked(v) return self:SetValue(v==true) end
function Checkbox:IsChecked() return self:GetValue()==true end
function Checkbox:Render(n)
    local l=self:GetAbsoluteLayout();local t=self:Theme();local y=l.y+(l.h-14)/2
    D.bevel(n,{x=l.x+4,y=y,w=14,h=14},t,true,self:IsDisabled() and t.face or t.paper)
    if self:GetValue() then Icons.draw(n,"check",l.x+3,y-1,16,self:IsDisabled()) end
    if self:IsDisabled() then D.disabledText(n,self:GetText(),l.x+24,l.y+l.h/2,t)
    else D.text(n,self:GetText(),l.x+24,l.y+l.h/2,t) end
    if self.state.focused then D.focus(n,l,t,2) end
end
local Toggle=Checkbox:Extend("Win95Toggle");C.Toggle=Toggle
function Toggle:Render(n) self.props.selected=self:GetValue();Button.Render(self,n) end
local Radio=Checkbox:Extend("Win95Radio");C.Radio=Radio
function Radio:OnClick(e)
    if not self:Alive() or (e and not self.clickReady_) then return true end
    if self.props.group then self.props.group:SetValue(self.props.optionValue) end
    return Base.OnClick(self,e)
end
function Radio:Render(n)
    local l=self:GetAbsoluteLayout();local t=self:Theme();local x=l.x+11;local y=l.y+l.h/2
    nvgBeginPath(n);nvgCircle(n,x,y,7);nvgFillColor(n,nvgRGBA(128,128,128,255));nvgFill(n)
    nvgBeginPath(n);nvgCircle(n,x+1,y+1,6);nvgFillColor(n,nvgRGBA(255,255,255,255));nvgFill(n)
    if self:GetValue() then D.rect(n,x-2,y-2,5,5,self:IsDisabled() and t.disabled or t.text) end
    D.text(n,self:GetText(),l.x+24,y,t,self:IsDisabled() and t.disabled or t.text)
    if self.state.focused then D.focus(n,l,t,2) end
end
function Radio:OnKeyDown(k)
    if self.ctx_:Key(self,k) then return true end
    if k==KEY_LEFT or k==KEY_UP or k==KEY_RIGHT or k==KEY_DOWN then self.props.group:Step((k==KEY_LEFT or k==KEY_UP) and -1 or 1);return true end
    return Base.OnKeyDown(self,k)
end
local RadioGroup=Base:Extend("Win95RadioGroup");C.RadioGroup=RadioGroup
function RadioGroup:Init(p)
    p.gap=p.gap or 2;Base.Init(self,p);self.buttons_={}
    for _,o in ipairs(p.options or {}) do
        local b=Radio{context=self.ctx_,text=o.label,optionValue=o.value,value=o.value==p.value,group=self,width="100%",disabled=o.disabled}
        self:AddChild(b);self.buttons_[#self.buttons_+1]=b
    end
end
function RadioGroup:SetValue(v)
    local found=false;for _,b in ipairs(self.buttons_) do if b.props.optionValue==v and not b.props.disabled then found=true end end
    if not found then return false end
    Base.SetValue(self,v);for _,b in ipairs(self.buttons_) do b.props.value=b.props.optionValue==v end;return true
end
function RadioGroup:Step(d)
    local at=1;for i,b in ipairs(self.buttons_) do if b.props.optionValue==self:GetValue() then at=i end end
    for _=1,#self.buttons_ do at=(at-1+d)%#self.buttons_+1;local b=self.buttons_[at];if b:Alive() then self:SetValue(b.props.optionValue);b:Focus();return end end
end
local Slider=Base:Extend("Win95Slider");C.Slider=Slider
function Slider:Init(p) p.focusable=true;p.height=p.height or p.context.theme.controlHeight;p.min=p.min or 0;p.max=p.max or 100;p.step=p.step or 1;p.value=p.value or p.min;assert(p.max>p.min and p.step>0,"invalid slider range");Base.Init(self,p);self.win95PanTarget_=true end
function Slider:SetValue(v) local p=self.props;Base.SetValue(self,D.clamp(p.min+math.floor(((tonumber(v) or p.min)-p.min)/p.step+.5)*p.step,p.min,p.max));return self end
function Slider:At(x) local l=self:GetAbsoluteLayout();self:SetValue(self.props.min+D.clamp((x-l.x-8)/math.max(1,l.w-16),0,1)*(self.props.max-self.props.min)) end
function Slider:OnPointerDown(e) Base.OnPointerDown(self,e);if self.pointer_==e.pointerId then self:At(e.x) end;return true end
function Slider:OnPointerMove(e) if self.pointer_==e.pointerId then self:At(e.x) end end
function Slider:OnPanStart(e)
    if self.panPointer_ and self.panPointer_~=e.pointerId then return true end
    if self:Alive() then self.panPointer_=e.pointerId;self.state.dragging=true;self:At(e.x) end;return true
end
function Slider:OnPanMove(e) if self.state.dragging and self.panPointer_==e.pointerId then self:At(e.x) end end
function Slider:OnPanEnd(e) if e and self.panPointer_~=e.pointerId then return end;if self.state.dragging then self:Emit("changeEnd",self:GetValue()) end;self.state.dragging=false;self.panPointer_=nil end
function Slider:OnPointerUp(e) if self.pointer_==e.pointerId then self:Emit("changeEnd",self:GetValue()) end;return Base.OnPointerUp(self,e) end
function Slider:OnKeyDown(k)
    if self.ctx_:Key(self,k) then return true end
    if not self:Alive() then return true end
    if k==KEY_LEFT or k==KEY_DOWN then self:SetValue(self:GetValue()-self.props.step)
    elseif k==KEY_RIGHT or k==KEY_UP then self:SetValue(self:GetValue()+self.props.step)
    elseif k==KEY_HOME then self:SetValue(self.props.min) elseif k==KEY_END then self:SetValue(self.props.max) end
end
function Slider:Render(n)
    local l=self:GetAbsoluteLayout();local t=self:Theme();local y=l.y+l.h/2
    D.bevel(n,{x=l.x+8,y=y-2,w=l.w-16,h=4},t,true)
    local ratio=(self:GetValue()-self.props.min)/(self.props.max-self.props.min)
    D.bevel(n,{x=l.x+ratio*(l.w-16),y=y-10,w=16,h=20},t,self.state.pressed,t.face)
    if self.state.focused then D.focus(n,l,t,1) end
end
return C
