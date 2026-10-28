Cell = {
    LIMIT = 1,
    UNDEFINED = 2,
    ELEVATOR = 3,
    CORRIDOR = 4,
    ROOM = 5,
    WALL_NONE = 1,
    WALL_BOTTOM = 2,
    WALL_RIGHT = 3,
    WALL_RIGHT_AND_BOTTOM = 4,
    NO_OPENINGS = 0,
    OPENED_BOTTOM = 1,
    OPENED_RIGHT = 2,
    STAIRCASE_UP = 3,
    STAIRCASE_DOWN = 4,
    CLOSED_BOTTOM = 5,
    CLOSED_RIGHT = 6,
}

Cell.__index = Cell

function Cell:new()
    local o = {
        tileRef = Cell.UNDEFINED,
        roomIndex = 0,
        anchor = Cell.getEmptyAnchors(),
        wallRef = Cell.WALL_NONE,
        openings = Cell.NO_OPENINGS,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Cell.getEmptyAnchors()
    return {
        toTop = false,
        toRight = false,
        toBottom = false,
        toLeft = false,
    }
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
