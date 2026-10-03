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
