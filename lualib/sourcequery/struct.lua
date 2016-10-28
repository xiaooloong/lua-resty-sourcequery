--[[
    Source Engine network data types.
    https://developer.valvesoftware.com/wiki/Server_queries#Data_Types
]]--
local bit = require 'bit'
local ffi = require 'ffi'
local ffi_new = ffi.new
local ffi_copy = ffi.copy
local byte = string.byte
local char = string.char
local reverse = string.reverse
local is_be = ffi.abi('be')

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
    if is_be then
        data = reverse(data)
    end
    local short = ffi_new('int16_t[1]')
    ffi_copy(short, data, 2)
    return tonumber(short[0])
end

-- 32 bit signed int, little endian
function _M.get_long(buff)
    local data, err = buff:get(4)
    if not data then
        return nil, err
    end
    if is_be then
        data = reverse(data)
    end
    local int = ffi_new('int32_t[1]')
    ffi_copy(int, data, 4)
    return tonumber(int[0])
end

-- 64 bit unsigned int, little endian
function _M.get_longlong(buff)
    local data, err = buff:get(8)
    if not data then
        return nil, err
    end
    if is_be then
        data = reverse(data)
    end
    local int = ffi_new('uint64_t[1]', 0)
    ffi_copy(int, data, 8)
    return tostring(int[0]):sub(1, -4)
end

-- 32 bit float, little endian
function _M.get_float(buff)
    local data, err = buff:get(4)
    if not data then
        return nil, err
    end
    if is_be then
        data = reverse(data)
    end
    local float = ffi_new('float[1]')
    ffi_copy(float, data, 4)
    return tonumber(float[0])
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