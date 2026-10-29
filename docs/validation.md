# Validation, limitations and independent reproduction

Date: 2026-10-29, Asia/Shanghai; v1.1.0. Scope: standalone native library, not integration into any game. The repo and all test resources are independent of the reference game's working tree, entry, Git config and Maker binding.

## Actual environment

| Item | Observed value |
|---|---|
| OS | Windows 11 Home Chinese, 10.0.26200, x64 |
| CPU | Intel Core i9-13980HX |
| Graphics adapters | RTX 4060 Laptop GPU (driver 32.0.15.6607), Intel UHD (32.0.101.6790); virtual display adapters also installed; no claim of isolating a single GPU for measurements |
| Runtime build.json | UrhoXRuntime `20260923-1717-bf3316f` |
| Runtime commit | `bf3316fd21de510af2fec2a9df99d476536f1b1e` |
| Engine resource tag | `maker_validate_window.0923` |
| Maker CLI | `@taptap/maker` 0.0.37-beta.11 |
| Language | Native `_VERSION` reports Lua 5.4 |
| Actual device DPR | 1.00; UI scale 1 and 2 exercised separately |
| Maker binding | Standalone workspace unbound; CLI preview requires `.maker-mcp/config.json`, so tests launch the already installed native Runtime directly |

No SDK or engine binary is in the repo/ZIP. No cloud Maker project was created or modified. A Maker Web/cloud build is not claimed. Two installed-runtime startup messages occur before UI initialization: `Could not find resource Cube/Day/DaySpecularHDR.dds` and `Can not load themis_x64.dll.` The UI scenes do not use that environment cubemap/anti-cheat module. The runner reports both and fails any other `ERROR:`; they are not silently generalized away.

## Automated/native coverage

`tests/native.lua` uses **real** UrhoX UI, Yoga, NanoVG image handles and `UI.HandleMouse*`, `UI.HandleTouch*`, `UI.HandleKeyDown`, `UI.HandleTextInput`. It does not stub the engine. Mouse/touch/key events are injected by the engine adapter, not physical fingers or an OS IME. Each case creates/destroys a context while preserving the host UI root.

The 33 checks cover: host ownership; actual click and disabled/keyboard behavior; change notifications and Tab; radio skipping; touch/mouse deduplication and two fingers; Chinese committed input/delete/validation; multiline navigation/wrap; numeric commit; slider drag; Select keyboard/focus; submenu boundaries/close/click-through; linked taskbar/window states; modal focus trap/restore; drag cancellation; 10k list pooling; table/tree/tabs; continuous tween redirect; shared path and borrowed texture handles; assistant queues/cancel/speech/passthrough; 50 lifecycle cycles; stable idle object/resource identity; touch hit sizes/theme isolation; right-click/tooltip destruction; multiline drag selection; resize grip/multitouch cancellation; container resize; window tween rect consistency; scroll gesture across recycled rows; host texture reallocation and explicit rebinding; separate regular/bold and working CJK fallback fonts; compact/touch title geometry and action clicks; separate icon sizes/custom registration; scrollbar arrows/thumb drag/cancellation.

| Configuration | Result |
|---|---|
| 1100×720, compact, UI scale 1 | 33 checks pass |
| 390×844, touch, UI scale 1 | 33 checks pass |
| 844×390, touch, UI scale 1 | 33 checks pass |
| 1100×720 framebuffer, compact, UI scale 2 (550×360 logical) | 33 checks pass |
| Native `loadfile` syntax check | 52 Lua files pass |
| EmmyLua MCP diagnostics, severity 1 | 52 opened Lua files: no returned errors; native loading remains the authoritative runtime check |
| Clean archive install | All three examples plus visual fixture launch/render from extracted release files; 33 checks pass in all four configurations; manifest and package audit pass; clean/development visual fixture screenshots are pixel-identical |

See the compact machine-readable [results](test-results.json) for measured runs. The tests check 44-unit primary targets in touch mode. They check container resizing, not a phone sensor-driven rotation event. A real high-DPI display is not available; scale 2 verifies the library's coordinate contract without mislabeling DPR hardware.

