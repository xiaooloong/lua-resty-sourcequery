local proto = require 'sourcequery.proto'
local packet = require 'sourcequery.packet'
local packet = require 'sourcequery.struct'
local udp = ngx.socket.udp
local rep = string.rep
local char = string.char
local now = ngx.now

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 32)

_M._VERSION = '0.1.0'

local mt = { __index = _M }

function _M.new(self, host, port, timeout)
    if not host then
        return nil, 'host ip address required'
    end
    port = port or 27015
    timeout = timeout or 1000
    local sock, err = udp()
    if not sock then
        return nil, err
    end
    return setmetatable({
        sock = sock,
        host = host,
        port = port,
        timeout = timeout,
    }, mt)
end

function _M.ping(self)
    local sock = self.sock
    if not sock then
        return nil, 'not initialized'
    end
    sock:settimeout(self.timeout)
    local ok, err = sock:setpeername(self.host, self.port)
    if not ok then
        return nil, err
    end
    local p = proto:new(sock)
    ok, err = p:send(char(packet.A2A_PING))
    if not ok then
        return nil, err
    end
    local st = now()
    local b, err = p:receive()
    if not b then
        return nil, err
    end
    ok, err = struct.get_byte(b)
    if not ok then
        return nil, err
    end
    local et = now()
    return ok == packet.A2A_PONG, et - st
end

return _M