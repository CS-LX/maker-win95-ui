-- SPDX-License-Identifier: MIT
local UI=require("urhox-libs/UI")
local Base=require("win95.Base")
local C=require("win95.Controls")
local D=require("win95.Draw")
local M={}
local Menu={};Menu.__index=Menu
function Menu:Close()
    if self.closed then return end
    self.closed=true;local ctx=self.ctx
    if ctx.menu_==self then ctx.menu_=nil end
    self.blocker:Destroy();self.frames={}
    if self.previous and self.previous.node and (not self.previous.Alive or self.previous:Alive()) then UI.SetFocus(self.previous) end
    if self.onClose then self.onClose() end
end
function Menu:Trim(depth)
    for i=#self.frames,depth+1,-1 do self.frames[i].widget:Destroy();self.frames[i]=nil end
end
function Menu:Focus(frame,index,delta)
    local n=#frame.buttons;if n==0 then UI.SetFocus(self.blocker);return end
    index=D.clamp(index,1,n)
    for _=1,n do
        local button=frame.buttons[index]
        if not button:IsDisabled() then
            frame.active=index;button:Focus()
            local _,y=frame.scroll:GetScroll();local row=self.ctx.theme.rowHeight
            local offset=button.menuOffset_ or (index-1)*row;local h=frame.scroll:GetLayout().h
            if offset<y then frame.scroll:SetScroll(0,offset) elseif offset+row>y+h then frame.scroll:SetScroll(0,offset+row-h) end
            return
        end
        index=(index-1+(delta or 1))%n+1
    end
