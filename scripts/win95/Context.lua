-- SPDX-License-Identifier: MIT
local UI=require("urhox-libs/UI")
local Input=require("urhox-libs/UI/Core/Input")
local Pointer=require("urhox-libs/UI/Core/PointerEvent")
local Gesture=require("urhox-libs/UI/Core/Gesture")
local Base=require("win95.Base")
local Theme=require("win95.Theme")
local Tween=require("win95.Tween")
local D=require("win95.Draw")
---@class Win95Context
---@field menu_ any
---@field active_ any
---@field Frame fun(self:Win95Context, props:table):any
---@field Label fun(self:Win95Context, props:table):any
---@field Panel fun(self:Win95Context, props:table):any
---@field Button fun(self:Win95Context, props:table):any
---@field IconButton fun(self:Win95Context, props:table):any
---@field Icon fun(self:Win95Context, props:table):any
---@field DesktopIcon fun(self:Win95Context, props:table):any
---@field Separator fun(self:Win95Context, props:table):any
---@field GroupBox fun(self:Win95Context, props:table):any
---@field ProgressBar fun(self:Win95Context, props:table):any
---@field Busy fun(self:Win95Context, props:table):any
---@field Checkbox fun(self:Win95Context, props:table):any
---@field Toggle fun(self:Win95Context, props:table):any
---@field RadioGroup fun(self:Win95Context, props:table):any
---@field Slider fun(self:Win95Context, props:table):any
---@field TextInput fun(self:Win95Context, props:table):any
---@field TextArea fun(self:Win95Context, props:table):any
---@field NumberInput fun(self:Win95Context, props:table):any
---@field ScrollView fun(self:Win95Context, props:table):any
---@field ListView fun(self:Win95Context, props:table):any
---@field Table fun(self:Win95Context, props:table):any
---@field TreeView fun(self:Win95Context, props:table):any
---@field Tabs fun(self:Win95Context, props:table):any
---@field StatusBar fun(self:Win95Context, props:table):any
---@field Select fun(self:Win95Context, props:table):any
---@field MenuBar fun(self:Win95Context, props:table):any
---@field ImageViewer fun(self:Win95Context, props:table):any
---@field Thumbnails fun(self:Win95Context, props:table):any
local Context={};Context.__index=Context
local factories={}
for _,name in ipairs({"Panel","Frame","Label","Button","IconButton","Icon","DesktopIcon","Separator","GroupBox","ProgressBar","Busy","Checkbox","Toggle","RadioGroup","Slider"}) do factories[name]="Controls" end
for _,name in ipairs({"TextInput","TextArea","NumberInput"}) do factories[name]="TextInput" end
for _,name in ipairs({"ScrollView","ListView","Table","TreeView","Tabs","StatusBar"}) do factories[name]="Views" end
for _,name in ipairs({"Select","MenuBar"}) do factories[name]="Menus" end
for _,name in ipairs({"ImageViewer","Thumbnails"}) do factories[name]="Media" end
for name,module in pairs(factories) do
    Context[name]=function(self,p)
        assert(not self.dead_,"context destroyed");local props={};for k,v in pairs(p or {}) do props[k]=v end
        props.context=self;return require("win95."..module)[name](props)
    end
end
function Context.new(container,options)
    assert(container and container.AddChild,"provide a host UI container after UI.Init")
    assert(UI.GetNVGContext(),"host must call UI.Init before win95.new")
    local self=setmetatable({},Context);self:init(container,options or {});return self
end
function Context:init(container,o)
    self.theme=Theme.create(o.theme,o.density);self.options=o
    self.widgets_=setmetatable({},{__mode="k"});self.captures_={};self.ownedPointers_={};self.tweens_={};self.windows_={}
    self.clock_=0;self.touchUntil_=0;self.modalStack_={};self.dead_=false;self.serial_=0
    self.root=Base{context=self,width="100%",height="100%",pointerEvents="box-none",overflow="hidden"}
    container:AddChild(self.root)
    self.content=Base{context=self,width="100%",height="100%",pointerEvents="box-none"};self.root:AddChild(self.content)
    self.windowLayer=Base{context=self,position="absolute",left=0,top=0,width="100%",height="100%",pointerEvents="box-none",zIndex=10}
    self.root:AddChild(self.windowLayer)
    self.overlayLayer=Base{context=self,position="absolute",left=0,top=0,width="100%",height="100%",pointerEvents="box-none",zIndex=10000}
    self.root:AddChild(self.overlayLayer)
    self.root.Update=function(_,dt) self:Update(dt) end
    self.eventNode_=Node();self.events_=self.eventNode_:CreateScriptObject("LuaScriptObject")
    self.events_:SubscribeToEvent("InputFocus",function(_,_,data)
        if not data:GetBool("Focus") then self:CancelInput();self:CloseMenu();self:HideTooltip() end
    end)
    self.pointerListener_=Input.On("PointerDown",function(e)
        if self.dead_ then return end
        local w=UI.FindWidgetAt(e.x/UI.GetScale(),e.y/UI.GetScale())
        if self:IsWithin(w,self.root) then
            -- Gesture subscribes before the UI hit-test callback. Preserve the original
            -- target before a drag leaves its title/slider; do not alter host targets.
            local gestureTarget=w;local ancestor=w --[[@as any]]
            while ancestor and ancestor~=self.root do
                if ancestor.win95PanTarget_ or ancestor.win95Scroll_ then gestureTarget=ancestor;break end
                ancestor=ancestor.parent
            end
            e.target=gestureTarget;self.ownedPointers_[e.pointerId]=gestureTarget;self:ActivateOwner(w)
        end
    end,20)
    self.pointerUpListener_=Input.On("PointerUp",function(e)self.ownedPointers_[e.pointerId]=nil end,-20)
    self.pointerCancelListener_=Input.On("PointerCancel",function(e)self.ownedPointers_[e.pointerId]=nil end,-20)
