# Lua API v1

```lua
local Win95 = require('win95')
local kit = Win95.new(hostContainer, {
    density='touch',                  -- compact by default
    assetRoot='win95',                -- default assistant resource root
    theme={font='host-font', fontSize=15, title={0,0,128,255}},
    onResize=function(w,h) end,
    onWindowsChanged=function(windows,active) end,
})
```

Call after the host's `UI.Init`. Every factory is `kit:Component{props}`. Creation returns an engine-compatible widget; `kit:Add(widget)` mounts it in the context's content layer, or use `parent:AddChild(widget)`. `Window`, `Modal`, `Taskbar`, `Desktop`, `Assistant` and popup menus mount themselves in their appropriate layers. Use `window.content:AddChild` for window contents. Native Yoga props (`width`, `height`, `flexDirection`, `gap`, `padding`, `flexGrow`, etc.) are available. Give flex/scroll layouts a definite parent size.

For the bundled classic Latin + Chinese fonts: `UI.Init{fonts=Win95.Fonts.options('win95','sans')}`, then `Win95.Fonts.attach(UI,'sans')`. Both calls are explicit host decisions; use a different family and matching `theme.font` to coexist with another UI. Register normal and `family..'-bold'` when providing a custom font. The library does not register fonts on import. See the font/license and input contracts before integrating.

Read managed state with `kit:GetWindows()`, `kit:GetActiveWindow()`, `window:GetWindowState()` (active/minimized/maximized/visible/rect), `image:GetStatus()` (pending/ready/error), `list:GetPoolStats()` (inUse/available/total), and `kit:Stats()` (widgets/windows/captures/resources). Returned window arrays and rect snapshots are copies; change behavior through the documented setters.

## Common operations

`SetStyle{...}`, `AddChild`, `Remove`, `SetVisible(bool)`, `SetDisabled(bool)`, `Focus()`, `SetText/GetText`, `SetValue/GetValue`, `Destroy()` are the regular widget operations. Only use value/text operations on components that own those properties. `Remove()` detaches without destruction. `Destroy()` is idempotent on library widgets and disposes their children. Call it explicitly; Lua GC alone is not a Yoga/resource cleanup API.

Callbacks receive `(widget, ...)`: `onClick(widget,event)`, `onChange(widget,value)`, `onFocus(widget)`, `onBlur(widget)`, `onCancel(widget,event)`. `event` may be nil for keyboard/programmatic activation. `onChange` fires when the value actually changes, including programmatic `SetValue`, not when assigning the same value. Prefer setters to direct `props` mutation, particularly for disabled/visible/value state. `OnEvent('change', handler)` / `OffEvent('change', handler)` expose engine listener registration; library cleanup removes its listeners. Do not destroy the global UI in a component callback.

## Forms and data

| Factory | Important props / methods |
|---|---|
| Button/IconButton | `text`, `icon`, `tooltip`, `disabled`, `onClick`; `SetText` |
| Label | `text`, `wrap`, `color`, `textAlign`; `SetText` |
| Frame/GroupBox | `inset`, `backgroundColor`; GroupBox caption=`text` |
| ProgressBar/Busy | `value` in 0..1; Busy has no progress requirement |
| Checkbox/Toggle | boolean `value`, `onChange`; Checkbox `SetChecked/IsChecked` |
| RadioGroup | `options={{value,label,disabled}}`, `value`; `SetValue`, `Step(+1/-1)` |
| TextInput/TextArea | `value`, `placeholder`, `maxLength` codepoints, `validate(value)->ok,reason`, `onChange`, `onInvalid(widget,value,reason)`, `onSubmit`; `SetValue`, `GetValue` |
| NumberInput | `value`, `min`, `max`, `step`; `SetValue` rejects NaN/infinity, `Commit()` |
| Select | `options={{value,label,disabled}}`, `value`, `maxHeight`; `SetOptions`, `SetValue`, `Open()` |
| Slider | `min/max/step/value`, `onChange`, `onChangeEnd`; `SetValue` |
| Tabs | `tabs={{id,label,content,disabled}}`, `value`; `SetValue(id)` |
| ScrollView | `scrollX`, `scrollY`, `showScrollbar`, `chrome=false` to omit the inset frame; engine `GetScroll`, `SetScroll(x,y)` |
| ListView | `data={{id,label,icon,disabled}}`, `value`, height; `SetData`, `SetValue(id)`, `Select(index,activate)`, `onSelect(widget,item,index)` |
| Table | `data`, `columns={{key,title,width}}` (width is a weight); `SetData`, `SetValue`, `Sort(key)`, `onSort(widget,key,descending)`, `onSelect` |
| TreeView | `data={{id,label,icon,disabled,children={...}}}`; `SetData`, `SetValue`, `ToggleNode(id)`, `onExpand(widget,id,expanded)`, `onNodeSelect(widget,node)` |
| StatusBar | `items={'Ready','...'}; SetText(text,fieldIndex=1)` |

