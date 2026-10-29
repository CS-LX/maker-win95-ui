-- SPDX-License-Identifier: MIT
-- Widget coordinates are engine base pixels. Never begin another NVG frame or apply DPR here.
local D={}
function D.rect(n,x,y,w,h,c)
    if w<=0 or h<=0 then return end
    nvgBeginPath(n); nvgRect(n,x,y,w,h); nvgFillColor(n,nvgRGBA(c[1],c[2],c[3],c[4] or 255)); nvgFill(n)
end
function D.edge(n,x,y,w,h,a,b)
    D.rect(n,x,y,w,1,a); D.rect(n,x,y,1,h,a)
    D.rect(n,x,y+h-1,w,1,b); D.rect(n,x+w-1,y,1,h,b)
end
function D.bevel(n,l,t,inset,fill)
    if fill then D.rect(n,l.x,l.y,l.w,l.h,fill) end
    D.edge(n,l.x,l.y,l.w,l.h,inset and t.shadow or t.white,inset and t.white or t.dark)
    D.edge(n,l.x+1,l.y+1,l.w-2,l.h-2,inset and t.dark or t.light,inset and t.light or t.shadow)
end
-- React95's frame shadow has a one-pixel outside shadow. Draw inside the owned
-- box, reserving that last pixel so clipping never drops the right/bottom edge.
function D.window(n,l,t)
    D.rect(n,l.x,l.y,l.w,l.h,t.face)
    D.edge(n,l.x,l.y,l.w,l.h,t.white,t.dark)
    D.edge(n,l.x+1,l.y+1,l.w-2,l.h-2,t.face,t.shadow)
end
function D.input(n,l,t)
    D.edge(n,l.x,l.y,l.w,l.h,t.shadow,t.white)
    D.edge(n,l.x+1,l.y+1,l.w-2,l.h-2,t.dark,t.face)
end
function D.checker(n,l,t)
    D.rect(n,l.x,l.y,l.w,l.h,t.white);nvgSave(n);nvgShapeAntiAlias(n,0);nvgBeginPath(n)
    for y=0,math.ceil(l.h)-1 do for x=y%2,math.ceil(l.w)-1,2 do nvgRect(n,l.x+x,l.y+y,1,1) end end
    nvgFillColor(n,nvgRGBA(t.face[1],t.face[2],t.face[3],255));nvgFill(n);nvgRestore(n)
end
function D.focus(n,l,t,pad)
    pad=pad or 4
    for x=l.x+pad,l.x+l.w-pad,2 do D.rect(n,x,l.y+pad,1,1,t.text);D.rect(n,x,l.y+l.h-pad-1,1,1,t.text) end
    for y=l.y+pad,l.y+l.h-pad,2 do D.rect(n,l.x+pad,y,1,1,t.text);D.rect(n,l.x+l.w-pad-1,y,1,1,t.text) end
end
function D.font(n,t,size)
    nvgFontFace(n,t.font);nvgFontSize(n,size or t.fontSize)
end
function D.text(n,text,x,y,t,color,align,size,bold)
    D.font(n,t,size);if bold then nvgFontFace(n,t.font..'-bold') end
    nvgTextAlign(n,align or (NVG_ALIGN_LEFT+NVG_ALIGN_MIDDLE))
    color=color or t.text;nvgFillColor(n,nvgRGBA(color[1],color[2],color[3],color[4] or 255))
    nvgText(n,x,y,tostring(text or ""))
end
function D.disabledText(n,text,x,y,t,align)
    D.text(n,text,x+1,y+1,t,t.white,align);D.text(n,text,x,y,t,t.disabled,align)
end
function D.clip(n,l,fn)
    nvgSave(n);nvgIntersectScissor(n,l.x,l.y,math.max(0,l.w),math.max(0,l.h));fn();nvgRestore(n)
end
function D.clamp(v,a,b) return math.max(a,math.min(math.max(a,b),v)) end
function D.inside(l,x,y) return x>=l.x and y>=l.y and x<l.x+l.w and y<l.y+l.h end
function D.sub(text,a,b)
    local s=utf8.offset(text,a or 1) or (#text+1)
    local e=b and ((utf8.offset(text,b+1) or (#text+1))-1) or #text
    return text:sub(s,e)
end
-- Character-boundary wrapping also works for CJK text without spaces. Positions are codepoints.
function D.lines(text,width,measure)
    local lines={};local line={text="",first=0,last=0,width=0,positions={0}};local index=0
    for _,cp in utf8.codes(text) do
        local c=utf8.char(cp)
        local w=measure(c)
        if cp==10 then
            line.last=index;lines[#lines+1]=line;index=index+1
            line={text="",first=index,last=index,width=0,positions={0}}
        else
            if line.width+w>width and #line.text>0 then
                line.last=index;lines[#lines+1]=line
                line={text="",first=index,last=index,width=0,positions={0}}
            end
            line.text=line.text..c;line.width=line.width+w;index=index+1
            line.last=index;line.positions[#line.positions+1]=line.width
        end
    end
    lines[#lines+1]=line;return lines
end
return D
