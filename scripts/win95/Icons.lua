-- SPDX-License-Identifier: MIT
-- Original two-size pixel artwork, decoded lazily by name. No runtime image handles.
local D=require('win95.Draw')
local I={registry={}}
for name in ('close minimize maximize restore folder file save computer image settings info warning error help check left right up down plus minus search trash start assistant busy home play stop'):gmatch('%S+') do
    I.registry[name]='win95.icondata.'..name
end
function I.register(name,definition)
    assert(type(name)=='string' and (type(definition)=='table' or type(definition)=='function'),'invalid icon')
    I.registry[name]=definition
end
function I.names()local a={};for k in pairs(I.registry)do a[#a+1]=k end;table.sort(a);return a end
function I.title(n,name,l,theme,disabled,offset)
    local x=math.floor(l.x+(l.w-10)/2)+(offset or 0);local y=math.floor(l.y+(l.h-8)/2)+(offset or 0)
    local ink=disabled and theme.disabled or theme.text
    if name=='close' then
        for i=0,6 do D.rect(n,x+i,y+i,2,1,ink);D.rect(n,x+6-i,y+i,2,1,ink) end
    elseif name=='minimize' then D.rect(n,x+1,y+6,6,2,ink)
    elseif name=='maximize' then
        D.rect(n,x,y,10,2,ink);D.rect(n,x,y+2,1,6,ink);D.rect(n,x+9,y+2,1,6,ink);D.rect(n,x,y+7,10,1,ink)
    elseif name=='restore' then
        D.edge(n,x+3,y,7,6,ink,ink);D.rect(n,x+3,y+1,7,1,ink)
        D.rect(n,x,y+3,7,6,theme.face);D.edge(n,x,y+3,7,6,ink,ink);D.rect(n,x,y+4,7,1,ink)
    end
end
function I.draw(n,name,x,y,size,disabled)
    local key=I.registry[name] and name or 'help';local shape=I.registry[key]
    if type(shape)=='string' then shape=require(shape);I.registry[key]=shape end
    if type(shape)=='function' then shape(n,x,y,size,disabled);return end
    if shape[16] then
        local native=size>=24 and 32 or 16;local scale=size/native
        nvgSave(n);nvgShapeAntiAlias(n,0)
        local function paint(offset,emboss)
            for _,group in ipairs(shape[native]) do
                local c=emboss or group.color
                if disabled and not emboss then local gray=math.floor(c[1]*.2126+c[2]*.7152+c[3]*.0722+.5);c={gray,gray,gray,128} end
                nvgBeginPath(n)
                for _,r in ipairs(group.runs) do
                    local xx=math.floor(x+r[1]*scale+.5)+offset;local yy=math.floor(y+r[2]*scale+.5)+offset
                    local ww=math.floor(x+(r[1]+r[3])*scale+.5)+offset-xx
                    local hh=math.floor(y+(r[2]+1)*scale+.5)+offset-yy
                    if ww>0 and hh>0 then nvgRect(n,xx,yy,ww,hh) end
                end
                nvgFillColor(n,nvgRGBA(c[1],c[2],c[3],c[4] or 255));nvgFill(n)
            end
        end
        paint(0)
        nvgRestore(n);return
    end
    -- Literal host rectangle registrations remain supported.
    for _,v in ipairs(shape) do D.rect(n,x+v[1]*size/16,y+v[2]*size/16,v[3]*size/16,v[4]*size/16,disabled and {134,138,142,255} or v[5]) end
end
return I
