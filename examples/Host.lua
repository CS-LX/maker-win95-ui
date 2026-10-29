-- SPDX-License-Identifier: MIT
-- Example host, not library code. The HOST owns UI.Init/SetRoot/Shutdown and update subscriptions.
local UI=require("urhox-libs/UI")
local Win=require("win95")
local H={}
function H.start(build)
    local options=WIN95_TEST_OPTIONS or {}
    UI.Init{
        theme="default-dark",
        fonts=Win.Fonts.options(),
        scale=options.scale and function()return options.scale end or UI.Scale.DEFAULT,
    }
    Win.Fonts.attach(UI)
    local root=UI.Panel{width="100%",height="100%",borderRadius=0,backgroundColor={0,128,128,255}}
    UI.SetRoot(root);UI.Layout()
    input.mouseVisible=true;input.mouseMode=MM_FREE
    local ctx=Win.new(root,{density=options.density or "compact"})
    UI.Layout();ctx:Update(0)
    H.root=root;H.ctx=ctx;H.demo=build(ctx);WIN95_DEMO=H.demo
    print("[Win95] Example ready; "..Win.version.."; "..ctx.theme.density.."; logical "..UI.GetWidth().."x"..UI.GetHeight())
    return H.demo
end
function H.stop()
    if H.ctx then H.ctx:Destroy();H.ctx=nil end
    UI.Shutdown();H.root=nil;H.demo=nil;WIN95_DEMO=nil
end
return H
