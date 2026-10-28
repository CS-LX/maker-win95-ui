# Third-party and original asset notices

The top-level MIT license covers this project's original Lua/Python code, original geometric icons, Byte character art and example pixel illustrations. It **does not** convert other parties' artwork or fonts to MIT.

| Material | Source and license | In default public package? |
|---|---|---|
| Original Lua library, examples, tests, tools | CS-LX / maker-win95-ui contributors, 2026; MIT | Yes |
| 29 geometric pixel icons | Authored in `scripts/win95/Icons.lua`, MIT; no bitmap copied from Windows or React95 | Yes |
| Byte monitor assistant | Authored by procedural pixel drawing in `tools/assets.py`, MIT; 16 original frames in `assets/win95/assistant/byte.png` | Yes |
| Garden/night example illustrations | Authored in `tools/assets.py`, MIT | Yes |
| Maker Classic Sans | Renamed/subsetted weight-400 derivative of Noto Sans SC; SIL OFL 1.1 | Yes, font + OFL + source metadata |
| React95/React95 code/design reference | MIT, copyright (c) 2018 React95; pinned in research | Study only; its license notice retained below/in docs/licenses |
| React95/React95 Windows images / icon bitmaps / Microsoft Clippy | Project license explicitly excludes Microsoft-owned images; redistribution rights not established here | **No** |
| react95-io/React95 code/design reference | MIT, copyright (c) 2019 Artur Bień; pinned in research | Study only; license notice retained |
| react95-io bundled MS Sans Serif font | Its source credits lou / FontStruct and CC BY-SA 3.0; not relabeled as MIT | **No** |
| clippyjs code and Microsoft agent images/sounds | npm 0.1.0 metadata/source studied; agent redistribution rights not established | **No code, images or sounds** |
| UrhoX engine / urhox-libs / SDK | Host-provided engine dependency under its own terms | **No engine/SDK binaries or source** |

## Font details

Upstream: [google/fonts at 9862abc066c9b83bf84c3e8ed1fc2d8d48f9bbf0](https://github.com/google/fonts/tree/9862abc066c9b83bf84c3e8ed1fc2d8d48f9bbf0/ofl/notosanssc), `NotoSansSC[wght].ttf`. Source SHA-256: `a3041811a78c361b1de50f953c805e0244951c21c5bd412f7232ef0d899af0da`. Copyright 2014–2021 Adobe (http://www.adobe.com/), Reserved Font Name “Source”. Full [SIL OFL text](assets/win95/fonts/OFL.txt) accompanies the font. Modified family name: **Maker Classic Sans**. The font remains OFL, may be bundled under its conditions, and may not be sold by itself. Keep its license and copyright. Regeneration uses `python tools/assets.py --font` with fontTools in the development environment; it is not needed at runtime.

## Reference software notices

The complete original notices are in [docs/licenses/React95.txt](docs/licenses/React95.txt) and [docs/licenses/react95-io.txt](docs/licenses/react95-io.txt). The first begins: “Windows and all associated images are the property of the Microsoft Corp and are not covered by this license.” This project follows that exclusion; neither the assistant API nor original icons grant rights to Microsoft's assets.

Windows, Microsoft and Clippy names identify the referenced visual tradition or excluded material. This project is not affiliated with or endorsed by Microsoft, React95 or TapTap. Host-added fonts/icons/characters require their own source and license audit.
