// Node and npm packages are development tools only. No browser runtime in the library.
const fs=require('fs'),path=require('path'),http=require('http');
const root=path.resolve(__dirname,'../..'),work=path.join(root,'.tmp/reference');
const esbuild=require(path.join(work,'node_modules/esbuild'));
const playwright=require(process.env.PLAYWRIGHT_PACKAGE||'playwright');
const upstream=process.argv.includes('--upstream-icons'),suffix=upstream?'-upstream':'';
(async()=>{
 const core=path.join(work,'node_modules/@react95/core/esm');
 const css=fs.readdirSync(core,{recursive:true}).filter(p=>p.endsWith('.vanilla.css')&&!p.startsWith('themes'));
 const imports=css.map(p=>'import '+JSON.stringify(path.join(core,p).replaceAll('\\','/'))+';').join('\n');
 await esbuild.build({stdin:{contents:imports+'\nimport '+JSON.stringify(path.join(__dirname,'fixture.jsx').replaceAll('\\','/'))+';',resolveDir:root,sourcefile:'fixture.js'},bundle:true,external:['/assets/*'],outfile:path.join(work,'site/fixture.js'),nodePaths:[path.join(work,'node_modules')],loader:{'.ttf':'file','.otf':'file','.woff':'file','.woff2':'file','.eot':'file','.svg':'file'},assetNames:'assets/[name]-[hash]',logLevel:'warning'});
 const server=http.createServer((req,res)=>{
  const url=decodeURIComponent(req.url.split('?')[0]);
  if(url==='/'){res.setHeader('Content-Type','text/html');res.end('<!doctype html><html class="r95_win95"><head><meta charset="utf-8"><link rel="stylesheet" href="/fixture.css"></head><body><div id="root"></div><script src="/fixture.js"></script></body></html>');return}
  let file=url.startsWith('/assets/win95/')?path.join(root,url):path.join(work,'site',url);
  if(url.startsWith('/upstream-icons/'))file=path.join(work,'node_modules/@react95/icons/png',path.basename(url));
  if(!file.startsWith(root)||!fs.existsSync(file)){res.writeHead(404);res.end();return}
  res.setHeader('Content-Type',({'.js':'text/javascript','.css':'text/css','.ttf':'font/ttf','.otf':'font/otf','.png':'image/png','.svg':'image/svg+xml'})[path.extname(file)]||'application/octet-stream');res.end(fs.readFileSync(file));
 });await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const browser=await playwright.chromium.launch({channel:'msedge',headless:true});
 try{
  const page=await browser.newPage({viewport:{width:960,height:640},deviceScaleFactor:1});
  const errors=[];page.on('pageerror',e=>errors.push(String(e)));
  await page.goto('http://127.0.0.1:'+server.address().port+'/'+(upstream?'?upstream-icons':''),{waitUntil:'networkidle'});
  await page.waitForFunction(()=>window.fixtureReady);await page.evaluate(()=>document.fonts.ready);await page.locator('#focusButton').focus();
  const theme=await page.evaluate(()=>({font:getComputedStyle(document.body).fontFamily,material:getComputedStyle(document.documentElement).getPropertyValue('--r95-color-material'),windows:[...document.querySelectorAll('[data-window]')].map(e=>({title:e.dataset.window,x:e.offsetLeft,y:e.offsetTop,w:e.offsetWidth,h:e.offsetHeight}))}));
  if(errors.length)throw Error(errors.join('\n'));
  if(!theme.material)throw Error('React95 theme not loaded');
  if(theme.windows[0]?.w!==440||theme.windows[0]?.x!==24||theme.windows[2]?.h!==226)throw Error('Reference window geometry mismatch: '+JSON.stringify(theme));
  const out=path.join(root,'.tmp/comparison');fs.mkdirSync(out,{recursive:true});
  if(await page.locator('img').evaluateAll(imgs=>imgs.some(i=>!i.complete||!i.naturalWidth)))throw Error('Missing comparison icons');
  await page.screenshot({path:path.join(out,'react95'+suffix+'.png')});
  fs.writeFileSync(path.join(out,'reference'+suffix+'.json'),JSON.stringify({core:'10.0.6',icons:upstream?'@react95/icons 2.8.0 (local study only)':'Original Maker icons on both sides',browser:browser.version(),viewport:[960,640],...theme},null,2));
  console.log('REFERENCE PASS',JSON.stringify(theme));
 }finally{await browser.close();await new Promise(r=>server.close(r))}
})().catch(e=>{console.error(e);process.exit(1)});
