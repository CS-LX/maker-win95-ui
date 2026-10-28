-- SPDX-License-Identifier: MIT
-- Original geometric pixel icons. No Microsoft or upstream bitmap is distributed.
local D=require("win95.Draw")
local I={registry={}}
local palette={k={0,0,0,255},w={255,255,255,255},g={128,128,128,255},s={192,192,192,255},
    b={0,0,128,255},c={0,160,160,255},y={255,224,64,255},r={192,32,32,255},v={32,144,64,255}}
local function r(x,y,w,h,c) return {x,y,w,h,c} end
I.registry={
    close={r(4,4,2,2,'k'),r(6,6,2,2,'k'),r(8,8,2,2,'k'),r(10,10,2,2,'k'),r(10,4,2,2,'k'),r(8,6,2,2,'k'),r(6,8,2,2,'k'),r(4,10,2,2,'k')},
    minimize={r(3,11,9,2,'k')},maximize={r(2,3,12,11,'k'),r(3,6,10,7,'w')},
    restore={r(5,2,9,9,'k'),r(6,5,7,5,'w'),r(2,6,9,9,'k'),r(3,9,7,5,'w')},
    folder={r(1,4,6,2,'k'),r(1,6,14,8,'k'),r(2,5,4,2,'y'),r(2,7,12,6,'y'),r(3,8,10,1,'w')},
    file={r(3,1,10,14,'k'),r(4,2,8,12,'w'),r(6,5,5,1,'b'),r(6,8,5,1,'g'),r(6,10,4,1,'g')},
    save={r(2,1,12,14,'k'),r(3,2,10,12,'b'),r(5,2,6,4,'s'),r(8,2,2,3,'k'),r(5,9,6,5,'w')},
    computer={r(1,1,14,10,'k'),r(2,2,12,8,'s'),r(3,3,10,6,'b'),r(6,11,4,2,'g'),r(3,13,10,2,'k')},
    image={r(1,2,14,12,'k'),r(2,3,12,10,'w'),r(3,4,10,8,'c'),r(10,5,2,2,'y'),r(4,9,3,3,'v'),r(7,7,2,5,'v'),r(9,10,3,2,'v')},
    settings={r(2,3,12,2,'g'),r(2,7,12,2,'g'),r(2,11,12,2,'g'),r(4,2,3,4,'k'),r(9,6,3,4,'k'),r(6,10,3,4,'k')},
    info={r(3,1,10,14,'b'),r(2,3,12,10,'b'),r(7,3,2,2,'w'),r(7,7,2,5,'w')},
    warning={r(7,1,2,2,'k'),r(5,3,6,3,'k'),r(3,6,10,4,'k'),r(1,10,14,5,'k'),r(3,11,10,2,'y'),r(5,7,6,4,'y'),r(7,4,2,4,'y'),r(7,7,2,3,'k'),r(7,11,2,1,'k')},
    error={r(3,2,10,12,'r'),r(2,3,12,10,'r'),r(5,4,2,2,'w'),r(7,6,2,4,'w'),r(9,4,2,2,'w'),r(5,10,2,2,'w'),r(9,10,2,2,'w')},
    help={r(3,2,10,11,'b'),r(5,4,6,2,'w'),r(9,6,2,2,'w'),r(7,8,4,1,'w'),r(7,11,2,1,'w')},
    check={r(2,8,2,2,'k'),r(4,10,2,2,'k'),r(6,8,2,2,'k'),r(8,6,2,2,'k'),r(10,4,2,2,'k')},
    left={r(4,7,8,2,'k'),r(5,5,2,6,'k'),r(7,3,2,10,'k')},
    right={r(4,3,2,10,'k'),r(6,5,2,6,'k'),r(8,7,3,2,'k')},
    up={r(7,4,2,2,'k'),r(5,6,6,2,'k'),r(3,8,10,2,'k')},
    down={r(3,5,10,2,'k'),r(5,7,6,2,'k'),r(7,9,2,2,'k')},
    plus={r(3,7,10,2,'k'),r(7,3,2,10,'k')},minus={r(3,7,10,2,'k')},
    search={r(2,2,8,8,'k'),r(3,3,6,6,'c'),r(8,9,3,3,'k'),r(11,12,3,3,'k')},
    trash={r(4,5,8,10,'g'),r(3,3,10,2,'k'),r(6,1,4,2,'k'),r(6,6,1,7,'w'),r(9,6,1,7,'w')},
    start={r(2,2,5,5,'r'),r(9,2,5,5,'v'),r(2,9,5,5,'b'),r(9,9,5,5,'y')},
    assistant={r(3,2,10,10,'k'),r(4,3,8,8,'c'),r(5,5,2,2,'w'),r(9,5,2,2,'w'),r(6,9,4,1,'k'),r(5,12,2,3,'g'),r(9,12,2,3,'g')},
    busy={r(4,1,8,2,'k'),r(4,13,8,2,'k'),r(5,3,1,10,'g'),r(10,3,1,10,'g'),r(6,4,4,2,'y'),r(7,6,2,4,'y'),r(6,10,4,2,'y')},
    home={r(7,1,2,2,'k'),r(5,3,6,2,'k'),r(3,5,10,2,'k'),r(2,7,12,1,'k'),r(4,8,8,7,'y'),r(7,10,3,5,'b')},
    play={r(4,2,2,12,'v'),r(6,4,2,8,'v'),r(8,6,2,4,'v'),r(10,7,2,2,'v')},
    stop={r(3,3,10,10,'r')},
}
function I.register(name,definition)
    assert(type(name)=="string" and (type(definition)=="table" or type(definition)=="function"),"invalid icon")
    I.registry[name]=definition
end
function I.names() local a={};for k in pairs(I.registry) do a[#a+1]=k end;table.sort(a);return a end
function I.draw(n,name,x,y,size,disabled)
    local shape=I.registry[name] or I.registry.help
    if type(shape)=="function" then shape(n,x,y,size,disabled);return end
    local s=size/16
    for _,v in ipairs(shape) do
        local c=disabled and palette.g or (palette[v[5]] or v[5])
        D.rect(n,x+v[1]*s,y+v[2]*s,v[3]*s,v[4]*s,c)
    end
end
return I
