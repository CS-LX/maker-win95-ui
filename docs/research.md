# Reference study and design decisions

Study dates: 2026-10-28–29. Source pins below identify what was actually read, not a floating latest version. No upstream JS/CSS implementation or bitmap/sprite/font was copied into the Lua runtime library.

| Source | Pin / package | Files and demos read |
|---|---|---|
| [React95/React95](https://github.com/React95/React95/tree/97bd045e3133ac1f3c239e3caece74910a7b1291) | `97bd045e3133ac1f3c239e3caece74910a7b1291`; core 10.0.6, clippy 2.2.3 | LICENSE; core Button.tsx/Button.css.ts, Modal.tsx, TaskBar.tsx; clippy ClippyProvider.tsx, clippyjs.d.ts; icons README; button/useModal stories and their play assertions |
| [react95-io/React95](https://github.com/react95-io/React95/tree/871d5335daebdda1469f66f81266523f4191a595) | `871d5335daebdda1469f66f81266523f4191a595`; package reports 0.0.0-development, so SHA is authoritative | LICENSE; original.ts theme; common/index.ts bevel primitives; Button.tsx + Button.stories.tsx; Select/useSelectState.ts + Select.tsx; Window.tsx; font README/license |
| [clippyjs](https://github.com/pi0/clippyjs/tree/84b798e4a56ab4674d8ac45113ad80146a70e342) | npm 0.1.0, gitHead `84b798e4a56ab4674d8ac45113ad80146a70e342` | Package dependency metadata; animator.ts, queue.ts, agents/clippy/agent.ts header/frame structure, agent index |

The [first Storybook](https://react95.github.io/React95/) index exposed 85 entries; the [second Storybook](https://storybook.react95.io/) exposed 50. Their story definitions, variants and interaction assertions were read. For 1.1.0, the first reference's actual core 10.0.6 was additionally installed in ignored development dependencies and rendered with its real GlobalStyle, Win95 theme, Frame, TitleBar, Input, Checkbox and Button in Edge. The npm gitHead matches the source pin above. GlobalStyle.css.ts, TitleBar.css.ts, Modal.css.ts, themes/tokens/win95.ts and baseTheme.ts were read to resolve font, dimensions, colors and edge order. Real same-size browser/native captures were inspected, including a local-only upstream icon variant. This does not claim manual traversal of every upstream Storybook story; see [comparison procedure](visual-fidelity.md).

## Comparison and unification

| Concern | First reference | Second reference | Maker decision |
|---|---|---|---|
| Composition | Core pieces plus separate icons and Clippy packages | Broad styled component catalog | One context-scoped Lua API; independent optional modules |
| Theme | CSS/token-driven square chrome | Original palette and bevel common styles | One gray/navy/white/shadow palette, two-layer bevel, no mixing of alternative themes |
| Button/focus | Raised/pressed styles and dotted focus | Multiple button variants and geometry options | Standard raised button; inverse pressed bevel; classic dotted focus; no rounded variants |
| Window/taskbar | Registration and events coordinate minimize/restore/focus | Window chrome is a composable visual component | Real Lua manager owns z-order and visibility; taskbar observes same window instances |
| Select | Component conventions | Dedicated state hook handles selection/navigation | Shared Lua popup stack; disabled skipping, selected value, boundaries, focus return |
| Text | Browser-native editing | Browser input/textarea | Engine TextField editing path; multiline drawing extension, explicit platform caveats |
| Layout | Browser/CSS | Browser/CSS | Existing engine Yoga and ScrollView/VirtualList, small library extensions only |
| Clippy | Provider/API wrapping clippyjs | Separate concern | Resource-neutral assistant runner plus original Byte, no Microsoft redistribution |

The useModal story tests show that taskbar registration, title changes, active state and minimize/restore must update together. This implementation applies those behavioral expectations to real Lua windows. The two references' broad catalogs informed coverage; no claim of source-level compatibility or complete React95 API parity is made.

## Assistant resource study

`@react95/clippy` 2.2.3 depends on clippyjs 0.1.0 and exposes an agent through its provider. clippyjs resources define frame size, a sprite-sheet map, image-coordinate arrays, frame durations in milliseconds, optional audio, overlay counts, weighted branch targets and exit branches. The queue/animator coordinate action completion.

Maker v1 uses an explicit small character contract: actions are named sequences of frames, frame crop rectangles or individual paths, duration in **seconds**, optional loop and a named idle. It supports interruption, FIFO actions, result callbacks, movement and speech independently from character ownership. It does not attempt an unverified weighted-branch converter or ship clippyjs code/sounds. Byte supplies four actual four-frame actions and works offline. A host may author a licensed adapter/resource pack separately.

## Engine capability evidence

Read before implementation: installed Maker UI workflow and local-preview workflow, NanoVG resolution-mode instructions, Lua scripting guide, UI recipe, API index, UI README, full widget-gallery / inventory-drag-drop / 10k-virtual-list examples. Then inspected the actual reference UI/Core/Widget, UI, Input, InputAdapter, Gesture, ImageCache, TextField, ScrollView and VirtualList sources plus scene-to-NanoVG recipe. They were read only.

Native probes use the installed runtime rather than assuming standard Urho3D behavior. They confirmed focus APIs, pointer cancellation, UI scale, texture bridge and Lua 5.4. The default runtime Chinese font path was unavailable; examples therefore explicitly register a permitted bundled font. Runtime mouse-button constants differ from hardcoded web button assumptions: tests use `MOUSEB_LEFT`/`MOUSEB_RIGHT`. An unattached percentage-height virtual list can measure the full data content; the library bounds the initial viewport before reusing the engine pool. Gesture target capture is established before engine gesture recognition to keep drags and recycled-list scrolling stable.

No complete UI engine was replaced or vendored. Runtime build and environment are pinned in [validation](validation.md).
