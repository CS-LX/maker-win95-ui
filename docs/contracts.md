# Host, input, layout and resource contracts

## Ownership and lifecycle

The host owns the engine UI singleton: initialization, root selection, global font registration, automatic event wiring and final shutdown. `require('win95')` is side-effect free with respect to that singleton. `Win95.new(container)` appends one owned subtree; it never replaces the container or changes `UI.Theme`. Multiple contexts can share one host UI and have separate palettes/densities/window lists.

The context uses the host's existing UI update traversal, three lightweight `Input` listeners (down/up/cancel), and one owned `LuaScriptObject` subscription to `InputFocus`. Destroying it cancels its pointers/gestures/tweens, removes listeners/event node, clears focus in its subtree, destroys widgets including detached virtual-list pool entries, drops image references and removes its subtree. It leaves the host root and unrelated input focus intact. Destroy the context **before** the host's `UI.Shutdown`. Disabling/hiding a component clears focus/capture within that component. Prefer `Destroy`, not merely dropping Lua references.

The host owns supplied callbacks, data, textures and app commands. Widgets are responsible for releasing their own callback/resource references on destruction. The UI thread executes callbacks synchronously; callbacks should be short. Do not mutate a data array midway through a library operation; replace it via `SetData` afterwards. Do not call destroyed widget methods except idempotent `Destroy`.

## Input isolation

The engine UI receives pointer and text input. The library does not stop the game's engine subscriptions or steal the camera. The host gates its own gameplay handlers:

```lua
-- in the host's gameplay input handler/update:
if not kit:ConsumesKeyboard() then
    -- handle gameplay keys, except keys the host reserves globally
end
local x=input:GetMousePosition().x / UI.GetScale()
local y=input:GetMousePosition().y / UI.GetScale()
if not kit:ConsumesPointer(x,y) then
    -- handle gameplay pointer interactions
end
```

`ConsumesKeyboard()` is true for context-owned focus, any modal, or an open menu. `ConsumesPointer(x,y)` takes **logical/base UI coordinates**, accounts for the hit subtree and active owned pointers. Evaluate the gates for pointer/key down, held actions and releases; do not only gate clicks. Event callback ordering depends on the host. For precise event-based routing, forward input to UI before evaluating the game action. All raw coordinates passed into `UI.HandleMouse*`/`UI.HandleTouch*` are physical pixels; never predivide those.

Tab walks enabled visible focusable controls; Enter/Space activates; Escape closes applicable menus/modals. Text fields retain engine text-input/clipboard handling; the host must honor the keyboard gate to prevent Enter, arrows or typing from also driving gameplay. A host with no current focus can call `kit:FocusNext(false)` for its initial Tab. Keyboard focusing a control raises its containing window.

The context assigns a stable gesture target before the engine gesture listener runs. Scrolling targets the scroll container so recycled rows cannot terminate the gesture. Dedicated drag/slider/text controls keep their own target. The first pointer owns a drag; secondary pointers cannot replace it. A touch suppresses same-context synthetic mouse activation for 0.6 seconds. Cancel, focus loss, hide, resize and destruction release context-owned interactions without globally resetting host input. Touch tests inject the real engine adapter; physical-device behavior remains separate.

## Logical units and resizing

All widget dimensions are UrhoX UI base/logical units. Use the host's `UI.Scale.DEFAULT` for actual DPR, or a documented host design-resolution scale. The library never calls `graphics:SetMode`, creates a second NVG frame, or multiplies rendering coordinates by DPR. Its drawing executes in the engine widget's existing NVG context. Engine hit testing transforms scroll/scale coordinates.

Context layout follows its supplied container. On bounds change, owned pointers/popups/tooltips are cancelled, windows and modals are clamped, and `onResize(width,height)` runs. Windows remain fully inside available bounds, reserving Taskbar height. Content scrolls instead of moving title controls off-screen. Menus flip submenus when needed and scroll/clamp within the mount. Assistant characters and balloons clamp on update. Minimum practical supported layout is 280×250 logical units; the supplied mobile-size tests use 390×844 and 844×390.

The host still chooses responsive content. Arbitrarily fixed oversized host children cannot magically reflow: use `width='100%'`, `flexShrink=1`, wrap or a ScrollView. Library Button constrains its default maximum width to its parent; long labels clip. Tooltips are supplementary, never the only core-action affordance. Modal and menu blockers are scoped to the mounted context; mount across the full game UI if the entire game should be blocked.

## Theme and fonts

`Theme.lua` centralizes the classic palette, font family/size, control/row/title heights, spacing, icon size and scrollbar width. Factory `theme` overrides are copied per context. The two-layer square bevel and dotted focus geometry are intentionally classic. No global engine theme mutation occurs. Configure density at context creation; recreate the context or explicitly resize widgets if changing density later.

The host registers fonts through `UI.Init{fonts=...}` and selects the family via `theme.font`. The bundled optional **Maker Classic Sans** is a renamed weight-400 Noto Sans SC subset, covering Latin, common punctuation, arrows, box drawing, basic CJK U+4E00–9FFF and full-width punctuation; see `tools/assets.py` for exact ranges. It is antialiased, not an exact Microsoft bitmap-font clone. Example bold aliases the same permitted static font. Complex scripts, emoji, supplementary CJK and fallback fonts are host responsibilities.

TextInput delegates actual committed text, caret, selection, clipboard and platform text activation to the installed engine `TextField`. TextArea adds multiline layout/selection on that same input path. Chinese glyph drawing and committed-string editing are tested. **This does not validate IME composition UI, candidate positioning or a mobile soft keyboard.** Do not claim those work until testing on the intended platform.

## Images and live textures

`ImageViewer{src=resourcePath}` creates a context-local lazy NanoVG image on first render. Identical paths share one reference-counted handle. `SetSource` releases the previous reference; `Destroy` removes the final NVG image. Errors are cached per attempt; explicitly call a setter to retry. `onReady`/`onError` are emitted on update after load, never by repeatedly rebuilding the widget tree.

`ImageViewer{texture=hostTexture}` uses `nvgCreateVideo(nvg, Texture2D)` as the engine's live-texture bridge. The source is **borrowed**: releasing the viewer calls `nvgDeleteVideo`, never texture disposal, camera removal or render-surface shutdown. Keep the texture alive while borrowed. The host owns render target size, producer scheduling, camera/scene, refresh, aspect, and readiness. Use `ready=false` until the host producer is usable, then `SetReady(true)`. If replacing/reallocating the Texture2D (including `SetData(Image)` on this runtime), call `SetTexture` again. Prefer a stable render target plus `surface:QueueUpdate()` for continuous rendering. Stopping the producer or freeing a borrowed source while rendering is a host error.

`contain` preserves the source aspect ratio with empty margins; `cover` preserves it and clips overflow. Optional `crop={x,y,w,h}` uses source pixels before fitting. Source must have valid positive dimensions. Cropping and clipping share the existing engine NVG scissor stack. The library has no map/camera/TTS/audio dependency. Native tests validate shared path handles and borrowed Texture2D survival; animated render-target production on devices remains host integration verification.

## Package and tooling

Runtime installation consists of `scripts/win95` and desired `assets/win95` resources plus applicable notices. Examples, tests and Python tools are development-only. No upstream repository, SDK, native executable, dependency download or `.local.json` belongs in the archive. `tools/check.py` accepts `--runtime`, `URHOX_RUNTIME`, or an ignored local runtime locator. The release remains usable with no hidden workspace files.
