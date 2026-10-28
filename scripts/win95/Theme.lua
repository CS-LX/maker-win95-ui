-- SPDX-License-Identifier: MIT
local M = {}
M.defaults = {
    face={192,192,192,255}, light={223,223,223,255}, white={255,255,255,255},
    shadow={128,128,128,255}, dark={0,0,0,255}, text={0,0,0,255},
    disabled={128,128,128,255}, selection={0,0,128,255}, selectionText={255,255,255,255},
    title={0,0,128,255}, inactiveTitle={128,128,128,255}, desktop={0,128,128,255},
    paper={255,255,255,255}, tooltip={255,255,225,255}, error={160,0,0,255},
    font="sans", fontSize=13, gap=6, padding=8, iconSize=16, border=2,
    rowHeight=26, controlHeight=28, titleHeight=26, scrollbar=16, density="compact",
}
function M.create(overrides, density)
    local t={}
    for k,v in pairs(M.defaults) do if type(v)=="table" then t[k]={table.unpack(v)} else t[k]=v end end
    if density=="touch" then
        t.density="touch"; t.fontSize=15; t.rowHeight=44; t.controlHeight=44
        t.titleHeight=44; t.scrollbar=24; t.gap=8; t.padding=10
    end
    for k,v in pairs(overrides or {}) do if type(v)=="table" then t[k]={table.unpack(v)} else t[k]=v end end
    return t
end
return M
