-- SPDX-License-Identifier: MIT
-- Original monitor-shaped assistant, generated from tools/assets.py. No Microsoft artwork.
local animations={}
for index,name in ipairs({"idle","greet","point","think"}) do
    local frames={}
    for frame=0,3 do local id=(index-1)*4+frame
        frames[#frames+1]={x=(id%8)*32,y=math.floor(id/8)*32,w=32,h=32,duration=name=="idle" and .5 or .18}
    end
    animations[name]={frames=frames,loop=name=="idle"}
end
return {name="Byte",sheet="win95/assistant/byte.png",width=64,height=64,animations=animations,idle="idle",license="MIT"}
