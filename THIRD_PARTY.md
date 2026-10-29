# Third-party and original asset notices

The top-level MIT license covers this project's original Lua/Python code, original pixel icons, Byte character art and example pixel illustrations. It **does not** convert other parties' artwork or fonts to MIT.

| Material | Source and license | In default public package? |
|---|---|---|
| Original Lua library, examples, tests, tools | CS-LX / maker-win95-ui contributors, 2026; MIT | Yes |
| 29 two-size pixel icons / 58 PNGs | Authored in `tools/icons.py`; Lua scanline modules in `scripts/win95/icondata`; MIT; no bitmap copied from Windows or React95 | Yes |
| Byte monitor assistant | Authored by procedural pixel drawing in `tools/assets.py`, MIT; 16 original frames in `assets/win95/assistant/byte.png` | Yes |
| Garden/night example illustrations | Authored in `tools/assets.py`, MIT | Yes |
| W95font regular/bold | Alle Sava (sava.io), author-distributed OTF files; SIL OFL 1.1 | Yes, unmodified fonts + author README + OFL + hashes |
| Maker Classic Sans regular/bold | Renamed/subsetted weight-400/700 derivatives of Noto Sans SC; SIL OFL 1.1 | Yes, fonts + OFL + source metadata |
| React95/React95 code/design reference | MIT, copyright (c) 2018 React95; pinned in research | Study only; its license notice retained below/in docs/licenses |
| React95/React95 Windows images / icon bitmaps / Microsoft Clippy | Project license explicitly excludes Microsoft-owned images; redistribution rights not established here | **No** |
| react95-io/React95 code/design reference | MIT, copyright (c) 2019 Artur Bień; pinned in research | Study only; license notice retained |
| react95-io bundled MS Sans Serif font | Its source credits lou / FontStruct and CC BY-SA 3.0; not relabeled as MIT | **No** |
| React95/core embedded MS Sans Serif font | Font metadata credits Microsoft and LR-Soft conversion; separate redistribution permission not established | **No font files**; rendered text appears in the visual comparison |
| clippyjs code and Microsoft agent images/sounds | npm 0.1.0 metadata/source studied; agent redistribution rights not established | **No code, images or sounds** |
| UrhoX engine / urhox-libs / SDK | Host-provided engine dependency under its own terms | **No engine/SDK binaries or source** |

## Font details

**W95font**: [distribution page](https://madebyarne.github.io/w95font/), [author ZIP](https://madebyarne.github.io/w95font/assets/files/w95font.zip), SHA-256 `8659859534c3e1d9b031a295d5ae37a4d944cb7693cd68d8ddc5565a604c831d`. The included author README names **Alle Sava / sava.io**, describes an Illustrator/FontSelf pixel-art revival and expressly permits commercial use, embedding and redistribution under OFL. Font copyright/license metadata agrees. The supplied OFL text contains template placeholders; we preserve it together with the substantive author README rather than inventing a filled-in notice. See [author README](assets/win95/fonts/W95font-README.txt), [OFL](assets/win95/fonts/W95font-OFL.txt) and [file hashes](assets/win95/fonts/W95font-source.json). The OTFs are unmodified; this is not the Microsoft/LR-Soft font embedded by React95. `python tools/assets.py --classic-font` verifies the pinned archive hash before installation.

Upstream: [google/fonts at 9862abc066c9b83bf84c3e8ed1fc2d8d48f9bbf0](https://github.com/google/fonts/tree/9862abc066c9b83bf84c3e8ed1fc2d8d48f9bbf0/ofl/notosanssc), `NotoSansSC[wght].ttf`. Source SHA-256: `a3041811a78c361b1de50f953c805e0244951c21c5bd412f7232ef0d899af0da`. Copyright 2014–2021 Adobe (http://www.adobe.com/), Reserved Font Name “Source”. Full [SIL OFL text](assets/win95/fonts/OFL.txt) accompanies the font. Modified family name: **Maker Classic Sans**. The font remains OFL, may be bundled under its conditions, and may not be sold by itself. Keep its license and copyright. Regeneration uses `python tools/assets.py --font` with fontTools in the development environment; it is not needed at runtime.

The Chinese fallback ships static weights 400 and 700; regenerate bold with `python tools/assets.py --cjk-bold`. The complete source hash is checked. Both derivatives retain OFL notices. Basic CJK and declared ranges are retained; this is not a full Unicode font.

The public comparison screenshot uses original Maker icons on both sides. A separate development command can render actual upstream icons for local inspection; those npm files and resulting screenshots stay under ignored `.tmp` and are excluded from both Git and the release archive. No Microsoft icon/character is bundled as a replacement asset. Development package manifests/lockfiles contain references, not upstream font/image payloads.

## Reference software notices

The complete original notices are in [docs/licenses/React95.txt](docs/licenses/React95.txt) and [docs/licenses/react95-io.txt](docs/licenses/react95-io.txt). The first begins: “Windows and all associated images are the property of the Microsoft Corp and are not covered by this license.” This project follows that exclusion; neither the assistant API nor original icons grant rights to Microsoft's assets.

Windows, Microsoft and Clippy names identify the referenced visual tradition or excluded material. This project is not affiliated with or endorsed by Microsoft, React95 or TapTap. Host-added fonts/icons/characters require their own source and license audit.
