"""Native UrhoX checks and reproducible packaging. Python standard library only."""
from pathlib import Path
import argparse
import json
import os
import subprocess
import sys
import time
import zipfile
import hashlib
import re

ROOT = Path(__file__).resolve().parents[1]

def lua(s):
    s = str(s).replace('\\', '/')
    assert ']===]' not in s
    return '[===[' + s + ']===]'

def runtime_path(args):
    config = ROOT / '.local.json'
    configured = json.loads(config.read_text('utf-8')).get('runtime') if config.exists() else None
    value = args.runtime or os.environ.get('URHOX_RUNTIME') or configured
    if not value:
        raise SystemExit('Pass --runtime <installed UrhoXRuntime executable> or set URHOX_RUNTIME.')
    return Path(value).resolve(strict=True)

def native(args):
    runtime = runtime_path(args)
    source = Path(args.project).resolve() if args.project else ROOT
    out = ROOT / '.tmp' / args.command
    out.mkdir(parents=True, exist_ok=True)
    label = f'{args.example}-{args.tab}-{args.state}-{args.width}x{args.height}-{args.density}-{args.scale}'
    if args.project:
        label='clean-'+label
    entry = out / (label + '.lua')
    prefix = ''.join('cache:AddResourceDir(' + lua(source / name) + ')\n' for name in ('scripts', 'assets', 'examples', 'tests'))
    prefix += f'WIN95_TEST_OPTIONS={{density={lua(args.density)},scale={args.scale},tab={lua(args.tab)},state={lua(args.state)},width={args.width},height={args.height},screenshot={lua(out / (label + ".png"))},frames={args.frames}}}\n'
    if args.command == 'probe':
        body = '''
function Start()
 local ok,err=pcall(function()
  local UI=require('urhox-libs/UI');UI.Init{theme='default-dark',fonts=require('win95').Fonts.options(),scale=function() return 1 end}
  require('win95').Fonts.attach(UI);local root=UI.Panel{width='100%',height='100%'};UI.SetRoot(root)
  local Win=require('win95');local c=Win.new(root)
  c:Add(c:Button{text='Native Win95 / 原生',width=230})
  c:Add(c:TextInput{value='中文输入',width=240})
  UI.Layout()
  for _,key in ipairs({'GetNVGContext','GetFocus','SetFocus','FindWidgetAt','GetScale','HandlePointerCancel','GetPressedWidgetForPointer'}) do assert(type(UI[key])=='function',key) end
  assert(nvgCreateVideo and nvgDeleteVideo,'live texture bridge')
  assert(UI.MeasureTextWidth('中文',13,'sans')>20,'Chinese glyphs missing')
  print('[Win95] PROBE PASS '.._VERSION..' DPR '..graphics:GetDPR()..' font '..tostring(UI.MeasureTextWidth('中文',13,'sans')))
  c:Destroy();UI.Shutdown()
 end)
 if not ok then print('[Win95] FAIL '..tostring(err)) end
 engine:Exit()
end
'''
    elif args.command == 'syntax':
        files = sorted(source.rglob('*.lua'))
        files = [p for p in files if not any(x.startswith('.') for x in p.relative_to(source).parts)]
        body = 'function Start()\n local ok,err=pcall(function()\n'
        for file in files:
            body += 'assert(loadfile(' + lua(file) + '))\n'
        body += f"print('[Win95] SYNTAX PASS {len(files)} files')\nend)\nif not ok then print('[Win95] FAIL '..tostring(err)) end\nengine:Exit()\nend\n"
    elif args.command == 'test':
        body = "require('native')\n"
    else:
        body = 'local loaded,loadError=pcall(function() require(' + lua(args.example) + ') end)\nif not loaded then function Start() print("[Win95] FAIL "..tostring(loadError));engine:Exit() end end\n'
        if args.command == 'capture':
            body += '''
local originalStart=Start
function Start()
 local ok,err=xpcall(originalStart,debug.traceback)
 if not ok then print('[Win95] FAIL '..err);engine:Exit();return end
 assert(graphics:GetWidth()==WIN95_TEST_OPTIONS.width and graphics:GetHeight()==WIN95_TEST_OPTIONS.height,'requested native framebuffer size not applied')
 if WIN95_DEMO.tabs then WIN95_DEMO.tabs:SetValue(WIN95_TEST_OPTIONS.tab) end
 local frames=0;local samples={};local firstPixel
 local function livePixel(image)
  local l=WIN95_DEMO.viewer:GetAbsoluteLayoutForHitTest();local scale=require('urhox-libs/UI').GetScale()
  local color=image:GetPixel(math.floor((l.x+l.w/2)*scale),math.floor((l.y+l.h/2)*scale))
  return {color.r,color.g,color.b}
 end
 SubscribeToEvent('Update',function(_,data) if frames>10 then samples[#samples+1]=data:GetFloat('TimeStep')*1000 end end)
 SubscribeToEvent('EndFrame',function()
  frames=frames+1
  if frames==15 then require('capture_state')(WIN95_DEMO,WIN95_TEST_OPTIONS.state) end
  if frames==30 and WIN95_TEST_OPTIONS.state=='live' then local probe=Image:new();assert(graphics:TakeScreenShot(probe));firstPixel=livePixel(probe) end
  if frames==WIN95_TEST_OPTIONS.frames then
   local image=Image:new()
   assert(graphics:TakeScreenShot(image),'GPU readback failed')
   if WIN95_TEST_OPTIONS.state=='live' then
    assert(firstPixel,'live capture requires more than 30 frames')
    local last=livePixel(image);local delta=0;for i=1,3 do delta=delta+math.abs(last[i]-firstPixel[i]) end
    assert(delta>.005 and last[1]+last[2]+last[3]<2.9,'live texture did not update or became white')
    print(string.format('[Win95] LIVE PIXELS PASS delta=%.4f',delta))
   end
   assert(image:SavePNG(WIN95_TEST_OPTIONS.screenshot),'PNG save failed')
   local sum=0;for _,v in ipairs(samples) do sum=sum+v end;table.sort(samples)
   print(string.format('[Win95] metric frames=%d mean_ms=%.3f p95_ms=%.3f',#samples,sum/math.max(1,#samples),samples[math.max(1,math.ceil(#samples*.95))] or 0))
   print('[Win95] CAPTURE PASS '..WIN95_TEST_OPTIONS.screenshot)
   engine:Exit()
  end
 end)
end
'''
    entry.write_text(prefix + body, 'utf-8')
    command = [str(runtime), entry.as_posix(), '-w', '-width='+str(args.width), '-height='+str(args.height), '-tool_mode', '-nosound', '-nothreads']
    started = time.perf_counter()
    try:
        result = subprocess.run(command, cwd=runtime.parent, capture_output=True,
                                timeout=args.timeout, creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        output = (result.stdout + result.stderr).decode('utf-8', 'replace')
    except subprocess.TimeoutExpired as e:
        output = ((e.stdout or b'') + (e.stderr or b'')).decode('utf-8', 'replace')
        (out / (label + '.log')).write_text(output, 'utf-8')
        raise SystemExit('Runtime timed out; log: ' + str(out / (label + '.log')))
    finally:
        entry.unlink(missing_ok=True)
    (out / (label + '.log')).write_text(output, 'utf-8')
    for line in output.splitlines():
        if '[Win95]' in line or 'ERROR' in line or 'Error:' in line:
            print(line)
    print(f'Elapsed {time.perf_counter()-started:.3f}s; log {out / (label + ".log")}')
    known_baseline = ('Could not find resource Cube/Day/DaySpecularHDR.dds', 'Can not load themis_x64.dll.')
    errors = [line for line in output.splitlines() if 'ERROR:' in line and not any(message in line for message in known_baseline)]
    failed = result.returncode != 0 or '[Win95] FAIL' in output or errors or ('[Win95]' not in output and args.command != 'preview')
    if args.command not in ('preview',) and 'PASS' not in output:
        failed = True
    if failed:
        print(output[-6000:]);raise SystemExit(1)

def package(args):
    out=ROOT/'dist';out.mkdir(exist_ok=True)
    target=out/'maker-win95-ui-1.1.0.zip'
    files=[]
    for base in ('scripts/win95','assets/win95','examples','docs','tests','tools'):
        files += [p for p in (ROOT/base).rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    files += [ROOT/name for name in ('README.md','LICENSE','THIRD_PARTY.md')]
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for p in sorted(files):
            info=zipfile.ZipInfo(p.relative_to(ROOT).as_posix(),date_time=(2026,10,29,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED
            z.writestr(info,p.read_bytes())
        manifest=''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.relative_to(ROOT).as_posix()+'\n' for p in sorted(files))
        info=zipfile.ZipInfo('MANIFEST.sha256',date_time=(2026,10,29,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED
        z.writestr(info,manifest)
    print(target, target.stat().st_size, 'bytes; sha256', hashlib.sha256(target.read_bytes()).hexdigest())

def audit(args):
    source=Path(args.project).resolve() if args.project else ROOT
    files=list((source/'scripts/win95').rglob('*.lua'))
    assert len(files)==45, 'incomplete library scripts'
    icons=list((source/'scripts/win95/icondata').glob('*.lua'))
    assert len(icons)==29, 'incomplete icon data'
    for icon in icons:
        for size in (16,32):
            assert (source/f'assets/win95/icons/{icon.stem}-{size}.png').is_file(), 'missing icon preview'
    for p in files:
        text=p.read_text('utf-8')
        assert not re.search(r'[A-Za-z]:[\\/]|MemesLiminal|frontend\.|CameraLook',text), 'host dependency: '+str(p)
        assert not re.search(r'\bUI\.(Init|SetRoot|Shutdown)\s*\(',text), 'library must not own global UI: '+str(p)
    for name in ('README.md','LICENSE','THIRD_PARTY.md','examples/Host.lua','examples/gallery.lua','examples/desktop.lua','examples/minimal.lua','assets/win95/fonts/OFL.txt','assets/win95/fonts/W95font.otf','assets/win95/fonts/W95font-Bold.otf','assets/win95/fonts/W95font-OFL.txt','assets/win95/fonts/W95font-README.txt','assets/win95/fonts/MakerClassicSans-Bold.ttf','assets/win95/fonts/MakerClassicSans.ttf','assets/win95/assistant/byte.png','assets/win95/images/garden.png','assets/win95/images/night.png'):
        assert (source/name).is_file(), 'missing '+name
    for p in list((source/'docs').rglob('*.md'))+[source/'README.md',source/'THIRD_PARTY.md']:
        for href in re.findall(r'\]\(([^)]+)\)',p.read_text('utf-8')):
            if '://' not in href and not href.startswith('#'):
                assert (p.parent/href.split('#')[0]).exists(), f'broken documentation link {p}: {href}'
    if (source/'MANIFEST.sha256').exists():
        for line in (source/'MANIFEST.sha256').read_text('utf-8').splitlines():
            digest,name=line.split('  ',1);assert hashlib.sha256((source/name).read_bytes()).hexdigest()==digest, 'manifest mismatch '+name
    archive=ROOT/'dist/maker-win95-ui-1.1.0.zip'
    if archive.exists() and source==ROOT:
        with zipfile.ZipFile(archive) as z:
            assert z.testzip() is None
            names=z.namelist();assert len(names)==len(set(names))
            for name in names:
                assert not any(part in ('.git','.tmp','.local.json','node_modules','engine-docs','urhox-libs','.maker-mcp') for part in Path(name).parts), 'non-release content '+name
                assert not name.lower().endswith(('.exe','.dll','.pak')), 'engine binary '+name
    print('[Win95] AUDIT PASS: installation files, host independence, documentation links, manifest/archive boundaries')

def report(args):
    import shutil
    shots={
        'desktop':'desktop-controls-assistant-1100x720-compact-1',
        'data':'gallery-data-last-row-1100x720-compact-1',
        'icons':'gallery-icons-default-1100x720-compact-1',
        'portrait':'gallery-forms-default-390x844-touch-1',
        'landscape':'gallery-windows-modal-844x390-touch-1',
        'scale2':'gallery-forms-default-1100x720-compact-2.0',
        'live-texture':'minimal-controls-live-1100x720-compact-1',
        'menu':'gallery-windows-submenu-390x844-touch-1',
    }
    output=ROOT/'docs/screenshots';output.mkdir(parents=True,exist_ok=True)
    data={'version':'1.1.0','date':'2026-10-29','platform':'Windows native; simulated touch and UI scale; actual DPR 1',
          'runtime':json.loads((runtime_path(args).parent/'build.json').read_text('utf-8'))['commit'],'suites':[],'captures':[],
          'unverified':['physical Android/iOS','IME composition/candidate UI','mobile keyboard','Web export','hardware DPR > 1','screen reader']}
    for width,height,density,scale in [(1100,720,'compact','1'),(390,844,'touch','1'),(844,390,'touch','1'),(1100,720,'compact','2.0')]:
        label=f'gallery-controls-default-{width}x{height}-{density}-{scale}'
        log=(ROOT/'.tmp/test'/(label+'.log')).read_text('utf-8')
        assert 'TEST PASS checks=33 failures=0' in log,label
        data['suites'].append({'size':[width,height],'density':density,'ui_scale':float(scale),'checks':33,'failures':0,
            'metrics':re.findall(r'\[Win95\] metric (.+)',log)})
    for name,label in shots.items():
        source=ROOT/'.tmp/capture'/label
        log=Path(str(source)+'.log').read_text('utf-8');assert 'CAPTURE PASS' in log,label
        shutil.copyfile(Path(str(source)+'.png'),output/(name+'.png'))
        data['captures'].append({'file':'screenshots/'+name+'.png','configuration':label,'metrics':re.findall(r'\[Win95\] metric (.+)',log)})
    clean=list((ROOT/'.tmp/test').glob('clean-*.log'))
    data['clean_install']={'native_suite_pass':any('TEST PASS checks=33 failures=0' in p.read_text('utf-8') for p in clean),
        'examples':sorted({p.name.split('-')[1] for p in (ROOT/'.tmp/capture').glob('clean-*.log') if 'CAPTURE PASS' in p.read_text('utf-8')})}
    (ROOT/'docs/test-results.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n','utf-8')
    print('[Win95] REPORT written: compact metrics and 8 selected screenshots')

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('command',choices=['probe','syntax','test','capture','preview','package','audit','report'])
    p.add_argument('--runtime');p.add_argument('--project',help='Clean extracted package root')
    p.add_argument('--example',default='gallery',choices=['gallery','desktop','minimal','visual'])
    p.add_argument('--width',type=int,default=1200);p.add_argument('--height',type=int,default=800)
    p.add_argument('--scale',type=float,default=1);p.add_argument('--density',default='compact',choices=['compact','touch'])
    p.add_argument('--tab',default='controls',choices=['controls','forms','data','icons','media','windows'])
    p.add_argument('--state',default='default',choices=['default','assistant','modal','submenu','last-row','live'])
    p.add_argument('--frames',type=int,default=90);p.add_argument('--timeout',type=int,default=60)
    a=p.parse_args()
    if a.command=='package':package(a)
    elif a.command=='audit':audit(a)
    elif a.command=='report':report(a)
    else:native(a)
if __name__=='__main__':main()
