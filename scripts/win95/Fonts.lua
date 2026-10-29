-- SPDX-License-Identifier: MIT
-- Explicit host opt-in; loading win95 never registers or replaces a global font.
local F={}
function F.options(root,family)
    root=root or 'win95';family=family or 'sans'
    return {
        {family=family,weights={normal=root..'/fonts/W95font.otf',bold=root..'/fonts/W95font-Bold.otf'}},
        {family=family..'-cjk',weights={normal=root..'/fonts/MakerClassicSans.ttf',bold=root..'/fonts/MakerClassicSans-Bold.ttf'}},
    }
end
function F.attach(UI,family)
    family=family or 'sans';local n=assert(UI.GetNVGContext(),'initialize the host UI first')
    local fallback=family..'-cjk'
    assert(nvgFindFont(n,family)>=0 and nvgFindFont(n,family..'-bold')>=0 and nvgFindFont(n,fallback)>=0,'register Fonts.options before attaching fallbacks')
    -- This runtime returns 0 even after successful registration. Validate real
    -- glyph rendering/metrics, not the upstream C return convention.
    nvgAddFallbackFontId(n,nvgFindFont(n,family),nvgFindFont(n,fallback))
    assert(nvgFindFont(n,fallback..'-bold')>=0,'register the CJK bold face')
    nvgAddFallbackFontId(n,nvgFindFont(n,family..'-bold'),nvgFindFont(n,fallback..'-bold'))
end
return F
