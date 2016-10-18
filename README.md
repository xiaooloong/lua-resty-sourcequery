# Resty Source-engine Query

is a Library to query Source-Engine game servers for [OpenResty][1].

Inspired by [xPaw/PHP-Source-Query][2].

```lua
local q = require 'sourcequery'
local j = require 'cjson'
--[[
    local s = q:new(
        host,       --ip address, required
        port,       --udp port, default value is 27015
        timeout,    --timeout, default value is 1000(ms)
        engine      --engine type, default is 'source',
                      otherwise will use Goldsource proto.
                      https://developer.valvesoftware.com/wiki/Server_queries#Goldsource_Server
    )
]]--
local server = q:new('207.173.67.34')
--[[
    local s = q:new('70.42.74.170', 27016)
    local s = q:new('216.131.79.171', 27015, 3000)
    local s = q:new('217.106.106.117', 27015, 1000, 'goldsource')
]]--
ngx.say(j.encode({server:ping()}))
--ngx.say(j.encode({server:getinfo()}))
--ngx.say(j.encode({server:getplayers()}))
--ngx.say(j.encode({server:getrules()}))
--[[
[true,0.26699995994568]
]]--
```

[OpenResty][1] 的起源引擎游戏服务器信息查询工具

受 [xPaw/PHP-Source-Query][2] 启发移植

### 已经实现的功能：
  * 查询方法（ping, getinfo, getrules, getplayers）

### 待实现的功能：
  * bzip 解压

### 不知道会不会开坑的功能：
  * RCON


  [1]: http://openresty.org/
  [2]: https://github.com/xPaw/PHP-Source-Query
