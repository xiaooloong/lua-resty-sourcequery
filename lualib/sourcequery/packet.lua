-- Packet ID number
-- https://developer.valvesoftware.com/wiki/Server_queries#Requests

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 32)

_M._VERSION = '0.1.1'


-- App to Server
_M.A2S_INFO      = 'T'
_M.A2S_PLAYER    = 'U'
_M.A2S_RULES     = 'V'
_M.A2S_SERVERQUERY_GETCHALLENGE = 'W'

-- Server to App
_M.S2A_CHALLENGE = 'A'
_M.S2A_INFO      = 'I'
_M.S2A_INFO_OLD  = 'm'
_M.S2A_PLAYER    = 'D'
_M.S2A_RULES     = 'E'
-- Not documented but found in CS:GO and Insurgency
_M.S2A_BANNED    = 'l'

-- Deprecated 
_M.A2A_PING      = 'i'
_M.A2A_PONG      = 'j'

-- Rcon
_M.SERVERDATA_AUTH           = 3
_M.SERVERDATA_AUTH_RESPONSE  = 2
_M.SERVERDATA_EXECCOMMAND    = 2
_M.SERVERDATA_RESPONSE_VALUE = 0

return _M