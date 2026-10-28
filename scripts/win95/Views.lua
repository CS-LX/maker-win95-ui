-- SPDX-License-Identifier: MIT
local UI=require("urhox-libs/UI")
local NativeScroll=require("urhox-libs/UI/Widgets/ScrollView")
local Base=require("win95.Base")
local C=require("win95.Controls")
local D=require("win95.Draw")
local Icons=require("win95.Icons")
local M={}
local Virtual=UI.VirtualList:Extend("Win95BoundedVirtualList")
function Virtual:PrewarmPool()
    -- An unattached percentage-height Yoga node may measure its entire content.
    -- Use the explicit viewport until the parent has completed layout.
    local count=math.ceil((self.props.viewportHeight or 180)/self.rowHeight_)+self.props.poolBuffer*2
    for _=1,count do local w=self:CreatePoolItem();w:SetVisible(false);self.pool_.available[#self.pool_.available+1]=w end
end
function Virtual:CalculateVisibleRange()
    local count=#self.props.data;if count==0 then return 0,0 end
    local height=self.validViewport_ or self.props.viewportHeight or 180
    return math.max(1,math.floor(self.scrollOffset_/self.rowHeight_)+1),math.min(count,math.ceil((self.scrollOffset_+height)/self.rowHeight_))
end
local function scrollbars(self,n)
    local t=self.ctx_.theme;local l=self:GetAbsoluteLayout();local hit=self:GetAbsoluteLayoutForHitTest()
    local width=t.scrollbar;local dx,dy=hit.x-l.x,hit.y-l.y
    self.vTrackBounds_=nil;self.vScrollbarBounds_=nil;self.hTrackBounds_=nil;self.hScrollbarBounds_=nil
    if self.props.scrollY and self.contentHeight_>l.h then
        local track={x=l.x+l.w-width,y=l.y,w=width,h=l.h}
        local height=math.min(l.h,math.max(t.density=="touch" and 44 or 24,l.h*l.h/self.contentHeight_))
        local y=l.y+(l.h-height)*D.clamp(self.state.scrollY/(self.contentHeight_-l.h),0,1)
        D.rect(n,track.x,track.y,track.w,track.h,t.light);D.bevel(n,{x=track.x,y=y,w=width,h=height},t,false,t.face)
        self.vTrackBounds_={x=track.x+dx,y=track.y+dy,w=width,h=l.h}
        self.vScrollbarBounds_={x=track.x+dx,y=y+dy,w=width,h=height}
    end
    if self.props.scrollX and self.contentWidth_>l.w then
        local size=math.min(l.w,math.max(24,l.w*l.w/self.contentWidth_));local x=l.x+(l.w-size)*D.clamp(self.state.scrollX/(self.contentWidth_-l.w),0,1)
        D.rect(n,l.x,l.y+l.h-width,l.w,width,t.light);D.bevel(n,{x=x,y=l.y+l.h-width,w=size,h=width},t,false,t.face)
        self.hTrackBounds_={x=l.x+dx,y=l.y+l.h-width+dy,w=l.w,h=width}
        self.hScrollbarBounds_={x=x+dx,y=l.y+l.h-width+dy,w=size,h=width}
    end
end
local function cancelScroll(self,e)
    if self.panPointer_ and self.panPointer_~=e.pointerId then return true end
    self.state.isDragging=false;self.state.velocityX=0;self.state.velocityY=0
    self.isDraggingScrollbarV_=false;self.isDraggingScrollbarH_=false
    Base.OnPointerCancel(self,e)
end
local Scroll=NativeScroll:Extend("Win95ScrollView");M.ScrollView=Scroll
for _,name in ipairs({"Theme","Alive","IsDisabled","Emit","Focus","SetVisible","SetDisabled","OnKeyDown","OnFocus","OnBlur","Destroy"}) do Scroll[name]=Base[name] end
function Scroll:Init(p)
    p.bounces=false;p.scrollbarInteractive=true;p.backgroundColor=p.backgroundColor or p.context.theme.paper
    p.borderRadius=0
    if p.scrollY~=false and p.showScrollbar~=false then p.paddingRight=(p.paddingRight or p.padding or 0)+p.context.theme.scrollbar end
    Base.adopt(self,p);NativeScroll.Init(self,p);self.win95Scroll_=true
end
Scroll.RenderScrollbars=scrollbars;Scroll.OnPointerCancel=cancelScroll
function Scroll:OnPointerDown(e)
    if not self:Alive() then return true end
    Base.OnPointerDown(self,e);return NativeScroll.OnPointerDown(self,e)
end
function Scroll:OnPointerUp(e) NativeScroll.OnPointerUp(self,e);Base.OnPointerUp(self,e) end
function Scroll:OnPanStart(e)
    if self.panPointer_ and self.panPointer_~=e.pointerId then return true end
    if self:Alive() then local result=NativeScroll.OnPanStart(self,e);if result then self.panPointer_=e.pointerId end;return result end;return true
end
function Scroll:OnPanMove(e) if self.panPointer_==e.pointerId then NativeScroll.OnPanMove(self,e) end end
function Scroll:OnPanEnd(e) if self.panPointer_~=e.pointerId then return end;NativeScroll.OnPanEnd(self,e);self.panPointer_=nil end
function Scroll:OnWheel(dx,dy) if self:Alive() then return NativeScroll.OnWheel(self,dx,dy) end;return true end
function Scroll:Render(n) NativeScroll.Render(self,n);D.bevel(n,self:GetAbsoluteLayout(),self:Theme(),true) end

local Row=C.Button:Extend("Win95ListRow")
function Row:OnClick(e)
    if not self:Alive() or (e and not self.clickReady_) then return true end
    self.props.list:Select(self.index_,true);self.props.list:Focus();self.clickReady_=false;return true
end
function Row:OnKeyDown(k) return self.props.list:OnKeyDown(k) end
function Row:Render(n)
    local list=self.props.list;local t=self:Theme();local l=self:GetAbsoluteLayout();local data=self.data_ or {}
    local selected=list.index_==self.index_;local color=selected and t.selectionText or (data.disabled and t.disabled or t.text)
    D.rect(n,l.x,l.y,l.w,l.h,selected and t.selection or t.paper)
    D.clip(n,l,function()
        if list.props.columns then
            local total=0;for _,col in ipairs(list.props.columns) do total=total+(col.width or 1) end
            local x=l.x
            for _,col in ipairs(list.props.columns) do
                local width=(l.w-t.scrollbar)*(col.width or 1)/total
                D.clip(n,{x=x+4,y=l.y,w=width-8,h=l.h},function()D.text(n,tostring(data[col.key] or ""),x+4,l.y+l.h/2,t,color)end)
                x=x+width
            end
        else
            local x=l.x+5+(data.depth or 0)*16
            if data.hasChildren then Icons.draw(n,data.expanded and "minus" or "plus",x,l.y+(l.h-16)/2,16,data.disabled);x=x+19 end
            if data.icon then Icons.draw(n,data.icon,x,l.y+(l.h-16)/2,16,data.disabled);x=x+20 end
            D.text(n,data.label or data.name or tostring(self.index_),x,l.y+l.h/2,t,color)
        end
    end)
    if selected and list.state.focused then D.focus(n,l,t,2) end
end
local List=Base:Extend("Win95ListView");M.ListView=List
function List:Init(p)
    p.focusable=true;p.height=p.height or 180;p.data=p.data or {};p.overflow="hidden";p.padding=2
    Base.Init(self,p);self.index_=0
    self.virtual_=Virtual{
        width="100%",height="100%",data=p.data,itemHeight=p.context.theme.rowHeight,viewportHeight=type(p.height)=="number" and p.height or 180,poolBuffer=2,bounces=false,
        createItem=function()return Row{context=self.ctx_,list=self,width="100%",height=self.ctx_.theme.rowHeight,focusable=false}end,
        bindItem=function(w,data,index)w.data_=data;w.index_=index;w.props.disabled=data.disabled==true end,
    }
    local sv=self.virtual_.scrollView_;sv.ctx_=self.ctx_;sv.props.context=self.ctx_;sv.focusable=false;sv.props.borderRadius=0;sv.win95Scroll_=true
    sv.RenderScrollbars=scrollbars;sv.OnPointerCancel=cancelScroll;sv.Emit=Base.Emit
    sv.Alive=Base.Alive;sv.OnPanStart=Scroll.OnPanStart;sv.OnPanMove=Scroll.OnPanMove;sv.OnPanEnd=Scroll.OnPanEnd
    self:AddChild(self.virtual_)
    if p.value~=nil then self:SetValue(p.value) end
end
function List:Render(n) D.bevel(n,self:GetAbsoluteLayout(),self:Theme(),true,self:Theme().paper) end
function List:Update()
    if not self:Alive() then return end
    local l=self.virtual_:GetLayout()
    if self.viewport_~=l.h then self.viewport_=l.h;self.virtual_.validViewport_=l.h;self.virtual_:UpdateVisibleItems() end
end
function List:SetData(data)
    self.props.data=data or {};local selected=self:GetValue();self.index_=0;self.virtual_:SetData(self.props.data)
    if selected~=nil then self:SetValue(selected) end
    if self.index_==0 then Base.SetValue(self,nil) end;return self
end
function List:GetPoolStats()
    local count=0;for _ in pairs(self.virtual_.pool_.inUse) do count=count+1 end
    local available=#self.virtual_.pool_.available
    return {inUse=count,available=available,total=count+available}
end
function List:SetValue(v)
    for i,item in ipairs(self.props.data) do if (item.id or item.value or i)==v then return self:Select(i) end end
    return false
end
function List:Select(i,activate)
    local item=self.props.data[i];if not item or item.disabled or not self:Alive() then return false end
    self.index_=i;Base.SetValue(self,item.id or item.value or i)
    if activate then self:Emit("select",item,i) end
    self:EnsureVisible(i);return true
end
function List:EnsureVisible(i)
    local h=self.ctx_.theme.rowHeight;local view=self.virtual_.scrollView_;local _,y=view:GetScroll();local l=view:GetLayout()
    if (i-1)*h<y then view:SetScroll(0,(i-1)*h) elseif i*h>y+l.h then view:SetScroll(0,i*h-l.h) end
end
function List:OnKeyDown(k)
    if self.ctx_:Key(self,k) or not self:Alive() then return true end
    local delta=(k==KEY_UP and -1) or (k==KEY_DOWN and 1) or (k==KEY_PAGEUP and -math.max(1,math.floor(self:GetLayout().h/self:Theme().rowHeight))) or (k==KEY_PAGEDOWN and math.max(1,math.floor(self:GetLayout().h/self:Theme().rowHeight)))
    local n=#self.props.data;if n==0 then return true end
    if k==KEY_HOME then self:Select(1) elseif k==KEY_END then self:Select(n)
    elseif delta then
        local at=D.clamp(self.index_+delta,1,n);local direction=delta<0 and -1 or 1
        while self.props.data[at] and self.props.data[at].disabled do at=at+direction end
        self:Select(at)
    elseif (k==KEY_RETURN or k==KEY_SPACE) and self.index_>0 then self:Emit("select",self.props.data[self.index_],self.index_) end
    return true
end
function List:Destroy()
    if self.dead_ then return end
    -- Engine VirtualList detaches pooled rows; release their Yoga nodes explicitly.
    self.virtual_:ReleaseAllItems()
    for _,w in ipairs(self.virtual_.pool_.available) do w:Destroy() end
    self.virtual_.pool_.available={};Base.Destroy(self);self.virtual_=nil
end
local Table=Base:Extend("Win95Table");M.Table=Table
function Table:Init(p)
    p.height=p.height or 220;Base.Init(self,p)
    local header=self.ctx_:Panel{height=self:Theme().rowHeight,flexDirection="row"}
    for _,col in ipairs(p.columns or {}) do header:AddChild(self.ctx_:Button{text=col.title or col.key,width=0,flexGrow=col.width or 1,flexShrink=1,onClick=function()self:Sort(col.key)end}) end
    self:AddChild(header)
    self.list_=self.ctx_:ListView{data=p.data,columns=p.columns,value=p.value,flexGrow=1,flexBasis=0,height="auto",
        onChange=function(_,v)Base.SetValue(self,v)end,onSelect=function(_,row,i)self:Emit("select",row,i)end}
    self:AddChild(self.list_)
end
function Table:SetData(data) self.props.data=data;self.list_:SetData(data);return self end
function Table:SetValue(v) return self.list_:SetValue(v) end
function Table:Sort(key)
    self.desc_=self.sort_==key and not self.desc_ or false;self.sort_=key
    local copy={};for i,row in ipairs(self.props.data or {}) do copy[i]=row end
    table.sort(copy,function(a,b)local x,y=a[key],b[key];if type(x)~=type(y) or type(x)~="number" then x=tostring(x or "");y=tostring(y or "") end;if self.desc_ then return x>y else return x<y end end)
    self:SetData(copy);self:Emit("sort",key,self.desc_)
end
local Tree=List:Extend("Win95TreeView");M.TreeView=Tree
function Tree:Init(p)
    self.tree_=p.data or {};self.expanded_={};p.data={};List.Init(self,p)
    self.props.onSelect=function(_,row) if row.hasChildren then self:ToggleNode(row.id) end;if p.onNodeSelect then p.onNodeSelect(self,row.node) end end
    self:Rebuild()
end
function Tree:Rebuild()
    local rows={}
    local function visit(nodes,depth,parent)
        for _,node in ipairs(nodes) do
            assert(node.id~=nil,"TreeView nodes require stable ids")
            rows[#rows+1]={id=node.id,label=node.label,icon=node.icon or (node.children and "folder" or "file"),depth=depth,node=node,parentId=parent,
                hasChildren=node.children and #node.children>0,expanded=self.expanded_[node.id],disabled=node.disabled}
            if node.children and self.expanded_[node.id] then visit(node.children,depth+1,node.id) end
        end
    end
    visit(self.tree_,0,nil);List.SetData(self,rows)
end
function Tree:SetData(data) self.tree_=data or {};self:Rebuild();return self end
function Tree:ToggleNode(id) self.expanded_[id]=not self.expanded_[id];self:Rebuild();self:Emit("expand",id,self.expanded_[id]) end
function Tree:OnKeyDown(k)
    local row=self.props.data[self.index_]
    if self:Alive() and row and (k==KEY_LEFT or k==KEY_RIGHT) then
        if row.hasChildren and ((k==KEY_RIGHT and not row.expanded) or (k==KEY_LEFT and row.expanded)) then self:ToggleNode(row.id)
        elseif k==KEY_LEFT and row.parentId then self:SetValue(row.parentId)
        elseif k==KEY_RIGHT and row.expanded then self:Select(self.index_+1) end;return true
    end
    return List.OnKeyDown(self,k)
end
local Tabs=Base:Extend("Win95Tabs");M.Tabs=Tabs
function Tabs:Init(p)
    p.height=p.height or 240;Base.Init(self,p)
    self.tabButtons_={};self.tabContent_={}
    self.bar_=self.ctx_:Panel{flexDirection="row",flexWrap="wrap",gap=2};self:AddChild(self.bar_)
    self.body_=self.ctx_:Frame{flexGrow=1,flexBasis=0,padding=8,overflow="hidden"};self:AddChild(self.body_)
    for i,tab in ipairs(p.tabs or {}) do
        local id=tab.id or i
        local b=self.ctx_:Button{text=tab.label,disabled=tab.disabled,onClick=function()self:SetValue(id)end}
        b.OnKeyDown=function(button,k)
            if k==KEY_LEFT or k==KEY_RIGHT then
                local nextIndex=i
                for _=1,#p.tabs do nextIndex=(nextIndex-1+(k==KEY_LEFT and -1 or 1))%#p.tabs+1
                    if not p.tabs[nextIndex].disabled then self:SetValue(p.tabs[nextIndex].id or nextIndex);self.tabButtons_[nextIndex]:Focus();break end
                end
            else Base.OnKeyDown(button,k) end
        end
        self.bar_:AddChild(b);self.tabButtons_[i]=b
        if tab.content then self.body_:AddChild(tab.content);tab.content:SetVisible(false);self.tabContent_[id]=tab.content end
    end
    self:SetValue(p.value or (p.tabs[1] and (p.tabs[1].id or 1)))
end
function Tabs:SetValue(v)
    local found=false
    for i,tab in ipairs(self.props.tabs) do if (tab.id or i)==v and not tab.disabled then found=true end end
    if not found then return false end
    for id,child in pairs(self.tabContent_) do child:SetVisible(id==v) end
    for i,b in ipairs(self.tabButtons_) do b.props.selected=(self.props.tabs[i].id or i)==v end
    Base.SetValue(self,v);return true
end
local Status=Base:Extend("Win95StatusBar");M.StatusBar=Status
function Status:Init(p)
    p.height=p.height or 24;p.flexDirection="row";p.gap=2;Base.Init(self,p)
    self.fields_={}
    for _,text in ipairs(p.items or {p.text or "Ready"}) do
        local f=self.ctx_:Frame{inset=true,flexGrow=1,flexBasis=0,paddingHorizontal=5}
        local label=self.ctx_:Label{text=text};f:AddChild(label);self:AddChild(f);self.fields_[#self.fields_+1]=label
    end
end
function Status:SetText(text,index) local f=self.fields_[index or 1];if f then f:SetText(text) end;return self end
return M
