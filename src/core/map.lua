require("src/core/cell")

---@class Map
---@field width number the width of a floor of the map
---@field height number the height of a floor of the map
---@field depth number the floor count of the map
---@field mapData metatable<Cell> the set of cells the map is composed of
Map = {}
Map.__index = Map

---@ctor
---@param width number
---@param height number
---@param depth number
function Map:new(width, height, depth)
    width = width or 16
    height = height or 16
    depth = depth or 16

    local mapData = {}
    for i=1, width * height * depth do
        mapData[i] = Cell:new()
    end

    local o = {
        width = width,
        height = height,
        depth = depth,
        mapData = mapData
    }

    setmetatable(o, self)
    return o
end

---Returns an ASCII character displayable in the terminal
---@param walls number the walls definition as per the Cell.walls
---@return string a single ASCII character
---@private
function Map.getCharacter(walls)
    if walls == Cell.CELL_WALL_ALL then
        return "."
    elseif walls == Cell.CELL_WALL_RIGHT then
        return "|"
    elseif walls == Cell.CELL_WALL_BOTTOM then
        return "_"
    elseif walls == Cell.CELL_WALL_NONE then
        return " "
    elseif walls == Cell.CELL_ELEVATOR then
        return "E"
    else
        return "?"
    end
end

---toString() metamethod to debug the map in the terminal
---@return string
function Map:__tostring()
    local output = "Map: ".. self.width .. "x".. self.height .. "x" .. self.depth .. "\n\n"
    local i = 1
    for z=1, self.depth do
        output = output .. "----------------\n"
        for y=1, self.height do
            for x=1, self.width do
                local mapChar = Map.getCharacter(self.mapData[i].walls)
                output = output .. mapChar
                i = i + 1
            end
            output = output .. "\n"
        end
    end
    return output
end