List/Tree item IDs are stable model identifiers, not array indices. A plain ListView may omit IDs and use its 1-based index. Removing the selected item clears its value and emits change. `Table:Sort` copies the array; it does not mutate the host's original ordering. Host record objects remain host-owned. Avoid mutating them during callbacks; call `SetData` after updates.

## Menus, windows and desktop

```lua
local commands = {
    {label='Open', icon='folder', action=function(item) openDocument() end},
    {separator=true},
    {label='View', children={
        {label='Details', checked=true, action=function() showDetails() end},
        {label='Unavailable', disabled=true},
    }},
}
local bar = kit:MenuBar{items={{label='File',children=commands}}}
local menu = kit:PopupMenu{anchor=button, items=commands, width=220, maxHeight=300}
-- Or use x/y relative to the context, ContextMenu / StartMenu, above=true.
menu:Close(); kit:CloseMenu()
```

`Window{title,icon,x,y,width,height,minWidth,minHeight,closable,resizable,maximizable,minimizable,beforeClose,onClose,onRect,onMinimize,onRestore}`. Methods: `SetTitle`, `SetRect(x,y,w,h)`, `Minimize`, `Maximize`, `Restore`, `Close`, `Destroy`. `beforeClose(window)==false` vetoes closing. `kit:Activate(window)` raises it. Window dimensions clamp to available context space. Minimize defaults on only when a Taskbar exists; explicit `minimizable=true` means the host also owns a restore route. `onRect(window,rect)` reports layout changes.

`Modal{title,width,height,onResult}` returns `{window,cancel,confirm,close}`; `modal.window.content` accepts children. `modal.cancel()` returns false; `confirm()` true; `close(value)` any result. `MessageBox{title,message,icon,confirmText,cancelText,cancel=false,onResult=function(value)end}` builds buttons and focuses OK. Result callbacks omit the widget argument. Closing the top modal restores valid previous focus. A modal is deliberately absent from Taskbar.

`Desktop{apps={{label,icon,description,open=function(kit)end}},backgroundColor,iconWidth}` and `DesktopIcon{text,icon,onClick}` have single-click/tap activation. `Taskbar{items=commands,text='Start'}` registers current and future windows. Create it before windows if default minimize buttons are wanted. One taskbar per context. Window models are context-local.

`kit:Tooltip{owner=button,text='...',immediate=true}`; `kit:HideTooltip()` removes it. Button `tooltip` shows after a 0.5-second hover; provide visible instructions for touch-essential information.

## Image, texture and thumbnail API

