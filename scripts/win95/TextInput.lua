-- SPDX-License-Identifier: MIT
-- Editing, clipboard and platform text-input activation are inherited from the engine TextField.
local UI=require("urhox-libs/UI")
local Native=require("urhox-libs/UI/Widgets/TextField")
local Base=require("win95.Base")
local D=require("win95.Draw")
local M={}
local Text=Native:Extend("Win95TextInput");M.TextInput=Text
for _,name in ipairs({"Theme","Alive","IsDisabled","Emit","Focus","SetVisible","SetDisabled"}) do Text[name]=Base[name] end
function Text:Init(p)
    local t=p.context.theme;p.focusable=true;p.height=p.height or t.controlHeight
    p.borderRadius=0;p.borderWidth=0;p.focusedBorderWidth=0;p.paddingHorizontal=5
    p.fontSize=t.fontSize/UI.Theme.FontSize(1);p.fontFamily=t.font
    p.backgroundColor=t.paper;p.focusedBgColor=t.paper;p.filledBgColor=t.paper;p.disabledBgColor=t.face
    p.textColor=t.text;p.disabledTextColor=t.disabled;p.placeholderColor=t.shadow;p.cursorColor=t.text;p.selectionBgColor=t.selection
    p.onPointerDown=p.onPointerDown or function() end
    Base.adopt(self,p);Native.Init(self,p)
    self.focusable=true;self.win95PanTarget_=true
end
function Text:SetValue(value)
    value=tostring(value or "")
    if not self.multiline_ then value=value:gsub("[\r\n]","") else value=value:gsub("\r\n","\n"):gsub("\r","\n") end
    if self.props.maxLength then value=D.sub(value,1,self.props.maxLength) end
    if self.props.validate then
        local ok,reason=self.props.validate(value)
        if not ok then self.error_=reason or "Invalid value";self:Emit("invalid",value,self.error_);return self end
    end
    local previous=self.props.value;self.error_=nil;Native.SetValue(self,value)
    if previous~=self.props.value then self:DispatchEvent("change",self,self.props.value) end
    local length=utf8.len(value) or #value
    self.state.cursorPos=math.min(self.state.cursorPos or 0,length);return self
end
function Text:OnTextInput(text)
    if not self:Alive() then return end
    local before=self.props.value;local cursor=self.state.cursorPos
    if not self.multiline_ then text=text:gsub("[\r\n]","") end
    Native.OnTextInput(self,text)
    if self.error_ and before==self.props.value then self.state.cursorPos=cursor end
    self.state.cursorPos=D.clamp(self.state.cursorPos,0,utf8.len(self.props.value))
end
function Text:OnKeyDown(k)
    if not self:Alive() then return true end
    if self.ctx_:Key(self,k) then return true end
    local cursor=self.state.cursorPos;local anchor=self.anchor_ or cursor
    local shift=input and input:GetQualifierDown(QUAL_SHIFT)
    Native.OnKeyDown(self,k)
    if shift and (k==KEY_LEFT or k==KEY_RIGHT or k==KEY_HOME or k==KEY_END) then
        self.anchor_=anchor;self.state.selectionStart=anchor;self.state.selectionEnd=self.state.cursorPos
    else self.anchor_=nil end
    return true
end
function Text:OnPointerDown(e)
    if not self:Alive() then return true end
    Base.OnPointerDown(self,e)
    if self.pointer_==e.pointerId then Native.OnPointerDown(self,e) end
    return true
end
function Text:OnPointerMove(e) if self.pointer_==e.pointerId and self:Alive() then Native.OnPointerMove(self,e) end end
function Text:OnPointerUp(e)
    if self.pointer_==e.pointerId and self:Alive() then Native.OnPointerUp(self,e) end
    return Base.OnPointerUp(self,e)
end
function Text:OnClick(e) if self:Alive() and self.clickReady_ then Native.OnClick(self,e) end;self.clickReady_=false end
function Text:OnPointerCancel(e)
    self.isDragging_=false;self.pendingActivation_=false;Base.OnPointerCancel(self,e)
end
function Text:OnFocus() if self:Alive() then self.ctx_:ActivateOwner(self);Native.OnFocus(self) end end
function Text:OnBlur() Native.OnBlur(self);self.anchor_=nil end
function Text:Render(n)
    Native.Render(self,n);local t=self:Theme();local l=self:GetAbsoluteLayout();D.input(n,l,t)
    if self.error_ then D.edge(n,l.x,l.y,l.w,l.h,t.error,t.error) end