end
function Menu:Key(frame,index,key)
    if key==KEY_ESCAPE or key==KEY_TAB then self:Close();return true end
    if key==KEY_UP or key==KEY_DOWN then self:Focus(frame,(index-1+(key==KEY_UP and -1 or 1))%#frame.buttons+1,key==KEY_UP and -1 or 1)
    elseif key==KEY_HOME then self:Focus(frame,1)
    elseif key==KEY_END then self:Focus(frame,#frame.buttons,-1)
    elseif key==KEY_LEFT and frame.depth>1 then
        self:Trim(frame.depth-1);frame.parentButton:Focus()
    elseif key==KEY_RETURN or key==KEY_SPACE or key==KEY_RIGHT then
        local item=frame.items[index]
        if key~=KEY_RIGHT or item.children then frame.buttons[index]:OnClick() end
    elseif key>=97 and key<=122 then
        local char=string.char(key)
        for off=1,#frame.buttons do local i=(index+off-1)%#frame.buttons+1
            if (frame.items[i].label or ""):lower():sub(1,1)==char and not frame.items[i].disabled then self:Focus(frame,i);break end
        end
    end
    return true
end
function Menu:Show(items,x,y,depth,parentButton)
    self:Trim(depth-1)
    local ctx=self.ctx;local t=ctx.theme;local bounds=ctx:Bounds();local width=math.min(self.width or 220,bounds.w-8)
    width=math.max(44,width);local wanted=4
    for _,item in ipairs(items) do wanted=wanted+(item.separator and 8 or t.rowHeight) end
    local height=math.max(24,math.min(wanted,bounds.h-8,self.maxHeight or math.huge))
    if x+width>bounds.w and parentButton then
        local r=parentButton:GetAbsoluteLayoutForHitTest();local root=ctx.root:GetAbsoluteLayoutForHitTest();x=r.x-root.x-width
    end
    x=D.clamp(x,4,bounds.w-width-4);y=D.clamp(y,4,bounds.h-height-4)
    local panel=ctx:Frame{position="absolute",left=x,top=y,width=width,height=height,padding=2,zIndex=depth}
    local scroll=ctx:ScrollView{width="100%",height="100%",backgroundColor=t.face}
    panel:AddChild(scroll);self.blocker:AddChild(panel)
    local frame={widget=panel,scroll=scroll,buttons={},items={},depth=depth,parentButton=parentButton}
    self.frames[depth]=frame;local offset=0
    for _,item in ipairs(items) do
        if item.separator then scroll:AddChild(ctx:Panel{height=8,paddingVertical=3,children={ctx:Separator{}}});offset=offset+8
        else
            local index=#frame.buttons+1
            local b=ctx:Button{menu=true,text=item.label or "",icon=item.icon,disabled=item.disabled,width="100%",height=t.rowHeight,
                onClick=function(button)
                    if item.children then
                        local r=button:GetAbsoluteLayoutForHitTest();local root=ctx.root:GetAbsoluteLayoutForHitTest()
                        self:Show(item.children,r.x-root.x+r.w-2,r.y-root.y,depth+1,button)
                    else
                        self:Close();if item.action then item.action(item) end
                        if self.onSelect then self.onSelect(item) end
                    end
                end}
            b.menuOffset_=offset;offset=offset+t.rowHeight
            b.OnKeyDown=function(_,key)return self:Key(frame,index,key)end
            local render=b.Render
            b.Render=function(button,n)
                render(button,n)
                if item.children then local l=button:GetAbsoluteLayout();D.text(n,">",l.x+l.w-22,l.y+l.h/2,t,button.state.focused and t.selectionText or t.text) end
                if item.checked then local l=button:GetAbsoluteLayout();D.text(n,"*",l.x+l.w-34,l.y+l.h/2,t,button.state.focused and t.selectionText or t.text) end
            end
            scroll:AddChild(b);frame.buttons[index]=b;frame.items[index]=item
        end
    end
    UI.Layout();scroll:UpdateContentSize()
    local selected=1;for i,item in ipairs(frame.items) do if item.checked then selected=i;break end end
    self:Focus(frame,selected)
    return frame
end
function M.open(ctx,p)
    ctx:CloseMenu();ctx:HideTooltip()
    local self=setmetatable({ctx=ctx,frames={},owner=p.anchor or p.owner,previous=UI.GetFocus(),width=p.width,maxHeight=p.maxHeight,onSelect=p.onSelect,onClose=p.onClose},Menu)
    ctx.menu_=self
    self.blocker=ctx:Panel{position="absolute",left=0,top=0,width="100%",height="100%",zIndex=1000,focusable=true,onClick=function()self:Close()end}
    self.blocker.OnKeyDown=function(_,key)if key==KEY_ESCAPE or key==KEY_TAB then self:Close() end;return true end
    ctx.overlayLayer:AddChild(self.blocker)
    local x,y=p.x or 4,p.y or 4
    if p.anchor then
        local a=p.anchor:GetAbsoluteLayoutForHitTest();local r=ctx.root:GetAbsoluteLayoutForHitTest();x=a.x-r.x;y=a.y-r.y+a.h
        if p.above then y=a.y-r.y-(#p.items*ctx.theme.rowHeight+4) end
    end
    self:Show(p.items or {},x,y,1);return self
end
local Select=C.Button:Extend("Win95Select");M.Select=Select
function Select:Init(p) p.width=p.width or 180;C.Button.Init(self,p);self:SyncText() end
function Select:SyncText()
    self.props.text=self.props.placeholder or "Select..."
    for _,o in ipairs(self.props.options or {}) do if o.value==self.props.value then self.props.text=o.label;break end end
end
function Select:SetValue(value)
    for _,o in ipairs(self.props.options or {}) do
        if o.value==value and not o.disabled then Base.SetValue(self,value);self:SyncText();return true end
    end
    return false
end
function Select:SetOptions(options) self.props.options=options;self:SyncText();self.ctx_:CloseMenu() end
function Select:Open()
    if not self:Alive() then return end
    local items={}
    for _,o in ipairs(self.props.options or {}) do items[#items+1]={label=o.label,disabled=o.disabled,checked=o.value==self:GetValue(),action=function()self:SetValue(o.value)end} end
    self.ctx_:PopupMenu{anchor=self,items=items,width=self:GetLayout().w,maxHeight=self.props.maxHeight}
end
function Select:OnClick(e) if self:Alive() and (not e or self.clickReady_) then self.clickReady_=false;self:Open() end;return true end
function Select:OnKeyDown(k)
    if self.ctx_:Key(self,k) then return true end
    if k==KEY_DOWN or k==KEY_UP or k==KEY_RETURN or k==KEY_SPACE then self:Open() end;return true
end
function Select:Render(n)
    local l=self:GetAbsoluteLayout();local t=self:Theme();D.bevel(n,l,t,true,self:IsDisabled() and t.face or t.paper)
    local size=math.min(l.h-4,24)
    D.clip(n,{x=l.x+5,y=l.y+2,w=l.w-size-10,h=l.h-4},function()D.text(n,self:GetText(),l.x+6,l.y+l.h/2,t,self:IsDisabled() and t.disabled or t.text)end)
    D.bevel(n,{x=l.x+l.w-size-2,y=l.y+2,w=size,h=l.h-4},t,self.state.pressed,t.face)
    require("win95.Icons").draw(n,"down",l.x+l.w-size-2+(size-16)/2,l.y+(l.h-16)/2,16,self:IsDisabled())
    if self.state.focused then D.focus(n,{x=l.x,y=l.y,w=l.w-size-3,h=l.h},t) end
end
local Bar=Base:Extend("Win95MenuBar");M.MenuBar=Bar
function Bar:Init(p)
    p.flexDirection="row";p.flexWrap="wrap";p.height=p.height or "auto";Base.Init(self,p);self.buttons_={}
    for i,item in ipairs(p.items or {}) do
        local b=self.ctx_:Button{menu=true,text=item.label,disabled=item.disabled,onClick=function(button) self.ctx_:PopupMenu{anchor=button,items=item.children or {item}} end}
        b.OnKeyDown=function(button,k)
            if k==KEY_LEFT or k==KEY_RIGHT then self.buttons_[(i-1+(k==KEY_LEFT and -1 or 1))%#self.buttons_+1]:Focus()
            elseif k==KEY_DOWN then button:OnClick() else Base.OnKeyDown(button,k) end;return true
        end
        self.buttons_[i]=b;self:AddChild(b)
    end
end
return M
