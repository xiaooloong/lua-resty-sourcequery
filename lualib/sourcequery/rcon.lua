local struct = require 'sourcequery.struct'
local buffer = require 'sourcequery.buffer'
local packet = require 'sourcequery.packet'
local tcp = ngx.socket.tcp
local tonumber = tonumber
local setmetatable = setmetatable
local char = string.char

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 32)

local mt = { __index = _M }

function _M.new(self)
    local sock, err = tcp()
    if not sock then
        return nil, err
    end
    return setmetatable({
        sock = sock,
        id = 0,
    }, mt)
end

function _M.send(self, packtype, data)
    local sock = self.sock
    if not sock then
        return nil, 'not initilized'
    end
    if not packtype then
        return nil, 'package type required'
    end
    data = data or ''
    self.id = self.id + 1
    local id = struct.set_long(self.id)
    packtype = struct.set_long(packtype)
    data = id .. packtype .. data .. char(0):rep(2)
    local size = struct.set_long(#data)
    data = size .. data
    local ok, err = sock:send(data)
    return ok == #data, err
end

function _M.receive(self)
    local sock = self.sock
    if not sock then
        return nil, 'not initilized'
    end
    local size, err = sock:receive(4)
    if not size then
        return nil, err
    end
    local buff = buffer:new()
    buff:set(size)
    size, err = struct.get_long(buff)
    if not size then
        return nil, err
    end
    if 10 > size then
        return nil, 'wrong package size of ' .. size
    end
    local data, err = sock:receive(size)
    if not data then
        return nil, err
    end
    buff:set(data)
    local id, err = struct.get_long(buff)
    if not id then
        return nil, 'no package id' .. err
    end
    if self.id ~= id then
        if -1 == id then
            return nil, 'wrong rcon password'
        else
            return nil, ('expect id of %d but received %d'):format(
                self.id, id
            )
        end
    end
    local packtype, err = struct.get_long(buff)
    if not packtype then
        return nil, 'no package type' .. err
    end
    local body, err = struct.get_string(buff)
    if not body then
        return nil, 'no package body' .. err
    end
    return packtype, body
end

function _M.connect(self, rconpass, host, port, timeout)
    local sock = self.sock
    if not sock then
        return nil, 'not initilized'
    end
    if not rconpass or 'string' ~= type(rconpass) then
        return nil, 'rcon password required'
    end
    if not host or 'string' ~= type(host) then
        return nil, 'ip address required'
    end
    timeout = tonumber(timetout) or 1000
    sock:settimeout(timeout)
    port = tonumber(port) or 27015
    local ok, err = sock:connect(host, port)
    if not ok then
        return nil, err
    end
    ok, err = self:send(packet.SERVERDATA_AUTH, rconpass)
    if not ok then
        sock:close()
        return nil, err
    end
    local packtype, body = self:receive()
    if not packtype then
        sock:close()
        return nil, body
    end
    if packet.SERVERDATA_RESPONSE_VALUE == packtype then
        packtype, body = self:receive()
        if not packtype then
            sock:close()
            return nil, body
        end
    end
    if packet.SERVERDATA_AUTH_RESPONSE ~= packtype then
        sock:close()
        return nil, 'wrong package type of ' .. packtype
    end
    return true
end

function _M.exec(self, command)
    local sock = self.sock
    if not sock then
        return nil, 'not initilized'
    end
    if not command or 'string' ~= type(command) then
        return nil, 'no command'
    end
    local ok, err = self:send(packet.SERVERDATA_EXECCOMMAND, command)
    if not ok then
        return nil, err
    end
    local packtype, body = self:receive()
    if not packtype then
        return nil, body
    end
    if packet.SERVERDATA_RESPONSE_VALUE ~= packtype then
        return nil, 'wrong packet type of ' .. packtype
    end
    return body
end

function _M.close(self)
    local sock = self.sock
    if not sock then
        return nil, 'not initilized'
    end
    return sock:close()
end
return _M