require("src/data/cell")

Map = {}
Map.__index = Map

function Map:new(width, height, depth)
    local o = {
        width = width or 1,
        height = height or 1,
        depth = depth or 1,
        floorCells = {},
        floorRooms = {},
    }

    setmetatable(o, self)
    self.__index = self

    o:_initMap()
    return o
end

function Map:_initMap()
    local cellPerFloor = self.width * self.height
    for z = 1, self.depth do
        local currentFlooCells = {}
        for xy = 1, cellPerFloor do
            currentFlooCells[xy] = Cell:new()
        end
        self.floorCells[z] = currentFlooCells
        self.floorRooms[z] = {}
    end
end