end
function Context:Owns(w) return w and w.ctx_==self end
function Context:IsWithin(w,parent)
    while w do if w==parent then return true end;w=w.parent end;return false
end
function Context:Add(w,parent) (parent or self.content):AddChild(w);return w end
function Context:Resource(path) return (self.options.assetRoot or "win95"):gsub("/$","").."/"..path:gsub("^/","") end
function Context:Bounds() local l=self.root:GetAbsoluteLayout();return {x=0,y=0,w=l.w,h=l.h} end
function Context:ConsumesKeyboard()
    return #self.modalStack_>0 or self.menu_~=nil or self:Owns(UI.GetFocus())==true
end
function Context:ConsumesPointer(x,y)
    return self:IsWithin(UI.FindWidgetAt(x,y),self.root) or next(self.captures_)~=nil or next(self.ownedPointers_)~=nil
end
function Context:Release(parent)
    if self:IsWithin(UI.GetFocus(),parent) then UI.ClearFocus() end
    local ids={}
    if UI.GetHoveredWidget and self:IsWithin(UI.GetHoveredWidget(),parent) and (not UI.GetPressedWidgetForPointer(0) or self:IsWithin(UI.GetPressedWidgetForPointer(0),parent)) then ids[0]=true end
    for id in pairs(Input.GetActivePointers()) do
        if self:IsWithin(UI.GetPressedWidgetForPointer(id),parent) then ids[id]=true end
    end
    for id,w in pairs(self.captures_) do if self:IsWithin(w,parent) then ids[id]=true end end
    for id,w in pairs(self.ownedPointers_) do if self:IsWithin(w,parent) then ids[id]=true end end
    for id in pairs(ids) do
        local event=Pointer.new("PointerCancel",{pointerId=id,x=0,y=0,pointerType=id==0 and "mouse" or "touch"})
        Gesture.HandlePointerCancel(event);UI.HandlePointerCancel(event)
        local w=self.captures_[id];if w and w.OnPointerCancel then w:OnPointerCancel({pointerId=id}) end
        self.captures_[id]=nil;self.ownedPointers_[id]=nil
    end
    for w in pairs(self.tweens_) do if self:IsWithin(w,parent) then w.tween_:cancel("hidden");self.tweens_[w]=nil end end
    if self.menu_ and self.menu_.owner and self:IsWithin(self.menu_.owner,parent) then self:CloseMenu() end
    if self.tooltip_ and self:IsWithin(self.tooltip_.owner,parent) then self:HideTooltip() end
