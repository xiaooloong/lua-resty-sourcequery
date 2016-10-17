local proto = require 'sourcequery.proto'
local packet = require 'sourcequery.packet'
local struct = require 'sourcequery.struct'
local bit = require 'bit'
local band = bit.band
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
        sock:close()
        return nil, err
    end
    local st = now()
    local b, err = p:receive()
    sock:close()
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

function _M.getinfo(self)
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
    local query = ('%sSource Engine Query%s'):format(
        char(packet.A2S_INFO), char(0)
    )
    ok, err = p:send(query)
    if not ok then
        sock:close()
        return nil, err
    end
    local b, err = p:receive()
    sock:close()
    if not b then
        return nil, err
    end
    local info = new_tab(0, 32)
    local t, err = struct.get_byte(b)
    if not t then
        return nil, err
    end
    if packet.S2A_INFO == t then
        info.GoldSource  = false
        info.Protocol    = struct.get_byte(b)
        info.Name        = struct.get_string(b)
        info.Map         = struct.get_string(b)
        info.Folder      = struct.get_string(b)
        info.Game        = struct.get_string(b)
        info.ID          = struct.get_short(b)
        info.Players     = struct.get_byte(b)
        info.MaxPlayers  = struct.get_byte(b)
        info.Bots        = struct.get_byte(b)
        info.ServerType  = struct.get_char(b)
        info.Environment = struct.get_char(b)
        info.Visibility  = struct.get_byte(b)
        info.VAC         = struct.get_byte(b)

        -- game <The Ship> added
        if 2400 == info.ID then
            info.Mode      = struct.get_byte(b)
            info.Witnesses = struct.get_byte(b)
            info.Duration  = struct.get_byte(b)
        end

        info.Version     = struct.get_string(b)
        if b:remaining() > 0 then
            local _edf = struct.get_byte(b)
            if band(0x80, _edf) > 0 then
                info.Port = struct.get_short(b)
            end
            if band(0x10, _edf) > 0 then
                info.SteamID = struct.get_longlong(b)
            end
            if band(0x40, _edf) > 0 then
                info.SpecPort = struct.get_short(b)
                info.SpecName = struct.get_string(b)
            end
            if band(0x20, _edf) > 0 then
                info.Keywords = struct.get_string(b)
            end
            if band(0x01, _edf) > 0 then
                info.GameID = struct.get_longlong(b)
            end
            if b:remaining() > 0 then
                info.BufferRemaining = b:getall()
            end
        end
        return info
    elseif packet.S2A_INFO_OLD == t then
        info.GoldSource = true
        for _, v in ipairs({
            'Address', 'Name', 'Map',
            'Folder', 'Game',
        }) do
            info[v] = struct.get_string(b)
        end
        for _, v in ipairs({
            'Players', 'MaxPlayers', 'Protocol',
            'ServerType', 'Environment', 'Visibility',
            'Mod',
        }) do
            info[v] = struct.get_byte(b)
        end
        if 1 == info.Mod then
            info.Link = struct.get_string(b)
            info.DownloadLink = struct.get_string(b)
            struct.get_byte(b)
            info.Version = struct.get_long(b)
            info.Size = struct.get_long(b)
            info.Type = struct.get_byte(b)
            info.DLL = struct.get_byte(b)
        end
        for _, v in ipairs({
            'VAC', 'Bots'
        }) do
            info[v] = struct.get_byte(b)
        end
        if b:remaining() > 0 then
            info.BufferRemaining = b:getall()
        end
        return info
    else
        return nil, 'wrong packet id'
    end
        
end

return _M