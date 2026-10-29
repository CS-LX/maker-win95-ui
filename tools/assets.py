"""Rebuild original pixel art (stdlib); --font also builds OFL Noto derivative (fontTools)."""
from pathlib import Path
import argparse, hashlib, io, json, struct, urllib.request, zlib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/win95'

def png(path,w,h,pixels):
    def chunk(kind,data):
        return struct.pack('!I',len(data))+kind+data+struct.pack('!I',zlib.crc32(kind+data)&0xffffffff)
    data=b''.join(b'\0'+bytes(pixels[y*w*4:(y+1)*w*4]) for y in range(h))
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',w,h,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(data,9))+chunk(b'IEND',b''))

def art():
    w,h=256,64;p=bytearray(w*h*4)
    colors={'k':(18,32,40,255),'s':(192,192,192,255),'w':(255,255,240,255),'c':(16,168,160,255),'b':(0,0,128,255),'y':(255,224,80,255)}
    def rect(frame,x,y,ww,hh,c):
        ox=(frame%8)*32;oy=(frame//8)*32
        for yy in range(y,y+hh):
            for xx in range(x,x+ww):
                i=((oy+yy)*w+ox+xx)*4;p[i:i+4]=bytes(colors[c])
    for frame in range(16):
        action=frame//4;phase=frame%4;bob=1 if phase==2 else 0
        rect(frame,7,25,18,2,'k');rect(frame,10,24,4,3,'s');rect(frame,20,24,4,3,'s')
        rect(frame,8,5+bob,18,18,'k');rect(frame,9,6+bob,16,16,'s')
        rect(frame,10,7+bob,14,12,'c');rect(frame,10,20+bob,14,1,'w')
        blink=(action==0 and phase==3);eyeH=1 if blink else 3
        look=1 if action==2 else 0
        rect(frame,12+look,11+bob,3,eyeH,'w');rect(frame,20+look,11+bob,2,eyeH,'w')
        rect(frame,13+look,12+bob,1,1,'k');rect(frame,20+look,12+bob,1,1,'k')
        rect(frame,15,16+bob,5,1,'k')
        rect(frame,5,16,3,2,'k');rect(frame,26,16,3,2,'k')
        if action==1:
            rect(frame,27,9-(phase%2)*3,2,8,'k');rect(frame,26,7-(phase%2)*3,4,3,'y')
        elif action==2:
            rect(frame,26,14,5,2,'k');rect(frame,29,12,2,2,'y')
        elif action==3:
            rect(frame,25,17,2,5,'k');rect(frame,22,18,5,2,'y')
            rect(frame,4+(phase%3)*3,2,2,2,'w')
    png(OUT/'assistant/byte.png',w,h,p)
    for name,shift in [('garden',0),('night',1)]:
        w,h=384,240;p=bytearray(w*h*4)
        for y in range(h):
            for x in range(w):
                color=(32,48,104,255) if shift else (80,160,192,255)
                if (x-290)**2+(y-55)**2<25**2:color=(255,232,144,255)
                hill=130+int(18*((x//24)%5)/4)
                if y>hill:color=(40,104,80,255) if shift else (64,136,72,255)
                if y>190 and (x//16+y//16)%2==0:color=(48,116,64,255)
                if 110<x<206 and 105<y<190:color=(224,208,160,255)
                if 100<x<216 and 90<y<107:color=(152,64,48,255)
                if 147<x<171 and 146<y<190:color=(64,72,88,255)
                if ((120<x<140) or (177<x<197)) and 120<y<142:color=(255,232,144,255)
                i=(y*w+x)*4;p[i:i+4]=bytes(color)
        png(OUT/('images/'+name+'.png'),w,h,p)

def font(bold_only=False):
    from fontTools.ttLib import TTFont
    from fontTools.varLib.instancer import instantiateVariableFont
    from fontTools import subset
    commit='9862abc066c9b83bf84c3e8ed1fc2d8d48f9bbf0'
    base=f'https://raw.githubusercontent.com/google/fonts/{commit}/ofl/notosanssc/'
    data=urllib.request.urlopen(base+'NotoSansSC%5Bwght%5D.ttf',timeout=90).read()
    source_hash=hashlib.sha256(data).hexdigest()
    assert source_hash=='a3041811a78c361b1de50f953c805e0244951c21c5bd412f7232ef0d899af0da','review changed font source before regenerating'
    face=TTFont(io.BytesIO(data));del data
    # Basic CJK, Latin, punctuation and symbols; omit rare extension planes and variable weights.
    chars=list(range(0x20,0x100))+list(range(0x2000,0x2070))+list(range(0x2190,0x2200))+list(range(0x2500,0x2600))+list(range(0x3000,0x3040))+list(range(0x4e00,0xa000))+list(range(0xff00,0xfff0))
    opts=subset.Options();opts.recalc_timestamp=False;opts.name_IDs=['*'];opts.name_legacy=True;opts.name_languages=['*']
    sub=subset.Subsetter(options=opts);sub.populate(unicodes=chars);sub.subset(face)
    weight=700 if bold_only else 400
    face=instantiateVariableFont(face,{'wght':weight},inplace=True)
    for record in face['name'].names:
        if record.nameID in (1,4,6,16):
            text='Maker Classic Sans' if record.nameID!=6 else ('MakerClassicSans-Bold' if bold_only else 'MakerClassicSans-Regular')
            record.string=text.encode(record.getEncoding())
        elif record.nameID in (2,17):record.string=('Bold' if bold_only else 'Regular').encode(record.getEncoding())
    dest=OUT/'fonts';dest.mkdir(exist_ok=True)
    filename='MakerClassicSans-Bold.ttf' if bold_only else 'MakerClassicSans.ttf'
    face.save(dest/filename);face.close()
    notice=urllib.request.urlopen(base+'OFL.txt',timeout=20).read().decode('utf-8')
    (dest/'OFL.txt').write_text('\n'.join(line.rstrip() for line in notice.splitlines())+'\n','utf-8')
    (dest/'source.json').write_text(json.dumps({'repository':'google/fonts','commit':commit,'path':'ofl/notosanssc/NotoSansSC[wght].ttf','source_sha256':source_hash,'derivative':'Maker Classic Sans; weights 400 and 700; Unicode ranges in tools/assets.py','license':'OFL-1.1'},indent=2)+'\n','utf-8')
    print('font',filename,(dest/filename).stat().st_size,'bytes',source_hash)

def classic_font():
    """Author-distributed OFL originals, not Microsoft's converted font files."""
    import zipfile
    url='https://madebyarne.github.io/w95font/assets/files/w95font.zip'
    data=urllib.request.urlopen(url,timeout=30).read()
    digest=hashlib.sha256(data).hexdigest()
    assert digest=='8659859534c3e1d9b031a295d5ae37a4d944cb7693cd68d8ddc5565a604c831d','upstream font archive changed; review before replacing'
    dest=OUT/'fonts';dest.mkdir(exist_ok=True)
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        for name in ('W95font.otf','W95font-Bold.otf'):
            (dest/name).write_bytes(z.read('w95font/'+name))
        for source,target in [('OFL.txt','W95font-OFL.txt'),('readme.txt','W95font-README.txt')]:
            text=z.read('w95font/'+source).decode('utf-8').replace('\r\r\n','\n').replace('\r\n','\n')
            (dest/target).write_text('\n'.join(line.rstrip() for line in text.splitlines())+'\n','utf-8')
    meta={'source':url,'archive_sha256':digest,'author':'Alle Sava (per included author README and font copyright metadata)',
          'license':'OFL-1.1','modified':False,'files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [dest/'W95font.otf',dest/'W95font-Bold.otf']}}
    (dest/'W95font-source.json').write_text(json.dumps(meta,indent=2)+'\n','utf-8')
    print('Classic regular/bold installed:',digest)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--font',action='store_true');p.add_argument('--cjk-bold',action='store_true');p.add_argument('--classic-font',action='store_true');a=p.parse_args();art()
    if a.font:font()
    if a.cjk_bold:font(True)
    if a.classic_font:classic_font()
    print('Original Byte sprite and two original sample images rebuilt.')