```lua
local image = kit:ImageViewer{
    src='my/images/photo.png', -- or texture=hostTexture, never both
    ready=true, fit='contain', width=320, height=200,
    crop={x=0,y=0,w=128,h=96}, -- optional source-pixel rectangle
    onReady=function(widget,size) print(size.width,size.height) end,
    onError=function(widget,err) print(err.code,err.message) end,
}
window.content:AddChild(image)
image:SetSource('my/images/next.png')
image:SetTexture(hostTexture, false)  -- borrow; do not render it yet
image:SetReady(true)                -- host says the producer is ready
image:SetFit('cover')
image:Destroy()                     -- drops the wrapper; hostTexture survives
```

Use `frame=false` for borderless media. `SetSource`/`SetTexture` clear old handles and allow explicit retry after an error. `ready=false` does not fetch/create the bridge. An error calls `onError` once per attempt; it does not retry every frame. Source paths are complete cache resource names; `assetRoot` only changes library default character assets. `kit:Resource('assistant/byte.png')` joins the configured root for host use.

`Thumbnails{items={{id,src,texture,ready,disabled}},value,itemWidth,itemHeight,onChange}`; `SetItems`, `SetValue`. Items are buttons with images, not disk files.

## Tween and assistant

```lua
local motion=kit:Tween(widget,{x=40,y=20,w=300,h=200,opacity=.8},.6,
    function(completed,reason) end)
kit:Tween(widget,{x=80},.3) -- redirects from the current numeric state
motion:cancel()            -- freezes current value

local a=kit:Assistant{x=40,y=100} -- original Byte by default
a:show():play('greet',{onComplete=function(ok,reason)end})
a:play('point',{queue=true}):play('think',{queue=true})
a:moveTo(160,100,.5,function(ok,reason)end)
a:speak('你好，世界！',{duration=5,onComplete=function()end})
a:stop(); a:hide(); a:Destroy()
```

Tween keys are only `x,y,w,h,opacity`, duration seconds, cubic ease-out. Redirection calls the old callback with `false,'redirected'`; completion `true,'completed'`. A hidden/disabled target cancels with `hidden`; destruction cancels as part of release. No tween dependency or global animation loop is installed. `Win95.Tween.new(values,apply)` also supplies a standalone numeric tween updated explicitly with `:update(dt)`.

Assistant `play` without `queue` interrupts current and pending actions; `queue=true` appends after a finite action (interrupts infinite idle). `loop=true` is explicit looping; character idle loops automatically. `stop` cancels current/queued actions and motion; `hide` also closes the speech balloon. Speech has an explicit touch-size OK button and scrollable long content. The character image passes pointer events through; only its speech balloon has interactive UI.

Replace characters with `Assistant{character=definition}` or `a:SetCharacter(definition)`:

```lua
local character={name='Your character',width=64,height=64,
    sheet='my/character.png', idle='idle', animations={
        idle={loop=true,frames={{x=0,y=0,w=32,h=32,duration=.5}}},
        hello={frames={{x=32,y=0,w=32,h=32,duration=.15},
                       {src='my/final-frame.png',duration=.3}}},
    }}
```

Frames use seconds and source pixels. The host must have redistribution rights. Optional frame `src` changes to a standalone image; otherwise the action crops `sheet`. There is no Microsoft-specific parser or dependency.

## Icon registry

`Win95.Icons.names()` returns sorted names; `kit:Icon{name='folder',size=16,disabled=false}` creates a display widget. `IconButton{icon='folder'}` and `DesktopIcon{icon='folder'}` use the same registry. Built-ins are geometry and require zero texture loads.

```lua
Win95.Icons.register('my-dot',{{6,6,4,4,{255,0,0,255}}})
-- Each rectangle is {x,y,width,height,color}; coordinates are in a 16-unit grid.
-- A custom function(nvg,x,y,size,disabled) is also accepted; it owns any resources.
```

Names: assistant, busy, check, close, computer, down, error, file, folder, help, home, image, info, left, maximize, minimize, minus, play, plus, restore, right, save, search, settings, start, stop, trash, up, warning. The Icons gallery previews 16/32/disabled variants.
