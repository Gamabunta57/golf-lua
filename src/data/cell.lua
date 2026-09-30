Cell = {
    LIMIT = 1,
    UNDEFINED = 2,
    ELEVATOR = 3,
    CORRIDOR = 4,
}

Cell.__index = Cell

function Cell:new()
    local o = {
        tileRef = Cell.UNDEFINED,
        anchor = {
            toTop = false,
            toRight = false,
            toBottom = false,
            toLeft = false,
        },
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Cell:hasAnchor()
    return self.anchor.toTop
        or self.anchor.toRight
        or self.anchor.toBottom
        or self.anchor.toLeft
end

function Cell:anchorCount()
    local count = 0
    if (self.anchor.toTop) then 
        count = 1
    end
    if (self.anchor.toRight) then
        count = count + 1
    end
    if (self.anchor.toBottom) then
        count = count + 1
    end
    if (self.anchor.toLeft) then
        count = count + 1
    end
    return count
end
