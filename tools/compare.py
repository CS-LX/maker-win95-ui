"""Compare real 960x640 captures without resizing/retouching. Requires Pillow."""
from pathlib import Path
import argparse,json,hashlib
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--upstream-icons',action='store_true',help='Local-only visual study; excluded from public archive')
a=p.parse_args();suffix='-upstream' if a.upstream_icons else ''
ref=ROOT/'.tmp/comparison'/('react95'+suffix+'.png')
native=ROOT/'.tmp/capture/visual-controls-default-960x640-compact-1.png'
images=[Image.open(f).convert('RGB') for f in (ref,native)]
assert all(im.size==(960,640) for im in images),'capture both native and browser at 960x640, scale/DPR 1'
samples={'desktop':((5,5),(0,128,128)),'panel':((300,220),(195,199,203)),
         'active_title':((300,30),(0,14,122)),'inactive_title':((800,30),(127,120,127)),
         'white_interior':((800,280),(255,255,255))}
checks={}
for name,(xy,color) in samples.items():
    values=[im.getpixel(xy) for im in images];assert all(v==color for v in values),(name,values,color)
    checks[name]={'position':xy,'rgb':color,'pass':True}
canvas=Image.new('RGB',(1920,690),'#17222c');d=ImageDraw.Draw(canvas)
d.text((12,9),'React95 core 10.0.6 | browser | 960 x 640',fill='white')
d.text((972,9),'Maker Win95 UI 1.1.0 | native UrhoX | 960 x 640',fill='white')
for i,im in enumerate(images):canvas.paste(im,(960*i,30))
note='Reference-only upstream icons (Microsoft ownership; not in public package).' if a.upstream_icons else 'Original licensed Maker icons on both sides; actual upstream font/chrome versus OFL native font/chrome.'
d.text((12,676),note,fill='white')
output=ROOT/'.tmp/comparison/upstream-vs-maker.png' if a.upstream_icons else ROOT/'docs/screenshots/comparison.png'
output.parent.mkdir(parents=True,exist_ok=True);canvas.save(output)
metadata=json.loads((ref.parent/('reference'+suffix+'.json')).read_text('utf-8'))
report={'version':'1.1.0','date':'2026-10-29','reference':metadata,'native':{'viewport':[960,640],'ui_scale':1,'actual_dpr':1},
        'pixel_samples':checks,'images_sha256':{f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in (ref,native)},
        'method':'Actual component renders; same strings, window rectangles and requested controls; source pixels pasted without rescaling.',
        'limits':['No claim of whole-image pixel equality','OFL W95font uses optical 13-unit size vs upstream CSS 12px; CJK uses Noto Sans SC','Native shadow stays inside widget bounds; browser shadow extends one pixel','Upstream icon comparison is generated locally and never copied into public assets/docs']}
report_path=ref.parent/'comparison-upstream.json' if a.upstream_icons else ROOT/'docs/visual-results.json'
report_path.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf-8')
print('COMPARISON PASS:',output,'; five palette samples, both 960x640; inspect glyphs/icons/borders visually')
