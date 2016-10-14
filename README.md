# Resty Source-engine Query

Library to query Source-Engine game servers for [OpenResty][1]

This library is inspired by [xPaw/PHP-Source-Query][2]

There is only a 'ping' method now. Developing is ongoing.

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
local server = q:new('192.168.123.222')
--[[
    local s = q:new('192.168.123.222', 27016)
    local s = q:new('192.168.123.222', 27015, 3000)
]]--
ngx.say(j.encode({server:ping()}))
--'[true,0.0010001659393311]'
```

[OpenResty][1] 的起源引擎游戏服务器信息查询工具

受 [xPaw/PHP-Source-Query][2] 启发进行移植。转换数据结构真痛苦\_(:з」∠)\_

只实现了一个 ping 的功能，然而这个 ping 方法已经被 valve 官方标记为废弃。只有少数服务器才会响应了。

### 已经实现的功能：
  * 数据结构转换
  * 协议封包

### 待实现的功能：
  * 查询方法（服务器信息、服务器规则、服务器玩家列表）
  * bzip 解压

### 不知道会不会开坑的功能：
  * RCON


  [1]: http://openresty.org/
  [2]: https://github.com/xPaw/PHP-Source-Query
