Cell = {
    LIMIT = 1,
    UNDEFINED = 2,
    ELEVATOR = 3,
    CORRIDOR = 4,
}

Cell.__index = Cell

function Cell:new()
    local o = {
        tileRef = Cell.UNDEFINED
    }
    setmetatable(o, self)
    self.__index = self
    return o
end
