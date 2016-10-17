--[[
    Source Engine network data types.
    https://developer.valvesoftware.com/wiki/Server_queries#Data_Types
]]--
local bit = require 'bit'
local ffi = require 'ffi'
local byte = string.byte
local char = string.char
local reverse = string.reverse

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 8)

_M._VERSION = '0.1.0'

-- 1 byte char
function _M.get_char(buff)
    local data, err = buff:get(1)
    if not data then
        return nil, err
    end
    return data
end

-- 8 bit unsigned int
function _M.get_byte(buff)
    local data, err = buff:get(1)
    if not data then
        return nil, err
    end
    return byte(data)
end

-- 16 bit signed int, little endian
function _M.get_short(buff)
    local data, err = buff:get(2)
    if not data then
        return nil, err
    end
    local al = byte(data)
    local ah = byte(data, 2)
    local ax = ah * 0x100 + al
    if ax > 0x7fff then
        ax = ax - 0x10000
    end
    return ax
end

-- 32 bit signed int, little endian
function _M.get_long(buff)
    local data, err = buff:get(4)
    if not data then
        return nil, err
    end
    local int = 0
    data = reverse(data)
    for i = 1, 4 do
        local part = byte(data, i)
        int = int * 0x100 + part
    end
    if int > 0x7fffffff then
        int = int - 0x100000000
    end
    return int
end

-- 64 bit unsigned int, little endian
function _M.get_longlong(buff)
    local data, err = buff:get(8)
    if not data then
        return nil, err
    end
    local int = ffi.new('uint64_t', 0)
    data = reverse(data)
    for i = 1, 8 do
        local part = byte(data, i)
        int = int * 0x100 + part
    end
    return tostring(int):sub(1, -4)
end

-- 32 bit float, little endian
-- https://en.wikipedia.org/wiki/Single-precision_floating-point_format
function _M.get_float(buff)
    local data, err = buff:get(4)
    if not data then
        return nil, err
    end
    data = reverse(data)
    local int = 0
    for i = 1, 4 do
        local part = byte(data, i)
        int = int * 0x100 + part
    end
    local s
    if int > 0x7fffffff then
        s = -1
    else
        s = 1
    end
    local f = int % 0x800000 + 0x800000
    local e = bit.rshift(int, 23) % 0x100 - 127 - 23
    return s * f * 2 ^ e
end

-- string, terminated by 0x00
function _M.get_string(buff)
    local s = ''
    local split = char(0)
    local part = ''
    repeat
        s = s .. part
        local err
        part, err = buff:get(1)
        if not part then
            return nil, err, s
        end
    until split == part
    return s
end

return _M