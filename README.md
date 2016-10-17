# Resty Source-engine Query

is a Library to query Source-Engine game servers for [OpenResty][1].

Inspired by [xPaw/PHP-Source-Query][2].

Developing is ongoing.

```lua
local q = require 'sourcequery'
local j = require 'cjson'
--[[
    local s = q:new(
        host,       --ip address, required
        port,       --udp port, default value is 27015
        timeout     --timeout, default value is 1000(ms)
    )
]]--
local server = q:new('207.173.67.34')
--[[
    local s = q:new('70.42.74.170', 27016)
    local s = q:new('216.131.79.171', 27015, 3000)
]]--
ngx.say(j.encode({server:ping()}))
ngx.say(j.encode({server:getinfo()}))
--[[
[true,0.25300002098083]
[{"Map":"the_raid_coopb4","GoldSource":false,"Port":27015,"Players":18,"Visibility":0,"VAC":1,"Environment":"w","Game":"Insurgency","Folder":"insurgency","Bots":0,"SteamID":"90104416476905476","Protocol":17,"Name":"SERNIX 24\/7 COOP #2 [18vs100AI|MEDICS|BOMBERS|MODS|MAPS|FASTDL]","ServerType":"d","ID":0,"GameID":"222880","Keywords":"g:checkpoint,p:sernix\/sernix_coop,t:dy_gnalvl_coop_usmc,v:2373,pure:-1,increasedbots,botcounter,coop,custommaps,no3dvoip,mods,r","Version":"2.3.7.3","MaxPlayers":18}]
]]
```

[OpenResty][1] 的起源引擎游戏服务器信息查询工具

受 [xPaw/PHP-Source-Query][2] 启发移植

### 已经实现的功能：
  * 数据结构转换
  * 协议封包
  * 查询方法（ping, getinfo）

### 待实现的功能：
  * 查询方法（getrules, getplayers）
  * bzip 解压

### 不知道会不会开坑的功能：
  * RCON


  [1]: http://openresty.org/
  [2]: https://github.com/xPaw/PHP-Source-Query
