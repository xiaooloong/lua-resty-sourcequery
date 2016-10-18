-- Packet ID number
-- https://developer.valvesoftware.com/wiki/Server_queries#Requests

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 16)

_M._VERSION = '0.1.0'


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

-- Deprecated 
_M.A2A_PING      = 'i'
_M.A2A_PONG      = 'j'

return _M