end
function Text:Destroy()
    if self.dead_ then return end
    if self.state.focused then self:OnBlur() end
    Base.Destroy(self)
end
local Area=Text:Extend("Win95TextArea");M.TextArea=Area
function Area:Init(p) self.multiline_=true;self.scrollY_=0;p.height=p.height or 112;Text.Init(self,p) end
function Area:Lines()
    local l=self:GetAbsoluteLayout();local t=self:Theme();local key=self.props.value..":"..l.w
    if self.linesKey_~=key then
        self.linesKey_=key;self.lines_=D.lines(self.props.value,math.max(1,l.w-14),function(s)return UI.MeasureTextWidth(s,t.fontSize,t.font)end)
    end
    return self.lines_
end
function Area:CursorLine()
    local rows=self:Lines();local pos=self.state.cursorPos
    for i=#rows,1,-1 do if pos>=rows[i].first then return i,rows[i] end end
    return 1,rows[1]
end
function Area:At(x,y)
    local l=self:GetAbsoluteLayout();local step=self:Theme().fontSize+6;local rows=self:Lines()
    local i=D.clamp(math.floor((y-l.y-5+self.scrollY_)/step)+1,1,#rows)
    local row=rows[i];local px=x-l.x-5;local nearest=1;local dist=math.huge
    for j,v in ipairs(row.positions) do if math.abs(v-px)<dist then nearest=j;dist=math.abs(v-px) end end
    return row.first+nearest-1
end
function Area:EnsureCursor()
    local i=self:CursorLine();local step=self:Theme().fontSize+6;local l=self:GetLayout()
    self.scrollY_=D.clamp(self.scrollY_,(i*step)-(l.h-10),(i-1)*step)
    self.scrollY_=math.max(0,self.scrollY_)
end
function Area:OnKeyDown(k)
    if not self:Alive() or self.ctx_:Key(self,k) then return true end
    local ctrl=input and input:GetQualifierDown(QUAL_CTRL)
    if (k==KEY_RETURN or k==KEY_KP_ENTER) and not ctrl then self:OnTextInput("\n")
    elseif k==KEY_UP or k==KEY_DOWN or ((k==KEY_HOME or k==KEY_END) and not ctrl) then
        local i,row=self:CursorLine();local rows=self:Lines();local old=self.state.cursorPos
        if k==KEY_HOME then self.state.cursorPos=row.first
        elseif k==KEY_END then self.state.cursorPos=row.last
        else
            local nextRow=rows[D.clamp(i+(k==KEY_UP and -1 or 1),1,#rows)]
            self.state.cursorPos=nextRow.first+math.min(old-row.first,nextRow.last-nextRow.first)
        end
        if input and input:GetQualifierDown(QUAL_SHIFT) then self.anchor_=self.anchor_ or old;self.state.selectionStart=self.anchor_;self.state.selectionEnd=self.state.cursorPos
        else self:ClearSelection();self.anchor_=nil end
    else Text.OnKeyDown(self,k) end
    self:EnsureCursor();return true
end
function Area:OnTextInput(s) Text.OnTextInput(self,s);self:EnsureCursor() end
function Area:OnPointerDown(e)
    Text.OnPointerDown(self,e)
    if self.pointer_==e.pointerId and e:IsPrimaryAction() then self.state.cursorPos=self:At(e.x,e.y);self.dragAnchor_=self.state.cursorPos;self:ClearSelection() end
end
function Area:OnPointerMove(e)
    if self.pointer_~=e.pointerId or not self:Alive() then return end
    if e.pointerType=="touch" then return end
    self.state.cursorPos=self:At(e.x,e.y);self.state.selectionStart=self.dragAnchor_;self.state.selectionEnd=self.state.cursorPos
end
function Area:OnPanStart(e)
    if self.panPointer_ and self.panPointer_~=e.pointerId then return true end
    self.panPointer_=e.pointerId;self.state.dragging=true
    if e.pointerType=="mouse" then self.mouseSelecting_=true;return true end
    self.mouseSelecting_=false;self.panY_=self.scrollY_;return true
end
function Area:OnPanMove(e)
    if self.panPointer_~=e.pointerId then return end
    if self.mouseSelecting_ then
        self.state.cursorPos=self:At(e.x,e.y);self.state.selectionStart=self.dragAnchor_;self.state.selectionEnd=self.state.cursorPos
    else self.scrollY_=D.clamp(self.panY_-e.totalDeltaY,0,math.max(0,#self:Lines()*(self:Theme().fontSize+6)-self:GetLayout().h+10)) end
end
function Area:OnPanEnd(e) if e and self.panPointer_~=e.pointerId then return end;self.state.dragging=false;self.panPointer_=nil;self.mouseSelecting_=nil end
function Area:OnWheel(_,dy) self.scrollY_=D.clamp(self.scrollY_-dy*30,0,math.max(0,#self:Lines()*(self:Theme().fontSize+6)-self:GetLayout().h+10));return true end
function Area:Render(n)
    local l=self:GetAbsoluteLayout();local t=self:Theme();local step=t.fontSize+6
    D.rect(n,l.x,l.y,l.w,l.h,self:IsDisabled() and t.face or t.paper);D.input(n,l,t)
    local rows=self:Lines();local a,b=self:GetSelectionRange();local cursorI,cursorRow=self:CursorLine()
    D.clip(n,{x=l.x+3,y=l.y+3,w=l.w-6,h=l.h-6},function()
        for i,row in ipairs(rows) do
            local y=l.y+5+(i-1)*step-self.scrollY_
            if y+step>=l.y and y<l.y+l.h then
                if a and b then
                    local first=math.max(a,row.first);local last=math.min(b,row.last)
                    if last>first then D.rect(n,l.x+5+row.positions[first-row.first+1],y,row.positions[last-row.first+1]-row.positions[first-row.first+1],step,t.selection) end
                end
                D.text(n,row.text,l.x+5,y+step/2,t,self:IsDisabled() and t.disabled or t.text)
                if a and b and b>row.first and a<row.last then
                    local first=math.max(a,row.first);local last=math.min(b,row.last)
                    D.text(n,D.sub(row.text,first-row.first+1,last-row.first),l.x+5+row.positions[first-row.first+1],y+step/2,t,t.selectionText)
                end
            end
        end
        if self.state.focused and self.state.cursorBlink then
            local x=l.x+5+(cursorRow.positions[self.state.cursorPos-cursorRow.first+1] or 0)
            D.rect(n,x,l.y+5+(cursorI-1)*step-self.scrollY_,1,step,t.text)
        end
        if self.props.value=="" and not self.state.focused then D.text(n,self.props.placeholder,l.x+5,l.y+5+step/2,t,t.shadow) end
    end)
end
local Number=Base:Extend("Win95NumberInput");M.NumberInput=Number
function Number:Init(p)
    p.flexDirection="row";p.height=p.height or p.context.theme.controlHeight;p.min=p.min or -math.huge;p.max=p.max or math.huge;p.step=p.step or 1
    assert(p.max>=p.min and p.step>0,"invalid number range");p.value=D.clamp(tonumber(p.value) or 0,p.min,p.max)
    Base.Init(self,p)
    self.input_=self.ctx_:TextInput{value=tostring(p.value),width="auto",flexGrow=1,flexShrink=1,
        validate=function(v) return v=="" or v=="-" or v=="." or v=="-." or tonumber(v)~=nil,"Enter a number" end,
        onChange=function(_,v) local n=tonumber(v);if n and n>=p.min and n<=p.max then Base.SetValue(self,n) end end,
        onBlur=function() self:Commit() end,onSubmit=function() self:Commit() end}
    self:AddChild(self.input_)
    self:AddChild(self.ctx_:IconButton{icon="minus",onClick=function() self:SetValue(self:GetValue()-p.step) end})
    self:AddChild(self.ctx_:IconButton{icon="plus",onClick=function() self:SetValue(self:GetValue()+p.step) end})
end
function Number:SetValue(v)
    v=tonumber(v);if not v or v~=v or v==math.huge or v==-math.huge then return false end
    v=D.clamp(v,self.props.min,self.props.max);Base.SetValue(self,v)
    if self.input_ then self.input_:SetValue(tostring(v)) end;return true
end
function Number:Commit() local n=tonumber(self.input_:GetValue()) or self:GetValue();self:SetValue(n) end
return M
