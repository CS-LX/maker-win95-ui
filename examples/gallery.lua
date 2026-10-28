-- SPDX-License-Identifier: MIT
local Host=require("Host")
local Win=require("win95")
local M={}
function M.build(c)
    local w=c:Window{title="Maker Win95 UI — Component Gallery / 组件画廊",icon="settings",minimizable=false}
    w:Maximize()
    local status=c:StatusBar{items={"Ready — all actions use public APIs","Lua 5.4 / Yoga / NanoVG"},width="100%"}
    local function say(s)status:SetText(s)end
    local function row(children) return c:Panel{flexDirection="row",flexWrap="wrap",gap=8,children=children} end
    local function page()return c:ScrollView{width="100%",height="100%",gap=12,padding=8,backgroundColor=c.theme.face}end
    local controls=page()
    controls:AddChild(c:Label{text="Classic geometry. Real input. A library your host owns.",wrap=true})
    local counter=0
    controls:AddChild(c:GroupBox{text="Buttons / 按钮",width="100%",gap=8,children={
        row({c:Button{text="Click me",onClick=function(b)counter=counter+1;b:SetText("Clicked "..counter);say("Button callback: "..counter)end},
            c:Button{text="Disabled",disabled=true},c:Toggle{text="Toggle",onChange=function(_,v)say("Toggle: "..tostring(v))end},
            c:IconButton{icon="save",tooltip="Save is a host callback",onClick=function()say("Save command received")end}}),
        c:Separator{},c:Label{text="Tab moves focus. Enter / Space activates. Hover for a tooltip; touch has explicit controls.",wrap=true},
    }})
    controls:AddChild(c:GroupBox{text="Display / 显示",width="100%",gap=8,children={
        c:Panel{height=26,backgroundColor=c.theme.paper,children={c:Label{text="Panel + Label"}}},
        c:Frame{inset=true,height=30,children={c:Label{text="Sunken Frame"}}},
        c:ProgressBar{value=.65,width="100%"},c:Busy{width="100%"},
    }})
    local forms=page();local saved=c:Label{text="Form values update immediately.",wrap=true}
    forms:AddChild(c:GroupBox{text="Choices",width="100%",children={
        c:Checkbox{text="Enable notifications / 启用通知",width="100%",value=true,onChange=function(_,v)saved:SetText("Notifications: "..tostring(v))end},
        c:RadioGroup{value="compact",options={{label="Compact",value="compact"},{label="Touch",value="touch"},{label="Unavailable",value="none",disabled=true}},onChange=function(_,v)saved:SetText("Density preference: "..v)end},
        c:Select{width="100%",value="en",options={{value="en",label="English"},{value="zh",label="简体中文"},{value="offline",label="Unavailable",disabled=true}},onChange=function(_,v)saved:SetText("Language: "..v)end},
    }})
    local single=c:TextInput{value="你好，Maker！",width="100%",maxLength=80,onChange=function(_,v)saved:SetText("Text: "..v)end}
    local multi=c:TextArea{value="真实多行编辑\n中文换行与选择\nEnter inserts a new line.",width="100%",height=120,maxLength=400}
    forms:AddChild(c:GroupBox{text="Native text editing / 文本编辑",width="100%",gap=8,children={single,multi,
        c:TextInput{value="Disabled input",disabled=true,width="100%"},
        c:NumberInput{value=5,min=0,max=100,step=1,width="100%",onChange=function(_,v)saved:SetText("Number: "..v)end},
        c:Slider{value=35,width="100%",onChange=function(_,v)saved:SetText("Slider: "..v)end},saved}})
    local data=page();local rows={};for i=1,10000 do rows[i]={id=i,label=string.format("Document %05d / 文档",i),name="Document "..i,kind=i%2==0 and "Image" or "Text",size=i*12,icon=i%2==0 and "image" or "file"}end
    local list=c:ListView{data=rows,width="100%",height=200,onSelect=function(_,item)say("Selected "..item.label)end}
    data:AddChild(c:Label{text="10,000 rows, recycled by the engine VirtualList. Arrow keys / PgUp / PgDn / Home / End.",wrap=true});data:AddChild(list)
    data:AddChild(c:Table{width="100%",height=190,columns={{key="name",title="Name",width=3},{key="kind",title="Kind",width=2},{key="size",title="Size",width=1}},data={rows[8],rows[2],rows[24],rows[5]},onSelect=function(_,item)say("Table: "..item.name)end})
    data:AddChild(c:TreeView{width="100%",height=160,data={{id="root",label="Workspace",children={{id="docs",label="Documents",children={{id="readme",label="Readme.txt"}}},{id="photos",label="Pictures"}}}},onNodeSelect=function(_,node)say("Tree: "..node.label)end})
    local icons=page();icons:AddChild(c:Label{text="29 original pixel icons. 16 / 32 sizes, disabled rendering, name-based registry.",wrap=true})
    local grid=row({})
    for _,name in ipairs(Win.Icons.names()) do
        grid:AddChild(c:GroupBox{text=name,width=150,height=100,children={row({c:Icon{name=name,size=16},c:Icon{name=name,size=32},c:Icon{name=name,size=16,disabled=true}})}})
    end;icons:AddChild(grid)
    local media=page();local viewer=c:ImageViewer{src="win95/images/garden.png",width="100%",height=260,onError=function(_,e)say(e.message)end}
    media:AddChild(viewer)
    media:AddChild(c:Thumbnails{value="garden",items={{id="garden",src="win95/images/garden.png"},{id="night",src="win95/images/night.png"}},onChange=function(_,v)viewer:SetSource("win95/images/"..v..".png")end})
    media:AddChild(row({c:Button{text="Contain",onClick=function()viewer:SetFit("contain")end},c:Button{text="Cover",onClick=function()viewer:SetFit("cover")end}}))
    local assistant
    media:AddChild(c:GroupBox{text="Byte — original animated assistant",width="100%",gap=6,children={row({
        c:Button{text="Show",onClick=function()if not assistant then assistant=c:Assistant{x=220,y=220}end;assistant:show()end},
        c:Button{text="Greet",onClick=function()if not assistant then assistant=c:Assistant{x=220,y=220}end;assistant:show():play("greet")end},
        c:Button{text="Think + point",onClick=function()if not assistant then assistant=c:Assistant{x=220,y=220}end;assistant:show():play("think"):play("point",{queue=true})end},
        c:Button{text="Speak",onClick=function()if not assistant then assistant=c:Assistant{x=220,y=220}end;assistant:show():speak("你好！我是 Byte。点击 OK 关闭气泡。文字按中文字符自动换行。")end},
        c:Button{text="Hide",onClick=function()if assistant then assistant:hide()end end},
    })}})
    local windows=page()
    local commands={{label="New window",icon="computer",action=function()local win=c:Window{title="Independent Window",width=340,height=220,x=70,y=80};win.content:AddChild(c:Label{text="Drag the title, resize the corner, maximize or close.\nAll content is supplied by this example.",wrap=true})end},
        {label="More",children={{label="Information",icon="info",action=function()c:MessageBox{title="Information",message="Menus and dialogs are keyboard and touch accessible.",cancel=false}end},{label="Unavailable",disabled=true}}}}
    windows:AddChild(c:MenuBar{items={{label="File",children=commands},{label="Help",children={{label="About",action=function()say("Maker Win95 UI "..Win.version)end}}}}})
    windows:AddChild(row({c:Button{text="Open window",onClick=commands[1].action},
        c:Button{text="Confirm dialog",onClick=function()c:MessageBox{title="Confirm",message="This modal blocks underlying input and restores focus.",onResult=function(v)say("Dialog result: "..tostring(v))end}end},
        c:Button{text="Context menu",contextMenu=commands,onClick=function(b)c:ContextMenu{anchor=b,items=commands}end},
    }))
    local moving=c:Button{text="Tween target",position="absolute",left=8,top=8,width=130}
    local stage=c:Frame{height=160,width="100%",inset=true};stage:AddChild(moving);windows:AddChild(stage)
    windows:AddChild(row({c:Button{text="Move / redirect",onClick=function()local l=stage:GetLayout();local x=moving:GetLayout().x<40 and math.max(8,l.w-145) or 8;c:Tween(moving,{x=x,y=80,opacity=.6},.8)end},c:Button{text="Cancel tween",onClick=function()if moving.tween_ then moving.tween_:cancel()end end}}))
    local tabs=c:Tabs{width="100%",height=math.max(240,c:Bounds().h-110),tabs={{id="controls",label="Controls",content=controls},{id="forms",label="Forms",content=forms},{id="data",label="Data",content=data},{id="icons",label="Icons",content=icons},{id="media",label="Media",content=media},{id="windows",label="Windows",content=windows}}}
    w.content:AddChild(tabs);w.content:AddChild(status)
    c.options.onResize=function(_,h)tabs:SetHeight(math.max(200,h-110))end
    return {context=c,window=w,tabs=tabs,list=list,single=single,multi=multi,viewer=viewer,status=status}
end
function Start()Host.start(M.build)end
function Stop()Host.stop()end
return M
