require("src/data/cell")

RectangleRoom = {}
RectangleRoom.__index = RectangleRoom

function RectangleRoom:new(x, y, w, h, ri)
    local o = {
        x = x or 0,
        y = y or 0,
        w = w or 0,
        h = h or 0,
        roomIndex = ri or 0,
        hasBeenMixed = false
    }

    setmetatable(o, self)
    self.__index = self

    return o
end

function RectangleRoom:overlaps(other)
    local startXA = self.x
    local endXA = self.x + self.w
    local startXB = other.x
    local endXB = other.x + other.w

    local startYA = self.y
    local endYA = self.y + self.h
    local startYB = other.y
    local endYB = other.y + other.h

    return startXA < endXB and endXA > startXB and startYA < endYB and endYA > startYB
end
