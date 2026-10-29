-- SPDX-License-Identifier: MIT
local M = {}
M.defaults = {
    face={195,199,203,255}, light={210,210,210,255}, lighter={230,230,230,255}, white={255,255,255,255},
    shadow={134,138,142,255}, dark={0,0,0,255}, text={0,0,0,255},
    disabled={134,138,142,255}, selection={0,14,122,255}, selectionText={255,255,255,255},
    title={0,14,122,255}, inactiveTitle={127,120,127,255}, inactiveTitleText={254,254,254,255}, titleText={254,254,254,255}, desktop={0,128,128,255},
    paper={255,255,255,255}, tooltip={255,255,225,255}, error={160,0,0,255},
    font="sans", fontSize=13, gap=6, padding=6, iconSize=16, border=2,
    rowHeight=20, controlHeight=23, titleHeight=20, titleButtonWidth=17, titleButtonHeight=14, scrollbar=17, density="compact",
}
function M.create(overrides, density)
    local t={} ---@type table<string,any>
    for k,v in pairs(M.defaults) do if type(v)=="table" then t[k]={table.unpack(v)} else t[k]=v end end
    if density=="touch" then
        t.density="touch"; t.fontSize=15; t.rowHeight=44; t.controlHeight=44
        t.titleHeight=44; t.titleButtonWidth=44; t.titleButtonHeight=44; t.scrollbar=24; t.gap=8; t.padding=10
    end
    for k,v in pairs(overrides or {}) do if type(v)=="table" then t[k]={table.unpack(v)} else t[k]=v end end
    return t
end
return M
