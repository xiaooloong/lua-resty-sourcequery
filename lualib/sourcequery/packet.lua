-- Packet ID number
-- https://developer.valvesoftware.com/wiki/Server_queries#Requests

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 16)

_M._VERSION = '0.1.0'


-- App to Server
_M.A2S_INFO      = 0x54
_M.A2S_PLAYER    = 0x55
_M.A2S_RULES     = 0x56
_M.A2S_SERVERQUERY_GETCHALLENGE = 0x57

-- Server to App
_M.S2A_CHALLENGE = 0x41
_M.S2A_INFO      = 0x49
_M.S2A_INFO_OLD  = 0x6D
_M.S2A_PLAYER    = 0x44
_M.S2A_RULES     = 0x45
_M.S2A_RCON      = 0x6C

-- Deprecated 
_M.A2A_PING      = 0x69
_M.A2A_PONG      = 0x6A

return _M