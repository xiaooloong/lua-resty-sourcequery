local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 8)

_M._VERSION = '0.1.0'

local mt = { __index = _M }

function _M.new(self)
    local pool = ''
    local position = 0
    return setmetatable({
        pool = pool,
        position = position,
    }, mt)
end

function _M.set(self, data)
    if not self.pool then
        return nil, 'not initialized'
    end
    self.pool = data
    self.position = 0
end

function _M.apply(self, data)
    if not self.pool then
        return nil, 'not initialized'
    end
    self.pool = self.pool .. data
end

function _M.get(self, length)
    if not self.pool then
        return nil, 'not initialized'
    end
    length = length or 1
    local position = self.position
    if position + length > #self.pool then
        return nil, 'buffer overflow'
    end
    self.position = position + length
    return self.pool:sub(position + 1, self.position)
end

function _M.getall(self)
    if not self.pool then
        return nil, 'not initialized'
    end
    if self.remain() > 0 then
        return self.pool:sub(self.position + 1)
    else
        return nil, 'nothing left in buffer'
    end
end

function _M.remain(self)
    if not self.pool then
        return nil, 'not initialized'
    end
    return #self.pool - self.position
end

return _M