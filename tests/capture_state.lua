-- SPDX-License-Identifier: MIT
-- Named, reusable capture states. No runtime entry replacement or host business dependencies.
return function(demo,state)
    local c=demo.context;local UI=require('urhox-libs/UI')
    if state=='assistant' then
        local a=demo.assistant or c:Assistant{x=c:Bounds().w-100,y=c:Bounds().h-110}
        a:show():play('greet'):play('think',{queue=true}):play('point',{queue=true})
        a:speak('你好！我是 Byte。点击按钮打开应用；我的文字和动作都由宿主控制。')
    elseif state=='modal' then
        c:MessageBox{title='Confirm / 确认',message='A real modal: Tab stays here. Enter confirms; Esc cancels. 焦点会回到原来的控件。'}
    elseif state=='submenu' then
        c:PopupMenu{x=c:Bounds().w-15,y=c:Bounds().h-15,items={{label='Applications',children={{label='Enabled',icon='folder'},{label='Disabled',disabled=true},{label='Checked',checked=true}}}}}
        UI.HandleKeyDown(KEY_RIGHT)
    elseif state=='last-row' and demo.list then
        demo.tabs:SetValue('data');UI.Layout();demo.list:Update();demo.list:Focus();UI.HandleKeyDown(KEY_END)
    elseif state=='live' and demo.startLive then demo.startLive()
    end
end
