-- SPDX-License-Identifier: MIT
---@class Win95Tween
---@field value table<string,number>
---@field apply fun(value:table<string,number>)|nil
---@field new fun(value:table<string,number>,apply:function):Win95Tween
local T={};T.__index=T
function T.new(value,apply)
    return setmetatable({value=value or {},apply=apply,active=false,elapsed=0},T)
end
function T:cancel(reason)
    if not self.active then return end
    self.active=false;local callback=self.callback;self.callback=nil
    if callback then callback(false,reason or "cancelled") end
end
function T:to(target,duration,callback)
    self:cancel("redirected")
    self.from={};self.target={}
    for k,v in pairs(target) do
        assert(type(v)=="number","tween values must be numeric")
        self.from[k]=self.value[k] or 0;self.target[k]=v
    end
    self.elapsed=0;self.duration=math.max(0,duration or .2);self.callback=callback;self.active=true
    if self.duration==0 then self:update(0) end
    return self
end
function T:update(dt)
    if not self.active then return end
    self.elapsed=self.elapsed+math.max(0,dt)
    local p=self.duration==0 and 1 or math.min(1,self.elapsed/self.duration)
    local q=1-(1-p)^3
    for k,v in pairs(self.target) do self.value[k]=self.from[k]+(v-self.from[k])*q end
    if self.apply then self.apply(self.value) end
    if p==1 then self.active=false;local cb=self.callback;self.callback=nil;if cb then cb(true,"completed") end end
end
return T
