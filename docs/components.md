# v1 component completion and implementation map

All entries below are implemented, not placeholders. “Implemented” describes the Lua/Windows-native scope; phone, IME, Web and accessibility limitations remain in [validation](validation.md). `C` means `scripts/win95/Controls.lua`; other filenames below are in the same directory. The engine is a runtime dependency, not redistributed source.

| Public component | Implementation / engine reuse | Actual v1 behavior |
|---|---|---|
| Frame, Panel | C / Widget, Yoga | Inset/raised 2-pixel bevel, background, children, clipping/layout |
| Label | C / font measurement | UTF-8, CJK character wrapping, alignment, color, clipping |
| Button, IconButton | C / unified PointerEvent | Click/keyboard callback, pressed/focus/hover tracking, disabled guards |
| Separator, GroupBox | C | Two-tone separator, caption interrupts etched border |
| Tooltip | Context | Delayed hover, explicit immediate show, bounds, owner destruction cleanup |
| ProgressBar, Busy | C | Clamped progress; animated indeterminate bars |
| Checkbox, Toggle | C | Boolean state/change event, Space/Enter, checked/selected style |
| RadioGroup | C | Exclusive enabled option, arrow keys skip disabled choices |
| TextInput | TextInput / engine TextField | Real engine text events, clipboard/edit menu inheritance, validation, max codepoint count, selection |
| TextArea | TextInput / engine TextField | Multiline Enter, UTF-8 wrap, caret/selection, Home/End/Up/Down, mouse selection, touch pan/wheel |
| NumberInput | TextInput | Intermediate text, numeric validation, min/max, increment/decrement, commit on blur/submit |
| Select | Menus | Options model, actual value, keyboard open/select, disabled options, focus return |
| Slider | C | Pointer/touch drag, keyboard steps/Home/End, clamped stepped values/changeEnd |
| Tabs | Views | Switch actual content visibility, keyboard arrows, disabled tabs |
| ScrollView | Views / engine ScrollView | Native wheel/pan/momentum, classic interactive scrollbar, cancellation; reserves vertical scrollbar gutter |
| ListView | Views / engine VirtualList | Stable IDs, single selection, recycled fixed-height rows, keyboard navigation; bounds initial unattached Yoga measurement |
| Table | Views / ListView | Weighted columns, clickable sort headers, single selected row, callbacks |
| TreeView | Views / ListView | Stable-ID node model, flattened visible rows, expansion, keyboard parent/child, click/tap expand |
| MenuBar | Menus | Host menu definitions, keyboard movement/open, wraps on narrow widths |
| PopupMenu, ContextMenu, StartMenu | Menus | Scroll, selected/checked/disabled items, outside dismissal, nested submenus, flipping/clamping, Escape/Tab and type-to-first-letter |
| Window + title bar | Windows | Close, optional minimize, maximize/restore, drag, resize grip, active/inactive, context-local layer order |
| Modal, MessageBox | Windows | Pointer blocker, focus trap/restore, nested modal stack, confirm/cancel/result, Escape |
| Desktop, DesktopIcon | Windows / C | Host app model; single tap/click launches; no OS/filesystem access |
| Taskbar | Windows | Window registration, activation/minimize/restore, title/state updates, horizontal scrolling, StartMenu |
| StatusBar | Views | Independently updateable inset text fields |
| ImageViewer | Media / nvgCreateImage or nvgCreateVideo | Lazy load, reference count, borrowed Texture2D, contain/cover, crop rectangle, ready/error callbacks |
| Thumbnails | Media | Image/texture-backed selectable buttons, disabled items, host value callbacks |
| Rect/opacity tween | Tween + Context | Cancel, redirect continuously from current value, completion/cancellation callback; windows preserve rect state |
| Icons | Icons | 29 original 16-grid geometric icons; 16/32 and arbitrary size, disabled rendering, registration |
| Assistant | Assistant + Media | Replaceable frame/sheet character, idle/greet/point/think, queued actions/cancel, move tween, Chinese speech, touch dismissal, bounds |

## State and density policy

Normal and hover keep the same classic Windows 95 bevel (no modern hover glow). Pressed buttons invert the bevel and offset text. Keyboard focus uses a dotted rectangle. Selected rows, menus and tabs show selection consistently. Disabled controls do not activate or edit; text/icons use the disabled palette. Window titles show active/inactive color. Busy animation and selection semantics are only applied where meaningful.

`compact`: 28-unit controls / 26-unit rows. `touch`: 44-unit controls, rows, title actions and tabs, and 44-unit resize hit area. Checkbox/radio marks stay small inside their full-row targets. The scrollbar has a narrower classic visual; ordinary touch scrolling does not depend on hitting it. Core actions have single-click/tap controls; hover tips, right click and precision dragging are optional.

## Deliberate v1 scope

- Lists/tables use fixed row height and single selection. No editable spreadsheet cells, column dragging, variable-height virtualization or arbitrary HTML rich text.
- Tree IDs must be unique; expansion is host-model based. No implicit disk enumeration or process control.
- Menus open submenus by click/tap/Right; hover-only cascading is not needed to operate them.
- Window resize is a lower-right grip; maximize/restore remain usable without precision dragging. With no Taskbar, minimize is absent by default; a host explicitly enabling it supplies its own restore route.
- TextArea is plain text. Real IME composition and mobile editing remain platform-verification work, not claimed as passed.
- The assistant accepts this library's documented deterministic frame format. It does not implement clippyjs weighted branching, sound tracks, TTS or distribute Microsoft characters.
- No native accessibility/screen-reader bridge is claimed for NanoVG widgets.
