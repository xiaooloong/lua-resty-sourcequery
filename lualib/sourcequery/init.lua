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

_M._VERSION = '1.2.2'

local mt = { __index = _M }

function _M.new(self, host, port, timeout, engine)
    if not host then
        return nil, 'host ip address required'
    end
    port = port or 27015
    timeout = timeout or 1000
    local sock, err = udp()
    if not sock then
        return nil, err
    end
    engine = engine or 'source'
    return setmetatable({
        sock = sock,
        host = host,
        port = port,
        timeout = timeout,
        engine = engine,
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
    local p = proto:new(sock, self.engine)
    ok, err = p:send(packet.A2A_PING)
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
    ok, err = struct.get_char(b)
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
    local p = proto:new(sock, self.engine)
    local query = ('%sSource Engine Query%s'):format(
        packet.A2S_INFO, char(0)
    )
    ok, err = p:send(query)
    if not ok then
        sock:close()
        return nil, err
    end
    local b, err = p:receive()
    if not b then
        sock:close()
        return nil, err
    end
    local t, err = struct.get_char(b)
    if not t then
        sock:close()
        return nil, err
    end
    if packet.S2A_CHALLENGE == t then
        local challenge, err = b:get(4)
        if not challenge then
            sock:close()
            return nil, err
        end
        local query = ('%sSource Engine Query%s%s'):format(
            packet.A2S_INFO, char(0), challenge
        )
        ok, err = p:send(query)
        if not ok then
            sock:close()
            return nil, err
        end
        b, err = p:receive()
        sock:close()
        if not b then
            return nil, err
        end
        t, err = struct.get_char(b)
        if not t then
            return nil, err
        end
    else
        sock:close()
    end
    local info = new_tab(0, 32)
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
    elseif packet.S2A_BANNED == t then
        local msg = struct.get_string(b)
        return nil, ('you got banned by server : %s'):format(msg)
    else
        return nil, ('wrong packet id of %s(%d)'):format(t, t:byte())
    end
        
end

function _M.getchallenge(self, packetid, raw)
    local sock = self.sock
    if not sock then
        return nil, 'not initialized'
    end
    if not packetid then
        return nil, 'packet id required'
    end
    sock:settimeout(self.timeout)
    local ok, err = sock:setpeername(self.host, self.port)
    if not ok then
        return nil, err
    end
    local p = proto:new(sock, self.engine)
    ok, err = p:send(packetid .. char(0xff):rep(4))
    if not ok then
        sock:close()
        return nil, err
    end
    local b, err = p:receive()
    if not b then
        sock:close()
        return nil, err
    end
    local _packetid, err = struct.get_char(b)
    if packet.S2A_CHALLENGE == _packetid then
        local challange, err
        if raw then
            challange, err = b:get(4)
        else
            challange, err = struct.get_long(b)
        end
        if not challange then
            sock:close()
            return nil, 'failed to get challange : ' .. err
        end
        return p, challange
    elseif packet.S2A_BANNED == _packetid then
        local msg = struct.get_string(b)
        return nil, ('you got banned by server : %s'):format(msg)
    else
        sock:close()
        return nil, ('wrong packet id of %s(%d), expected S2A_CHALLENGE'):format(t, t:byte())
    end
end

function _M.getplayers(self)
    local p, challange = self.getchallenge(self, packet.A2S_PLAYER, true)
    if not p then
        return nil, challange
    end
    local sock = p.sock
    if not sock then
        return nil, 'failed to get udp socket handle from proto'
    end
    local ok, err = p:send(packet.A2S_PLAYER .. challange)
    if not ok then
        sock:close()
        return nil, err
    end
    local b, err = p:receive()
    sock:close()
    if not b then
        return nil, err
    end
    local _packetid, err = struct.get_char(b)
    if not _packetid then
        return nil, err
    end
    if packet.S2A_PLAYER == _packetid then
        local _count, err = struct.get_byte(b)
        if not _count then
            return nil, 'failed to get size of players'
        end
        local players = new_tab(_count, 0)
        if _count > 0 then
            for i = 1, _count do
                local _t = new_tab(0, 4)
                _t.Index = struct.get_byte(b)
                _t.Name = struct.get_string(b)
                _t.Score = struct.get_long(b)
                _t.Duration = struct.get_float(b)
                players[i] = _t
            end
        end
        return players
    elseif packet.S2A_BANNED == _packetid then
        local msg = struct.get_string(b)
        return nil, ('you got banned by server : %s'):format(msg)
    else
        return nil, ('wrong packet id of %s(%d)'):format(_packetid, _packetid:byte())
    end
end

function _M.getrules(self)
    local p, challange = self.getchallenge(self, packet.A2S_RULES, true)
    if not p then
        return nil, challange
    end
    local sock = p.sock
    if not sock then
        return nil, 'failed to get udp socket handle from proto'
    end
    local ok, err = p:send(packet.A2S_RULES .. challange)
    if not ok then
        sock:close()
        return nil, err
    end
    local b, err = p:receive()
    sock:close()
    if not b then
        return nil, err
    end
    local _packetid, err = struct.get_char(b)
    if not _packetid then
        return nil, err
    end
    if packet.S2A_RULES == _packetid then
        local _count, err = struct.get_short(b)
        if not _count then
            return nil, 'failed to get size of rules : ' .. err
        elseif _count < 0 then
            return nil, 'wrong size of rules : ' .. _count
        end
        local rules = new_tab(0, _count)
        if _count > 0 then
            for i = 1, _count do
                local k, err = struct.get_string(b)
                if not k then
                    return nil, ('failed to get rule name of %d/%d : %s'):format(i, _count, err)
                end
                local v, err = struct.get_string(b)
                if not v then
                    return nil, ('failed to get rule value of %d/%d : %s'):format(i, _count, err)
                end
                rules[k] = v
            end
        end
        return rules
    elseif packet.S2A_BANNED == _packetid then
        local msg = struct.get_string(b)
        return nil, ('you got banned by server : %s'):format(msg)
    else
        return nil, ('wrong packet id of %s(%d)'):format(_packetid, _packetid:byte())
    end
end

return _M