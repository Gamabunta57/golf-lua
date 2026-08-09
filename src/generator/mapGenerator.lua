require("src/core/cell")
require("src/core/prng")

---@class MapGenerator
---@field prng Prng
---@field map Map
---@field options {roomThreshold: number, shouldCarveRoom: boolean}
MapGenerator = {}
MapGenerator.__index = MapGenerator

local defaultOptions = {
    roomThreshold = 10,
    shouldCarveRoom = true,
}

---@ctor
---@param prng Prng
---@param map Map
---@param options [metatable]
function MapGenerator:new(prng, map, options)
    if not prng then error("prng parameter must be set") end
    if not map then error("map parameter must be set") end

    if not options then
        options = defaultOptions
    end

    local o = {
        prng = prng,
        map = map,
        options = options,
    }

    setmetatable(o, self)
    return o
end

---Initialise the map by setting surrounding walls on all floors
function MapGenerator:initialiseMap()
    local depth = self.map.depth
    local height = self.map.height
    local width = self.map.width
    local floorTileCount = height * width
    local lastTileRowStartIndex = width * (height - 1)

    for z=0, depth - 1 do
        local floorBaseIndex = z * floorTileCount
        -- setting left and right walls
        for y=0, height -1 do
            local index = floorBaseIndex + y * width
            self.map.mapData[index + 1].index = Cell.CELL_WALL_BLOCKED
            self.map.mapData[index + width].index = Cell.CELL_WALL_BLOCKED
            self.map.mapData[index + 1].walls = 9
            self.map.mapData[index + width].walls = 9
        end

        -- setting top and bottom walls
        for x = 2, width - 1 do
            local index = floorBaseIndex + x
            self.map.mapData[index].index = Cell.CELL_WALL_BLOCKED
            self.map.mapData[index + lastTileRowStartIndex].index = Cell.CELL_WALL_BLOCKED
            self.map.mapData[index].walls = 9
            self.map.mapData[index + lastTileRowStartIndex].walls = 9
        end
    end
end

