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
        hasBeenMixed = false,
        additionalAreaRooms = {},
    }

    setmetatable(o, self)
    self.__index = self

    return o
end

function RectangleRoom:getOverlappingAreaWith(other)
    local overlappingAreaStartPoint = {
        x = 0,
        y = 0,
    }

    local overlappingAreaEndPoint = {
        x = 0,
        y = 0,
    }

    if (self.x > other.x) then 
        overlappingAreaStartPoint.x = self.x
    else
        overlappingAreaStartPoint.x = other.x
    end

    if (self.y > other.y) then 
        overlappingAreaStartPoint.y = self.y
    else
        overlappingAreaStartPoint.y = other.y
    end

    if (self.x + self.w - 1 > other.x + other.w - 1) then 
        overlappingAreaEndPoint.x = other.x + other.w - 1
    else
        overlappingAreaEndPoint.x = self.x + self.w - 1
    end

    if (self.y + self.h - 1 > other.y + other.h - 1) then 
        overlappingAreaEndPoint.y = other.y + other.h - 1
    else
        overlappingAreaEndPoint.y = self.y + self.h - 1
    end

    local overlappingArea = {
        x = overlappingAreaStartPoint.x,
        y = overlappingAreaStartPoint.y,
        w = overlappingAreaEndPoint.x - overlappingAreaStartPoint.x + 1,
        h = overlappingAreaEndPoint.y - overlappingAreaStartPoint.y + 1,
        area = 0,
    }

    if overlappingArea.w < 0 then
        overlappingArea.w = 0
    end

    if overlappingArea.h < 0 then
        overlappingArea.h = 0
    end

    overlappingArea.area = overlappingArea.w * overlappingArea.h
    return overlappingArea
end

function RectangleRoom:isCorridorRoom()
    return self.w == 1 or self.h == 1
end
