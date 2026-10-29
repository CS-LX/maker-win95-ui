"""Original, size-specific Win95-style pixel artwork. Pillow is development-only.

No pixels or paths are traced/copied from Windows or React95 assets. The 16px
silhouettes and 32px detail layers are independently rasterized on integer grids.
Runtime data are per-icon color runs, loaded only when that name is first drawn.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import json
ROOT=Path(__file__).resolve().parents[1]
P={'k':'#101010','w':'#ffffff','g':'#808080','s':'#c0c0c0','l':'#e4e4e4','d':'#404040',
   'b':'#000080','B':'#2058b0','c':'#008080','C':'#80d0d0','y':'#ffff80','Y':'#d8a840',
   'o':'#a06020','r':'#b02020','R':'#ff7070','v':'#208040','V':'#80c860','p':'#804080'}
NAMES='close minimize maximize restore folder file save computer image settings info warning error help check left right up down plus minus search trash start assistant busy home play stop'.split()
def draw(name,n):
    im=Image.new('RGBA',(n,n));d=ImageDraw.Draw(im);s=n/32
    def xy(v):return round(v*s)
    def rect(box,c):
        x,y,x2,y2=map(xy,box);d.rectangle((x,y,max(x,x2-1),max(y,y2-1)),fill=P.get(c,c))
    def poly(pts,c):d.polygon([(xy(x),xy(y)) for x,y in pts],fill=P.get(c,c))
    def line(pts,c,w=1):d.line([(xy(x),xy(y)) for x,y in pts],fill=P.get(c,c),width=max(1,round(w*s)))
    def ellipse(box,c):d.ellipse(tuple(map(xy,box)),fill=P.get(c,c))
    def panel(box,face='s'):
        x,y,x2,y2=box;rect(box,'k');rect((x+1,y+1,x2-1,y2-1),face)
        line([(x+1,y2-2),(x+1,y+1),(x2-2,y+1)],'w');line([(x+2,y2-2),(x2-2,y2-2),(x2-2,y+2)],'g')
    if name in ['close','minimize','maximize','restore','check','left','right','up','down','plus','minus']:
        # Glyph designs use a true 12px title-control cell, not enlarged pictograms.
        if name=='close':
            for i in range(6):rect((8+i*2,8+i*2,12+i*2,10+i*2),'k');rect((18-i*2,8+i*2,22-i*2,10+i*2),'k')
        elif name=='minimize':rect((6,22,24,26),'k')
        elif name in ['maximize','restore']:
            if name=='restore':rect((10,4,29,23),'k');rect((12,10,27,21),'w')
            rect((4,10 if name=='restore' else 6,24,28),'k');rect((6,16 if name=='restore' else 12,22,26),'w')
        elif name=='check':poly([(5,14),(11,20),(25,6),(25,12),(11,26),(5,20)],'k')
        elif name in ['plus','minus']:
            rect((6,14,26,18),'k')
            if name=='plus':rect((14,6,18,26),'k')
        else:
            pts={'left':[(9,16),(21,5),(21,27)],'right':[(23,16),(11,5),(11,27)],'up':[(16,9),(5,21),(27,21)],'down':[(16,23),(5,11),(27,11)]}[name];poly(pts,'k')
    elif name=='folder':
        poly([(3,6),(13,6),(16,10),(28,10),(30,13),(28,27),(2,27),(2,7)],'k')
        poly([(4,7),(12,7),(15,11),(27,11),(27,25),(4,25)],'Y')
        line([(4,8),(12,8),(15,12),(26,12)],'y')
        poly([(3,16),(10,13),(31,13),(27,28),(2,28)],'k')
        poly([(4,17),(10,14),(29,14),(26,26),(4,26)],'y')
        line([(4,18),(5,25),(25,25),(28,15)],'Y');line([(5,17),(11,15),(27,15)],'w')
        if n==32:line([(5,27),(26,27)],'o')
    elif name in ['file','image']:
        poly([(7,2),(22,2),(28,8),(28,29),(7,29),(5,27),(5,4)],'k')
        poly([(7,3),(21,3),(21,9),(27,9),(27,28),(7,28)],'w')
        rect((7,27,26,28),'g');poly([(22,3),(26,7),(22,7)],'s')
        if name=='file':
            for y in range(12,24,3):line([(10,y),(23-(y%2)*4,y)],'b' if y==12 else 'g')
            if n==32:line([(5,5),(5,26)],'l');rect((9,5,17,7),'b')
        else:
            panel((8,11,25,25),'c');ellipse((17,13,21,17),'y')
            poly([(9,23),(13,17),(16,20),(20,16),(23,23)],'V');poly([(13,18),(16,21),(9,23)],'v')
    elif name in ['computer','assistant']:
        poly([(3,4),(23,2),(29,6),(29,23),(24,26),(3,23)],'k')
        poly([(5,5),(22,4),(22,21),(5,21)],'s');poly([(23,4),(27,7),(27,22),(23,24)],'g')
        panel((5,6,23,22));rect((7,8,21,19),'k');rect((8,9,20,18),'b' if name=='computer' else 'c')
        line([(9,10),(19,10)],'B' if name=='computer' else 'C');rect((19,20,21,21),'V')
        if name=='assistant':rect((10,12,12,14),'w');rect((16,12,18,14),'w');line([(12,16),(16,16)],'w')
        rect((12,23,19,26),'k');rect((13,23,18,25),'g')
        poly([(7,26),(24,26),(28,29),(27,31),(3,31),(3,29)],'k');poly([(7,27),(23,27),(25,29),(5,29)],'s')
        if n==32:line([(8,28),(21,28)],'w');line([(25,8),(25,20)],'d')
    elif name=='save':
        poly([(4,2),(26,2),(29,5),(29,30),(3,30),(3,3)],'k');rect((4,3,28,29),'b')
        rect((7,3,23,14),'s');rect((18,4,22,12),'k');line([(8,4),(8,12),(16,12)],'w')
        panel((7,18,25,30),'w');rect((9,20,23,23),'B')
        if n==32:
            for y in [25,27]:line([(10,y),(21,y)],'g')
            rect((5,5,6,26),'B');rect((26,25,27,28),'s')
    elif name=='settings':
        # Perspective control board with three distinct recessed adjustment lanes.
        poly([(3,5),(25,3),(29,7),(29,27),(7,30),(3,27)],'k');poly([(4,6),(24,4),(27,7),(7,10)],'l')
        poly([(4,7),(26,7),(26,26),(7,28),(4,26)],'s');poly([(27,8),(28,8),(28,26),(27,27)],'g')
        for x,level in [(9,14),(16,20),(23,12)]:
            rect((x-1,11,x+1,25),'g');line([(x+1,11),(x+1,24)],'w');panel((x-3,level-2,x+3,level+3))
        if n==32:line([(6,10),(6,25)],'w')
    elif name in ['info','help','error']:
        ellipse((3,3,29,29),'k');ellipse((3,2,27,26),'b' if name!='error' else 'r')
        line([(7,5),(12,3),(20,3)],'B' if name!='error' else 'R',2)
        if name=='info':rect((14,7,18,11),'w');rect((12,13,18,22),'w');rect((11,22,21,24),'w')
        elif name=='help':
            poly([(10,8),(13,6),(21,6),(24,9),(24,14),(18,18),(18,20),(14,20),(14,16),(20,12),(20,10),(14,10),(14,12),(10,12)],'w');rect((14,22,18,25),'w')
        else:
            line([(10,9),(22,21)],'w',4);line([(22,9),(10,21)],'w',4)
    elif name=='warning':
        poly([(15,2),(18,2),(31,27),(29,30),(2,30),(0,27)],'k');poly([(16,4),(28,27),(3,27)],'y')
        line([(5,26),(16,6),(26,26)],'Y');rect((14,12,18,21),'k');rect((14,24,18,27),'k')
    elif name=='search':
        poly([(19,18),(24,19),(31,26),(31,30),(27,31),(19,23)],'k');line([(22,22),(28,28)],'o',4);line([(23,21),(29,27)],'Y')
        ellipse((1,1,24,24),'k');ellipse((2,2,22,22),'s');ellipse((4,4,20,20),'k');ellipse((5,5,19,19),'C')
        line([(7,12),(8,8),(12,7)],'w',2);line([(8,18),(14,19),(18,15)],'c')
    elif name=='trash':
        poly([(7,7),(26,7),(24,29),(10,31),(7,29),(5,10)],'k');poly([(7,10),(24,9),(22,28),(11,29)],'s')
        for x in [10,15,20]:line([(x,12),(x+1,26)],'g');line([(x+1,12),(x+2,26)],'w')
        poly([(5,7),(10,4),(25,4),(28,7),(25,10),(7,11),(4,9)],'k');poly([(6,7),(11,5),(24,5),(26,7),(23,8),(8,9)],'l')
        panel((13,2,20,6));line([(11,30),(22,28)],'g')
    elif name=='busy':
        panel((7,2,26,5),'o');panel((7,27,26,30),'o');line([(9,5),(10,12),(16,16),(10,22),(9,27)],'k');line([(24,5),(23,12),(18,16),(23,22),(24,27)],'k')
        poly([(11,6),(22,6),(21,11),(17,15),(12,11)],'C');poly([(17,18),(22,26),(11,26)],'y')
        line([(13,9),(20,9)],'y',2);line([(17,15),(17,22)],'Y');line([(11,6),(12,9)],'w')
    elif name=='home':
        poly([(4,16),(16,3),(30,14),(28,17),(26,16),(26,29),(7,30),(7,17)],'k');poly([(8,15),(16,8),(25,16),(25,28),(8,28)],'y')
        poly([(3,15),(15,2),(30,13),(28,16),(15,6),(5,17)],'r');line([(4,15),(15,4),(28,14)],'R')
        panel((13,19,19,30),'o');panel((20,17,24,23),'c');line([(8,17),(8,27)],'w')
    elif name=='start':
        # Original four-color application tiles, no Windows logo silhouette.
        for x,y,c in [(3,3,'r'),(17,3,'v'),(3,17,'B'),(17,17,'Y')]:
            panel((x,y,x+12,y+12),c);line([(x+3,y+3),(x+8,y+3)],'w');rect((x+3,y+6,x+6,y+9),'l')
    elif name=='play':
        poly([(7,3),(29,16),(7,30),(4,28),(4,4)],'k');poly([(7,5),(26,16),(7,27)],'v');line([(8,7),(23,16)],'V',2)
    elif name=='stop':panel((4,4,28,28),'r');line([(8,8),(23,8)],'R',2)
    return im
def runs(im):
    groups={}
    for y in range(im.height):
        x=0
        while x<im.width:
            color=im.getpixel((x,y));end=x+1
            while end<im.width and im.getpixel((end,y))==color:end+=1
            if color[3]:groups.setdefault(color,[]).append([x,y,end-x])
            x=end
    return [{'color':list(c),'runs':r} for c,r in groups.items()]
def lua(v):
    if isinstance(v,dict):return '{'+','.join(k+'='+lua(x) for k,x in v.items())+'}'
    if isinstance(v,list):return '{'+','.join(map(lua,v))+'}'
    return str(v)
def main():
    out=ROOT/'scripts/win95/icondata';out.mkdir(exist_ok=True)
    previews=ROOT/'assets/win95/icons';previews.mkdir(exist_ok=True)
    for name in NAMES:
        a,b=draw(name,16),draw(name,32)
        text='-- Original MIT artwork; generated by tools/icons.py.\nreturn {[16]='+lua(runs(a))+',[32]='+lua(runs(b))+'}\n'
        (out/(name+'.lua')).write_text(text,'utf-8')
        # PNG previews are also useful for host tooling/browser comparison; runtime uses runs.
        a.save(previews/(name+'-16.png'));b.save(previews/(name+'-32.png'))
    print('Original icons: 29 names, 16 and 32 pixel designs.')
if __name__=='__main__':main()