---Returns an array of "directions"; a tuple of (mapsCellIndex, directionName)
---@param mapCellIndex number the cell index on the map
---@return metatable
function MapGenerator:getAvailableDirections(mapCellIndex)
    local map = self.map.mapData
    local topCell = map[mapCellIndex - self.map.width]
    local rightCell = map[mapCellIndex + 1]
    local bottomCell = map[mapCellIndex + self.map.width]
    local leftCell = map[mapCellIndex - 1]

    local availableDirections = {}
    if topCell.index == Cell.CELL_UNWALKED then
        availableDirections[1] = {mapCellIndex - self.map.width, "top"}
    end
    if rightCell.index == Cell.CELL_UNWALKED then
        availableDirections[#availableDirections + 1] = {mapCellIndex + 1, "right"}
    end
    if bottomCell.index == Cell.CELL_UNWALKED then
        availableDirections[#availableDirections + 1] = {mapCellIndex + self.map.width, "bottom"}
    end
    if leftCell.index == Cell.CELL_UNWALKED then
        availableDirections[#availableDirections + 1] = {mapCellIndex - 1, "left"}
    end

    return availableDirections
end

---Mark a cell as "browsed" or "walked" to avoid passing 2 times on the same cell
---@param cellIndex number the index of the cell in the map
---@param step number a number matching the step count made to reach it
function MapGenerator:markCellAsBrowsed(cellIndex, step)
    local cell = self.map.mapData[cellIndex]
    if (cell.index < 0) then
        cell.index = step
    end
end

---Removes a wall on a given cell given the wall to remove
---@param mapCellIndex number the index of the cell in the map where to run the operation
---@param wallToRemove number the wall reference to remove
function MapGenerator:removeWall(mapCellIndex, wallToRemove)
    local mapCell = self.map.mapData[mapCellIndex]
    local walls = mapCell.walls
    if (wallToRemove == Cell.CELL_WALL_RIGHT) then
        if walls == Cell.CELL_WALL_ALL or walls == Cell.CELL_WALL_RIGHT then
            self.map.mapData[mapCellIndex].walls = self.map.mapData[mapCellIndex].walls - wallToRemove
        end
    end

    if (wallToRemove == Cell.CELL_WALL_BOTTOM) then
        if walls == Cell.CELL_WALL_ALL or walls == Cell.CELL_WALL_BOTTOM then
            self.map.mapData[mapCellIndex].walls = self.map.mapData[mapCellIndex].walls - wallToRemove
        end
    end
end

---Removes the right walls and bottom walls on the right and bottom border of the map
function MapGenerator:cleanMapBorder()
    local depth = self.map.depth
    local height = self.map.height
    local width = self.map.width
    local floorTileCount = height * width
    local lastTileRowStartIndex = width * (height - 2)

    for z=0, depth - 1 do
        local floorBaseIndex = z * floorTileCount
        -- cleaning right walls
        for y=2, height - 1 do
            local index = floorBaseIndex + y * width
            self:removeWall(index - 1, Cell.CELL_WALL_RIGHT)
        end

        -- cleaning bottom walls
        for x = 2, width - 1 do
            local index = floorBaseIndex + x
            self:removeWall(index + lastTileRowStartIndex, Cell.CELL_WALL_BOTTOM)
        end
    end
end

---Generate a maze in the map
function MapGenerator:generateMaze()
    local startingPointX = self.prng:next(2, self.map.width - 1)
    local startingPointY = self.prng:next(2, self.map.height - 1)
    local startingPoint = startingPointX + (startingPointY - 1) * self.map.width

    local indicesStack = {startingPoint}
    local currentStackIndex = 1
    local tileWalkedCount = 0
    self:markCellAsBrowsed(indicesStack[currentStackIndex], tileWalkedCount)
    while currentStackIndex > 0 do
        local currentMapIndex = indicesStack[currentStackIndex]
        local availableDirections = self:getAvailableDirections(currentMapIndex)

        if #availableDirections == 0 then
            currentStackIndex = currentStackIndex - 1
            self:markCellAsBrowsed(currentMapIndex, tileWalkedCount)
            goto continue
        end

        local directionIndex = self.prng:next(1, #availableDirections)
        local nextIndex = availableDirections[directionIndex]
        currentStackIndex = currentStackIndex + 1
        indicesStack[currentStackIndex] = nextIndex[1]

        if (nextIndex[2] == "top") then
            self:removeWall(nextIndex[1], Cell.CELL_WALL_BOTTOM)
        elseif nextIndex[2] == "right" then
            self:removeWall(currentMapIndex, Cell.CELL_WALL_RIGHT)
        elseif nextIndex[2] == "bottom" then
            self:removeWall(currentMapIndex, Cell.CELL_WALL_BOTTOM)
        elseif nextIndex[2] == "left" then
            self:removeWall(nextIndex[1], Cell.CELL_WALL_RIGHT)
        end

        self:markCellAsBrowsed(currentMapIndex, tileWalkedCount)
        tileWalkedCount = tileWalkedCount + 1

        ::continue::
    end

    self:cleanMapBorder()
end

---Carves room in the map based on the indices of the map cells
function MapGenerator:carveRooms()
    local rightCellOffset = 1
    local bottomCellOffset = self.map.width
    local roomThreshold = self.options.roomThreshold

    for i = 1, #self.map.mapData do
        local cell = self.map.mapData[i]

        if cell.index == -2 then goto continue end

        local rightCell = self.map.mapData[i + rightCellOffset]
        local bottomCell = self.map.mapData[i + bottomCellOffset]

        if rightCell.index >= 0 then
            local diff = math.abs(rightCell.index - cell.index)
            if diff > 2 and diff <= roomThreshold then
                self:removeWall(i, Cell.CELL_WALL_RIGHT)
            end
        end

        if bottomCell.index >= 0 then
            local diff = math.abs(bottomCell.index - cell.index)
            if diff > 2 and diff <= roomThreshold then
                self:removeWall(i, Cell.CELL_WALL_BOTTOM)
            end
        end

        ::continue::
    end
end

---Runs the map generation
function MapGenerator:generate()
    self:initialiseMap()
    self:generateMaze()

    if (self.options.shouldCarveRoom) then
       self:carveRooms()
    end
end
