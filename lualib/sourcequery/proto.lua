-- Protocol layout
-- https://developer.valvesoftware.com/wiki/Server_queries#Protocol

local struct = require 'sourcequery.struct'
local buffer = require 'sourcequery.buffer'
local bit = require 'bit'
local udp = ngx.socket.udp
local crc32 = ngx.crc32_long
local char = string.char
local rep = string.rep

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 32)

_M._VERSION = '0.1.0'

local mt = { __index = _M }

function _M.new(self, sock, engine)
    if not sock then
        return nil, 'udp socket handle required'
    end
    local sock = sock
    engine = engine or 'source'
    return setmetatable({
        sock = sock,
        engine = engine,
    }, mt)
end

function _M.send(self, data)
    local sock = self.sock
    if not sock then
        return nil, 'not initialized'
    end
    -- all data is prefixed by a long int -1, meaning it is not split.
    -- https://developer.valvesoftware.com/wiki/Server_queries#Simple_Response_Format
    local d = rep(char(0xff), 4) .. data
    return sock:send(d)
end

function _M.receive(self)
    local sock = self.sock
    if not sock then
        return nil, 'not initialized'
    end
    local data, err = sock:receive()
    if not data then
        return nil, err
    end
    local buff = buffer:new()
    buff:set(data)
    --[[ 
        packet header
        for -1 is one single packet,
        or -2 means there are series split packets
    ]]--
    local split, err = struct.get_long(buff)
    if not split then
        return nil, err
    end
    if -1 == split then
        return buff
    elseif -2 == split then
        local packetsid, total, packetnumber
        local compressed, rawsize, crc32sum
        local packets = {}
        local i = 0
        repeat
            i = i + 1
            local id, err = struct.get_long(buff)
            if not id then
                return nil, 'failed to get packet id : ' .. err
            end
            if not packetsid then
                packetsid = id
            elseif id ~= packetsid then
                return nil, ('packet id is differ from previous : %d/%d'):format(
                    id, packetsid
                )
            end
            if 'source' ~= self.engine then
                local combine, err = struct.get_byte(buff)
                if not combine then
                    return nil, 'failed to get packet number : ' .. err
                end
                if not total then
                    total = combine % 0x10
                elseif total ~= combine % 0x10 then
                    return nil, ('total is differ from previous : %d/%d'):format(
                        combine % 0x10, total
                    )
                end
                packetnumber = bit.rshift(combine, 4)
                local data, err = buff:getall()
                if not data then
                    return nil, ('failed to get payload of packet %d(%d/%d) : %s'):format(
                        i, packetnumber, total, err
                    )
                end
                packets[packetnumber + 1] = data
            else
                if 1 == i and packetsid < 0 then
                    compressed = true
                end
                local _total, err = struct.get_byte(buff)
                if not _total then
                    return nil, 'failed to get total number of packets'
                end
                if not total then
                    total = _total
                elseif total ~= _total then
                    return nil, ('total number is differ from previous : %d/%d'):format(
                        _total, total
                    )
                end
                packetnumber, err = struct.get_byte(buff)
                if not packetnumber then
                    return nil, 'failed to get number of packet'
                end
                struct.get_short(buff)
                if compressed and 0 == packetnumber then
                    rawsize, err = struct.get_long(buff)
                    if not rawsize then
                        return nil, 'failed to get uncompressed length'
                    end
                    crc32sum, err = struct.get_long(buff)
                    if not crc32sum then
                        return nil, 'failed to get umcompressed checksum'
                    end
                    -- this long int is unsigned
                    if crc32sum < 0 then
                        crc32sum = crc32sum + 0x100000000
                    end
                end
                local data, err = buff:getall()
                if not data then
                    return nil, ('failed to get payload of packet %d(%d/%d) : %s'):format(
                        i, packetnumber, total, err
                    )
                end
                packets[packetnumber + 1] = data
            end
            if i < total then
                local data, err = sock:receive()
                if not data then
                    return nil, ('failed to receive packet %d(%d) : %s'):format(
                        i, total, err
                    )
                end
                buff:set(data)
                local split, err = struct.get_long(buff)
                if not split then
                    return nil, ('failed to get header of packet %d(%d) : %s'):format(
                        i, total, err
                    )
                end
                if -2 ~= split then
                    return nil, ('following packet %d(%d) is a single packet'):format(
                        i, total
                    )
                end
            end
        until i == total
        local data = table.concat(packets)
        if compressed then
            return nil, 'data is compressed and this library is not support yet'
            --[[
            data = maybe_a_function_will_do_decompress(data)
            if rawsize ~= #data then
                return nil, 'packet wrong size'
            end
            if crc32sum ~= crc32(data) then
                return nil, 'packet bad checksum'
            end
            ]]--
        end
        buff:set(data)
        struct.get_long(buff)
        return buff
    else
        return nil, ('wrong packet header of %d'):format(split)
    end
end

return _M