local Cell = {}
Cell.__index = Cell

Cell.LIMIT = 1
Cell.UNDEFINED = 2
Cell.ELEVATOR = 3
Cell.CORRIDOR = 4

function Cell:new()
    local o = {
        tileRef = Cell.UNDEFINED
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

return Cell