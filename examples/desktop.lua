-- SPDX-License-Identifier: MIT
local Host=require("Host")
local M={}
function M.build(c)
    local assistant=c:Assistant{x=24,y=210}
    local function photos()
        local w=c:Window{title="Pictures / 图片",icon="image",x=150,y=80,width=480,height=390}
        local view=c:ImageViewer{src="win95/images/garden.png",width="100%",height=230}
        w.content:AddChild(c:MenuBar{items={{label="View",children={
            {label="Contain",action=function()view:SetFit("contain")end},
            {label="Cover",action=function()view:SetFit("cover")end},
        }}}})
        w.content:AddChild(view)
        w.content:AddChild(c:Thumbnails{items={{id="garden",src="win95/images/garden.png"},{id="night",src="win95/images/night.png"}},onChange=function(_,id)view:SetSource("win95/images/"..id..".png")end})
        return w
    end
    local function notes()
        local w=c:Window{title="Notes / 记事本",icon="file",x=440,y=170,width=410,height=330}
        local text=c:TextArea{value="Welcome to Maker Win95 UI.\n你好，世界！\n\nThis document exists only in the host data model.",width="100%",height=190}
        w.content:AddChild(text)
        w.content:AddChild(c:Button{text="Show text with Byte",onClick=function()assistant:show():play("greet"):speak(text:GetValue())end})
        w.content:AddChild(c:StatusBar{text="No disk access. No TTS. Host callbacks only."});return w
    end
    local function settings()
        local w=c:Window{title="Settings / 设置",icon="settings",width=330,height=310,x=320,y=120}
        w.content:AddChild(c:Checkbox{text="Enable Byte",value=true,width="100%",onChange=function(_,v)if v then assistant:show()else assistant:hide()end end})
        w.content:AddChild(c:Label{text="Example preference / 示例设置"})
        w.content:AddChild(c:Slider{value=60,width="100%"})
        w.content:AddChild(c:Select{width="100%",value="normal",options={{label="Normal",value="normal"},{label="Quiet",value="quiet"}}})
        w.content:AddChild(c:Button{text="Apply",onClick=function()c:MessageBox{title="Preferences",message="The host received your settings.",cancel=false}end});return w
    end
    local function files()
        local w=c:Window{title="Example files",icon="folder",width=360,height=280,x=200,y=140}
        w.content:AddChild(c:Label{text="Data supplied by the host. Select an item to open it.",wrap=true})
        w.content:AddChild(c:ListView{width="100%",height=150,data={{id='pictures',label='Pictures',icon='image'},{id='notes',label='Notes',icon='file'},{id='settings',label='Settings',icon='settings'}},
            onSelect=function(_,item)({pictures=photos,notes=notes,settings=settings})[item.id]()end})
        return w
    end
    local apps={{label="Pictures",icon="image",open=photos},{label="Notes",icon="file",open=notes},{label="Settings",icon="settings",open=settings},{label="Files",icon="folder",open=files}}
    c:Desktop{apps=apps};c:Taskbar{items={{label="Applications",children={{label="Pictures",icon="image",action=photos},{label="Notes",icon="file",action=notes},{label="Settings",icon="settings",action=settings},{label="Files",icon="folder",action=files}}},{separator=true},{label="Hello Byte",icon="assistant",action=function()assistant:show():play("greet"):speak("你好！拖动标题栏可移动窗口；任务栏可恢复最小化窗口。")end}}}
    local a=photos();local b=notes();assistant:moveTo(c:Bounds().w-100,c:Bounds().h-150,0)
    return {context=c,photos=a,notes=b,assistant=assistant}
end
function Start()Host.start(M.build)end
function Stop()Host.stop()end
return M
