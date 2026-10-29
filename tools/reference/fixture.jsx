// Actual @react95/core 10.0.6 components; upstream fonts stay in ignored dev deps.
import React from 'react';
import {createRoot} from 'react-dom/client';
import {Frame,TitleBar,Button,Input,Checkbox} from '@react95/core';
import '@react95/core/GlobalStyle';
import '@react95/core/themes/win95.css';
import './fixture.css';
const h=React.createElement;
// Reference-only Microsoft artwork stays in ignored npm dependencies. The public
// comparison uses our original icons on both sides to isolate chrome and fonts.
const upstream={computer:['Computer_16x16_4','Computer_32x32_4'],folder:['Folder_16x16_4','Folder_32x32_4'],file:['FileText_16x16_4','FileText_32x32_4'],save:['Save_16x16_4','Save_16x16_4'],image:['Mspaint_16x16_4','Mspaint_32x32_4'],settings:['Settings_16x16_4','Settings_32x32_4'],search:['FileFind_16x16_4','FileFind_32x32_4'],trash:['RecycleEmpty_16x16_4','RecycleEmpty_32x32_4'],help:['User3_32x32_4','User3_32x32_4'],info:['User5_32x32_4','User5_32x32_4'],warning:['User2_32x32_4','User2_32x32_4'],error:['User4_32x32_4','User4_32x32_4']};
function iconSource(name,size){return location.search.includes('upstream-icons')?'/upstream-icons/'+upstream[name][size===32?1:0]+'.png':'/assets/win95/icons/'+name+'-'+size+'.png'}
function Icon({name,size=16,disabled=false}){return <img className={disabled?'disabledIcon':''} src={iconSource(name,size)} width={size} height={size}/>}
function At({x,y,w,h:height,children,...rest}){return <div style={{position:'absolute',left:x,top:y,width:w,height,display:'flex',alignItems:'center'}} {...rest}>{children}</div>}
function Window({title,icon,x,y,w,h:height,active=false,children}){
 return <Frame data-window={title} position="absolute" left={String(x)+'px'} top={String(y)+'px'} width={String(w)+'px'} height={String(height)+'px'} padding={String(2)+'px'} bgColor="$material" boxShadow="$out">
  <TitleBar title={title} active={active} icon={<svg width="16" height="16"><image href={iconSource(icon,16)} width="16" height="16"/></svg>}>
   <TitleBar.OptionsBox><TitleBar.Minimize/><TitleBar.Maximize/><TitleBar.Close/></TitleBar.OptionsBox>
  </TitleBar>
  <div style={{position:'absolute',left:2,top:22,right:2,bottom:2}}>{children}</div>
 </Frame>
}
function App(){
 const rows=[['file','Readme.txt','Text document','4 KB'],['image','Garden.png','Image','18 KB'],['save','Project.dat','Data file','12 KB'],['folder','Pictures','Folder','']];
 const names=['computer','folder','file','save','image','settings','search','trash','help','info','warning','error'];
 return <>
 <Window title="Display Properties / 显示属性" icon="settings" x={24} y={24} w={440} h={328} active>
  <At x={10} y={8} w={400} h={18}>Appearance    Settings    About</At>
  <div className="separator" style={{left:10,top:30,width:416}}/>
  <At x={12} y={42} w={390} h={18}>Window text: The quick brown fox 0123456789</At>
  <At x={12} y={66} w={390} h={18}>中文显示、编辑与换行：你好，世界！</At>
  <At x={12} y={94} w={270} h={23}><Input defaultValue="Desktop / 我的桌面" style={{width:'100%',height:23}}/></At>
  <At x={12} y={128} w={300} h={23}><Checkbox defaultChecked>Show desktop icons / 显示图标</Checkbox></At>
  <At x={12} y={156} w={300} h={23}><Checkbox disabled defaultChecked>Unavailable option</Checkbox></At>
  <Frame position="absolute" left={String(12)+'px'} top={String(193)+'px'} width={String(414)+'px'} height={String(35)+'px'} padding={String(2)+'px'} boxShadow="$in">Ready — native widgets, host-owned data.</Frame>
  {[['OK',168],['Cancel',256],['Apply',344]].map(([text,x])=><At key={text} x={x} y={260} w={80} h={24}><Button id={text==='OK'?'focusButton':undefined} disabled={text==='Apply'} style={{width:80,height:24,padding:0}}>{text}</Button></At>)}
 </Window>
 <Window title="Documents / 文档" icon="folder" x={496} y={24} w={440} h={328}>
  <At x={10} y={8} w={400} h={18}>File    Edit    View    Help</At><div className="separator" style={{left:10,top:30,width:416}}/>
  <Frame position="absolute" left={String(10)+'px'} top={String(40)+'px'} width={String(416)+'px'} height={String(206)+'px'} bgColor="$inputBackground" boxShadow="$input">
   {rows.map((r,i)=><React.Fragment key={r[1]}><At x={8} y={8+i*45} w={32} h={32}><Icon name={r[0]} size={32}/></At><At x={50} y={8+i*45} w={150} h={30}>{r[1]}</At><At x={208} y={8+i*45} w={130} h={30}>{r[2]}</At><At x={351} y={8+i*45} w={55} h={30}>{r[3]}</At></React.Fragment>)}
  </Frame>
  <At x={12} y={263} w={400} h={22}>4 objects                         No real filesystem access</At>
 </Window>
 <Window title="Icon catalog / 图标目录" icon="computer" x={24} y={380} w={912} h={226}>
  {names.map((name,i)=>{let x=14+i%6*149,y=14+Math.floor(i/6)*88;return <React.Fragment key={name}><At x={x} y={y+9} w={16} h={16}><Icon name={name}/></At><At x={x+26} y={y} w={32} h={32}><Icon name={name} size={32}/></At><At x={x+70} y={y+9} w={16} h={16}><Icon name={name} disabled/></At><At x={x} y={y+38} w={130} h={20}>{name+'  16 / 32'}</At></React.Fragment>})}
 </Window>
 </>
}
createRoot(document.getElementById('root')).render(<App/>);
document.fonts.ready.then(()=>{document.getElementById('focusButton')?.focus();window.fixtureReady=true});