end
function Context:CancelInput() self:Release(self.root) end
function Context:Focusables(root)
    local result={}
    local function visit(w)
        if w.props.visible==false or w.props.disabled or w.dead_ then return end
        if w.ctx_==self and w.focusable then result[#result+1]=w end
        for _,child in ipairs(w.children or {}) do visit(child) end
    end
    visit(root or self.root);return result
end
function Context:FocusNext(backward)
    local modal=self.modalStack_[#self.modalStack_]
    local list=self:Focusables(modal and modal.window or self.root)
    if #list==0 then return end
    local at=backward and 1 or 0
    for i,w in ipairs(list) do if UI.GetFocus()==w then at=i;break end end
    UI.SetFocus(list[(at-1+(backward and -1 or 1))%#list+1])
end
function Context:Key(w,key)
    if key==KEY_TAB then self:FocusNext(input and input:GetQualifierDown(QUAL_SHIFT));return true end
    if key==KEY_ESCAPE then
        if self.menu_ then self:CloseMenu();return true end
        local modal=self.modalStack_[#self.modalStack_]
        if modal and modal.cancel then modal.cancel();return true end
    end
    return false
end
function Context:ActivateOwner(w)
    while w do if w.win95Window_ then self:Activate(w);return end;w=w.parent end
end
function Context:Tween(w,target,duration,callback)
    assert(w.ctx_==self and not w.dead_,"tween target must belong to context")
    for k in pairs(target) do assert(k=="x" or k=="y" or k=="w" or k=="h" or k=="opacity","unsupported tween property: "..k) end
    if not w.tween_ or not w.tween_.active then
        local l=w:GetLayout()
        w.tween_=Tween.new({x=l.x,y=l.y,w=l.w,h=l.h,opacity=w.props.opacity or 1},function(v)
            if w.win95Window_ then w:SetRect(v.x,v.y,v.w,v.h);w:SetStyle{opacity=v.opacity}
            else w:SetStyle{position="absolute",left=v.x,top=v.y,width=v.w,height=v.h,opacity=v.opacity} end
        end)
    end
    self.tweens_[w]=true;w.tween_:to(target,duration,callback);return w.tween_
end
function Context:Update(dt)
    if self.dead_ then return end
    self.clock_=self.clock_+dt
    for w in pairs(self.tweens_) do
        if w.dead_ then self.tweens_[w]=nil
        else w.tween_:update(dt);if not w.tween_.active then self.tweens_[w]=nil end end
    end
    local b=self:Bounds()
    if self.width_~=b.w or self.height_~=b.h then
        self.width_=b.w;self.height_=b.h
        self:CancelInput();self:CloseMenu();self:HideTooltip()
        for _,w in ipairs(self.windows_) do w:Constrain() end
        for _,m in ipairs(self.modalStack_) do m.window:Constrain() end
        if self.options.onResize then self.options.onResize(b.w,b.h) end
    end
    local modal=self.modalStack_[#self.modalStack_]
    if modal and not self:IsWithin(UI.GetFocus(),modal.window) and not self.menu_ then
        local list=self:Focusables(modal.window);UI.SetFocus(list[1] or modal.window)
    end
    if self.tooltip_ and not self.tooltip_.shown and self.clock_>=self.tooltip_.at then self:DisplayTooltip() end
end
function Context:ShowTooltip(owner,text)
    self:HideTooltip();self.tooltip_={owner=owner,text=text,at=self.clock_+.5}
end
function Context:DisplayTooltip()
    local tip=self.tooltip_;if not tip or not tip.owner:Alive() then self:HideTooltip();return end
    local l=tip.owner:GetAbsoluteLayoutForHitTest();local root=self.root:GetAbsoluteLayoutForHitTest();local b=self:Bounds()
    local width=math.min(260,math.max(80,b.w-12));local p=self:Frame{width=width,padding=6,backgroundColor=self.theme.tooltip,position="absolute",pointerEvents="none"}
    p:AddChild(self:Label{text=tip.text,wrap=true});self.overlayLayer:AddChild(p)
    local lines=D.lines(tip.text,width-12,function(s)return UI.MeasureTextWidth(s,self.theme.fontSize,self.theme.font)end)
    local h=#lines*(self.theme.fontSize+5)+12
    p:SetStyle{left=D.clamp(l.x-root.x,0,b.w-width),top=D.clamp(l.y-root.y+l.h+4,0,b.h-h),height=h}
    tip.widget=p;tip.shown=true
end
function Context:HideTooltip(owner)
    if self.tooltip_ and (not owner or self.tooltip_.owner==owner) then
        local p=self.tooltip_.widget;self.tooltip_=nil;if p then p:Destroy() end
    end
end
function Context:Tooltip(p) self:ShowTooltip(assert(p.owner),assert(p.text));if p.immediate then self:DisplayTooltip() end end
function Context:PopupMenu(p) return require("win95.Menus").open(self,p) end
function Context:ContextMenu(p) return self:PopupMenu(p) end
function Context:CloseMenu() if self.menu_ then self.menu_:Close() end end
function Context:Window(p) return require("win95.Windows").create(self,p or {}) end
function Context:GetWindows() local result={};for i,w in ipairs(self.windows_) do result[i]=w end;return result end
function Context:GetActiveWindow() return self.active_ end
function Context:Activate(w) return require("win95.Windows").activate(self,w) end
function Context:Modal(p) return require("win95.Windows").modal(self,p or {}) end
function Context:MessageBox(p) return require("win95.Windows").message(self,p or {}) end
function Context:Desktop(p) return require("win95.Windows").desktop(self,p or {}) end
function Context:Taskbar(p) return require("win95.Windows").taskbar(self,p or {}) end
function Context:StartMenu(p) return self:PopupMenu(p) end
function Context:Assistant(p) return require("win95.Assistant").new(self,p or {}) end
function Context:Stats()
    local count=0;for _ in pairs(self.widgets_) do count=count+1 end
    return {widgets=count,windows=#self.windows_,captures=next(self.captures_)~=nil,resources=require("win95.Media").stats(self)}
end
function Context:Destroy()
    if self.dead_ then return end
    self:CancelInput();self:CloseMenu();self:HideTooltip()
    Input.Off("PointerDown",self.pointerListener_)
    Input.Off("PointerUp",self.pointerUpListener_);Input.Off("PointerCancel",self.pointerCancelListener_)
    self.events_:UnsubscribeFromAllEvents();self.eventNode_:Remove();self.events_=nil;self.eventNode_=nil
    self.root:Destroy()
    local rest={};for w in pairs(self.widgets_) do rest[#rest+1]=w end
    for _,w in ipairs(rest) do if not w.dead_ then w:Destroy() end end
    self.dead_=true;self.windows_={};self.modalStack_={};self.tweens_={};self.options={}
    self.root=nil;self.content=nil;self.windowLayer=nil;self.overlayLayer=nil
end
return Context