## Screenshot review

Screenshots were captured with the native runtime's `graphics:TakeScreenShot`, opened and visually reviewed. They are not browser or mock rendering. Only representative images are retained:

- [Desktop and animated Byte speech](screenshots/desktop.png)
- [10,000th list row / table / tree](screenshots/data.png)
- [Icon sizes and disabled variants](screenshots/icons.png)
- [Portrait touch form](screenshots/portrait.png)
- [Landscape touch modal and focus ring](screenshots/landscape.png)
- [UI scale 2](screenshots/scale2.png)
- [Minimal host using a live updated Texture2D](screenshots/live-texture.png)
- [Narrow-screen submenu](screenshots/menu.png)
- [Same-content 960×640 React95/native comparison](visual-fidelity.md) (actual browser reference next to native output; licensed icons on both sides)

The minimal example's **Live host texture** button creates a 128×128 render target in the host, updates an isolated empty preview scene's clear color at 10 Hz, and shows a frame counter while ImageViewer keeps its bridge. The host owns that preview scene/camera/surface; the library receives only the Texture2D and neither creates nor updates the producer. Render-target behavior on phone/Web remains an additional host test. `Texture2D:SetData(Image)` can reallocate the GPU resource in this runtime; rebind with `SetTexture` afterwards rather than assuming the old bridge stays valid.

## Performance observations

The native suite's 50 create/destroy cycles (window, assistant, speech and textures) took **0.401–0.470 seconds** in the four recorded runs; ending counts returned to the initial four context widgets, zero windows/captures and zero image handles. 1,000 context/assistant state updates took **0.009–0.010 seconds**, with unchanged widget count and image-handle identity. This is a state-update microbenchmark, not whole-frame GPU time or proof of zero engine allocations.

Captured desktop+speech run: 109 measured frame intervals, mean **21.495 ms**, p95 **31.094 ms**. Data gallery: 79 samples, mean **16.872 ms**, p95 **17.255 ms**. Portrait form capture: 79 samples, mean **16.835 ms**, p95 **17.182 ms**. Scheduling/vsync and foreground/background state varied; these observations are not a cross-platform performance guarantee. Native virtual-list checks bound live/pool widgets to the viewport, and detect initial accidental creation of all 10,000 rows. Idle updates do not rebuild the tree, reload images or re-layout an unchanged speech balloon.

## What remains unverified or limited

| Item | Status / independent validation procedure |
|---|---|
| Android/iOS actual device | **Unverified.** Install examples into a separately bound Maker sample, run on devices; tap every action, drag/scroll with two fingers, cancel by app switch, rotate with menus/modals open. |
| Mobile soft keyboard | **Unverified.** Focus both text fields, type Chinese, move caret, dismiss/reopen keyboard; check viewport shrink, title/OK reachability and focus retention. |
| Windows/phone IME composition | **Unverified.** Select a real Chinese IME, compose without committing, choose candidates, backspace during composition, move/resize field; inspect candidate placement and ensure gameplay keys remain gated. Committed strings are already tested. |
| Web build / WebView | **Web export unverified.** Use a separate sample's normal Maker cloud workflow. Runtime architecture needs no WebView or DOM. |
| Actual hardware DPR > 1 | **Unverified.** Repeat captures/clicks on a high-DPI display with UI.Scale.DEFAULT; compare physical size vs logical coordinates. UI scale 2 simulation passed. |
| Full platform focus-loss event path | **Partially verified.** Library's cancellation and host-focus preservation pass; physically Alt-Tab/app-switch mid-drag still belongs in manual acceptance. |
| Clipboard/native edit menu | Inherited from engine TextField; no OS clipboard permissions/device edit-menu certification claimed. |
| Accessibility | No screen-reader/accessibility bridge in v1. Keyboard support is implemented, not equivalent to native accessibility APIs. |
| Advanced table/text/animation scope | Single selection/fixed-height rows, plain text, deterministic sprite frames. See component matrix; no silent TODO components. |
| Microsoft assets | Excluded by design; original Byte is executable, not an empty replacement interface. |

## Another agent's reproduction order

