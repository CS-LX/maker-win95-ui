-- SPDX-License-Identifier: MIT
-- Fixed 960x640 acceptance fixture, mirrored by tools/reference/fixture.jsx.
local Host=require('Host')
local M={}
function M.build(c)
    local function put(parent,kind,x,y,w,h,p)
        p=p or {};p.position='absolute';p.left=x;p.top=y;p.width=w;p.height=h
        local child=c[kind](c,p);parent:AddChild(child);return child
    end
    local main=c:Window{title='Display Properties / 显示属性',icon='settings',x=24,y=24,width=440,height=328,contentPadding=0,minimizable=true}
    local p=main.content
    put(p,'Label',10,8,400,18,{text='Appearance    Settings    About'})
    put(p,'Separator',10,30,416,2)
    put(p,'Label',12,42,390,18,{text='Window text: The quick brown fox 0123456789'})
    put(p,'Label',12,66,390,18,{text='中文显示、编辑与换行：你好，世界！'})
    put(p,'TextInput',12,94,270,23,{value='Desktop / 我的桌面'})
    put(p,'Checkbox',12,128,300,23,{text='Show desktop icons / 显示图标',value=true})
    put(p,'Checkbox',12,156,300,23,{text='Unavailable option',disabled=true,value=true})
    put(p,'Frame',12,193,414,35,{inset=true,children={c:Label{text='Ready — native widgets, host-owned data.'}}})
    local focus=put(p,'Button',168,260,80,24,{text='OK'})
    put(p,'Button',256,260,80,24,{text='Cancel'})
    put(p,'Button',344,260,80,24,{text='Apply',disabled=true})
    local files=c:Window{title='Documents / 文档',icon='folder',x=496,y=24,width=440,height=328,contentPadding=0,minimizable=true}
    put(files.content,'Label',10,8,400,18,{text='File    Edit    View    Help'})
    put(files.content,'Separator',10,30,416,2)
    local data={{'file','Readme.txt','Text document','4 KB'},{'image','Garden.png','Image','18 KB'},{'save','Project.dat','Data file','12 KB'},{'folder','Pictures','Folder',''}}
    local list=put(files.content,'Frame',10,40,416,206,{inset=true,backgroundColor=c.theme.paper})
    for i,item in ipairs(data)do
        local y=8+(i-1)*45
        put(list,'Icon',8,y,32,32,{name=item[1],size=32})
        put(list,'Label',50,y,150,30,{text=item[2]})
        put(list,'Label',208,y,130,30,{text=item[3]})
        put(list,'Label',351,y,55,30,{text=item[4]})
    end
    put(files.content,'Label',12,263,400,22,{text='4 objects                         No real filesystem access'})
    local icons=c:Window{title='Icon catalog / 图标目录',icon='computer',x=24,y=380,width=912,height=226,contentPadding=0,minimizable=true}
    local names={'computer','folder','file','save','image','settings','search','trash','help','info','warning','error'}
    for i,name in ipairs(names)do
        local x=14+((i-1)%6)*149;local y=14+math.floor((i-1)/6)*88
        put(icons.content,'Icon',x,y+9,16,16,{name=name,size=16})
        put(icons.content,'Icon',x+26,y,32,32,{name=name,size=32})
        put(icons.content,'Icon',x+70,y+9,16,16,{name=name,size=16,disabled=true})
        put(icons.content,'Label',x,y+38,130,20,{text=name..'  16 / 32'})
    end
    focus:Focus()
    return {context=c,window=main,focus=focus}
end
function Start()Host.start(M.build)end
function Stop()Host.stop()end
return M
