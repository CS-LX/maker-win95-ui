-- SPDX-License-Identifier: MIT
-- This host imports only the public entry point and an example bootstrap.
local Host=require("Host")
local M={}
local liveScene,liveTexture,liveTime,liveFrame,liveNode,liveSurface,liveViewport,liveClear
function M.build(kit)
    local picture=kit:Window{title="Host image",width=420,height=330,x=20,y=30,icon="image"}
    local viewer=kit:ImageViewer{src="win95/images/garden.png",fit="contain",width="100%",height=220,
        onReady=function(_,size)print('[Win95] Host image ready '..size.width..'x'..size.height)end,
        onError=function(_,error)print('[Win95] Host image error '..error.message)end}
    picture.content:AddChild(viewer)
    local prefs=kit:Window{title="Host settings",width=300,height=310,x=460,y=80,icon="settings"}
    local liveStatus=kit:Label{text='A live source is created only on request.',wrap=true}
    picture.content:AddChild(liveStatus)
    local function startLive()
        if not liveTexture then
            -- HOST-only producer. The UI library receives only its Texture2D.
            liveScene=Scene();liveScene:CreateComponent('Octree')
            local camera=liveScene:CreateChild('PreviewCamera'):CreateComponent('Camera')
            liveTexture=Texture2D:new();liveTexture:SetNumLevels(1)
            assert(liveTexture:SetSize(128,128,Graphics:GetRGBAFormat(),TEXTURE_RENDERTARGET))
            liveViewport=Viewport:new(liveScene,camera)
            local path=liveViewport:GetRenderPath():Clone()
            while path:GetNumCommands()>0 do path:RemoveCommand(0) end
            local clear=RenderPathCommand:new()
            clear.type=CMD_CLEAR;clear.clearFlags=CLEAR_COLOR;clear.useFogColor=false;clear.clearColor=Color(.1,.5,.8,1)
            clear:SetNumOutputs(1);clear:SetOutputName(0,'viewport');path:AddCommand(clear)
            liveViewport:SetRenderPath(path);liveClear=path:GetCommand(0)
            liveSurface=liveTexture:GetRenderSurface();liveSurface:SetViewport(0,liveViewport);liveSurface:SetUpdateMode(SURFACE_MANUALUPDATE);liveSurface:QueueUpdate()
            liveTime=0;liveFrame=0
            liveNode=Node();local events=liveNode:CreateScriptObject('LuaScriptObject')
            events:SubscribeToEvent('Update',function(_,_,event)
                if not liveTexture then return end
                liveTime=liveTime+event:GetFloat('TimeStep');local frame=math.floor(liveTime*10)
                if frame==liveFrame then return end;liveFrame=frame
                liveClear.clearColor=Color(.2+.15*math.sin(liveTime*2),.4+.25*math.sin(liveTime),.65+.2*math.cos(liveTime),1)
                liveSurface:QueueUpdate()
                if not liveStatus.dead_ then liveStatus:SetText('Host render target: frame '..frame..' / 10 Hz') end
            end)
        end
        viewer:SetTexture(liveTexture,true)
    end
    prefs.content:AddChild(kit:Checkbox{text="Crop to fill",width="100%",onChange=function(_,checked)viewer:SetFit(checked and "cover" or "contain")end})
    prefs.content:AddChild(kit:Button{text="Switch image",onClick=function()viewer:SetSource('win95/images/night.png')end})
    prefs.content:AddChild(kit:Button{text="Live host texture",onClick=startLive})
    prefs.content:AddChild(kit:Button{text="Transition image window",onClick=function()kit:Tween(picture,{x=40,y=80,w=360,h=290,opacity=.85},.6)end})
    prefs.content:AddChild(kit:Label{text="The host gates gameplay input with kit:ConsumesKeyboard() and kit:ConsumesPointer(x,y).",wrap=true})
    return {context=kit,viewer=viewer,picture=picture,settings=prefs,startLive=startLive}
end
function Start()Host.start(M.build)end
function Stop()
    if liveNode then liveNode:Remove();liveNode=nil end
    Host.stop() -- release the borrowed UI handle before its host-owned producer
    if liveSurface then liveSurface:SetNumViewports(0) end
    if liveTexture then liveTexture:Dispose() end
    if liveScene then liveScene:Remove() end
    liveSurface=nil;liveViewport=nil;liveClear=nil;liveTexture=nil;liveScene=nil
end
return M