1. Checkout release tag `v1.1.0` and record `git rev-parse HEAD`; compare with the release handoff commit. Use an independent folder, never the game's directory. Read README, contracts, components, visual-fidelity and THIRD_PARTY.
2. Locate an installed UrhoXRuntime and inspect its adjacent `build.json`. Set `URHOX_RUNTIME` or pass `--runtime`. Do not download a replacement SDK or fabricate a Maker binding to run tests.
3. Run `python tools/check.py audit`, `python tools/check.py probe`, `python tools/check.py syntax` and the four native test commands below. Treat a timeout, exception, missing PASS, or unexpected ERROR as a failure.
4. Capture each example; open the actual PNGs, compare expected layout, then run an interactive native preview. Use the gallery tabs; edit the Chinese field, choose Select values, scroll to last row, expand tree, sort columns, open menus/dialogs, interrupt motion, operate Byte actions. Close previews between runs.
5. On desktop: open apps from icons/Start, activate overlapping windows, minimize and restore via taskbar, resize and cancel a drag outside/through focus loss. On minimal: select **Live host texture**, crop, switch image, redirect window tween. Confirm only host handlers update resources.
6. Build the package, extract into a **new empty** independent folder, run audit with `--project`, syntax, native tests and three captures against that folder. The runner's resource prefix must reference only that extracted folder plus the installed engine, not a development folder. Check `MANIFEST.sha256`.
7. Perform the explicitly unverified platform tests above when equipment is available. Do not convert window-size screenshots into a mobile-device pass. Integration into a game follows only after the receiving agent's independent acceptance.

```powershell
$env:URHOX_RUNTIME='C:\path\to\installed\UrhoXRuntime.exe'
python tools/check.py audit
python tools/check.py probe
python tools/check.py syntax
python tools/check.py test --width 1100 --height 720
python tools/check.py test --width 390 --height 844 --density touch
python tools/check.py test --width 844 --height 390 --density touch
python tools/check.py test --width 1100 --height 720 --scale 2
python tools/check.py capture --example desktop --state assistant --width 1100 --height 720 --frames 120
python tools/check.py capture --example gallery --tab data --state last-row --width 1100 --height 720
python tools/check.py capture --example gallery --tab icons --width 1100 --height 720
python tools/check.py capture --example gallery --tab forms --width 390 --height 844 --density touch
python tools/check.py capture --example gallery --tab windows --state modal --width 844 --height 390 --density touch
python tools/check.py capture --example gallery --tab forms --width 1100 --height 720 --scale 2
python tools/check.py capture --example minimal --state live --width 1100 --height 720 --frames 120
python tools/check.py capture --example gallery --tab windows --state submenu --width 390 --height 844 --density touch
python tools/check.py package
# Use a new empty folder below; do not overwrite an existing installation.
Expand-Archive -LiteralPath dist/maker-win95-ui-1.1.0.zip -DestinationPath C:\scratch\win95-clean
python tools/check.py audit --project C:\scratch\win95-clean
python tools/check.py syntax --project C:\scratch\win95-clean
python tools/check.py test --project C:\scratch\win95-clean
python tools/check.py capture --project C:\scratch\win95-clean --example gallery
python tools/check.py capture --project C:\scratch\win95-clean --example desktop
python tools/check.py capture --project C:\scratch\win95-clean --example minimal --state live
```

`preview` uses the same paths/arguments but leaves the window interactive until close or timeout. All transient launch scripts are removed after completion. Capture logs/PNGs overwrite matching configurations under `.tmp`; published evidence is the small curated set here, not accumulated recordings or historical packages. After closing previews and keeping any needed local-only icon comparison, `pwsh -File tools/cleanup-temp.ps1` removes this repository's temporary development dependencies, extracted test package and intermediate captures. It never touches a game or the installed engine. None of `.tmp` enters the release archive.

Live captures also read two actual framebuffer pixels 30 frames apart or more and require a nonwhite changing result. Both development and clean-package render-target captures passed (`LIVE PIXELS PASS`; development RGB delta 0.5608); this guards against a successful API call with a blank texture on screen.
