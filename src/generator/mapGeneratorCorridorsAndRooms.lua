require("src/core/cell")
require("src/core/prng")

---@class MapGenerator
---@field prng Prng
---@field map Map
---@field options {roomThreshold: number, shouldCarveRoom: boolean}
MapGenerator = {}
MapGenerator.__index = MapGenerator

local DIRECTIONS = {
    TOP = 1,
    RIGHT = 2,
    BOTTOM = 4,
    LEFT = 8
}

local defaultOptions = {
    roomThreshold = 10,
    shouldCarveRoom = true,
    corridorsStep = 12,
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
            self.map.mapData[index + 1].walls = Cell.CELL_SURROUNDING_WALLS
            self.map.mapData[index + width].walls = Cell.CELL_SURROUNDING_WALLS
        end

        -- setting top and bottom walls
        for x = 2, width - 1 do
            local index = floorBaseIndex + x
            self.map.mapData[index].index = Cell.CELL_WALL_BLOCKED
            self.map.mapData[index + lastTileRowStartIndex].index = Cell.CELL_WALL_BLOCKED
            self.map.mapData[index].walls = Cell.CELL_SURROUNDING_WALLS
            self.map.mapData[index + lastTileRowStartIndex].walls = Cell.CELL_SURROUNDING_WALLS
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
        else
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

        end
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

        if not cell.index == -2 then

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
        end
    end
end

-- Places the elevator on random coordinates and returns it back
function MapGenerator:placeElevator()
    local minXCoord = 3
    local minYCoord = 3
    local maxXCoord = self.map.width - 2 -- at map.width there are walls and we keep 1 space to ease the algo
    local maxYCoord = self.map.height - 3 -- at map.height there are walls and we need 1 space for a corridor start

    local elevatorX = self.prng:next(minXCoord, maxXCoord)
    local elevatorY = self.prng:next(minYCoord, maxYCoord)

    local baseMapIndex = elevatorX + elevatorY * self.map.width
    local floorIndexShift = self.map.width * self.map.height
    for i = 1, self.map.depth do
        local mapIndex = baseMapIndex + floorIndexShift * (i - 1)
        self.map.mapData[mapIndex].index = Cell.CELL_ELEVATOR
        self.map.mapData[mapIndex].walls = Cell.CELL_WALL_RIGHT
    end

    return baseMapIndex
end

function MapGenerator:getAvailableCellDirections(cell)
    local directions = {}
    local directionsDone = cell.directionsDone

    if not directionsDone.TOP then
        directions[1] = DIRECTIONS.TOP
    end

    if not directionsDone.RIGHT then
        directions[#directions + 1] = DIRECTIONS.RIGHT
    end

    if not directionsDone.BOTTOM then
        directions[#directions + 1] = DIRECTIONS.BOTTOM
    end

    if not directionsDone.LEFT then
        directions[#directions + 1] = DIRECTIONS.LEFT
    end

    return directions
end

function MapGenerator:getDirectionMaxDistance(cell, directionStepOffset)
    local isEndReached = false
    local distance = 0
    local currentCellMapIndex = cell.index

    while not isEndReached do
        local nextCell = self.map.mapData[currentCellMapIndex + directionStepOffset]
        if nextCell.index == Cell.CELL_UNWALKED then
            distance = distance + 1
            currentCellMapIndex = currentCellMapIndex + directionStepOffset
        else
            isEndReached = true
        end
    end

    return distance
end

function MapGenerator:markCellDirectionAsDone(cell, directionToGoTo)
    if directionToGoTo == DIRECTIONS.TOP then
        cell.directionsDone.TOP = true
    elseif directionToGoTo == DIRECTIONS.RIGHT then
        cell.directionsDone.RIGHT = true
    elseif directionToGoTo == DIRECTIONS.BOTTOM then
        cell.directionsDone.BOTTOM = true
    else -- directionToGoTo == DIRECTIONS.LEFT
        cell.directionsDone.TOP = true
    end

    self.map.mapData[cell.index].index = Cell.CELL_WALL_NONE
end

function MapGenerator:getDirectionStepOffset(directionToGoTo)
    if directionToGoTo == DIRECTIONS.TOP then
        return -self.map.width
    elseif directionToGoTo == DIRECTIONS.RIGHT then
        return 1
    elseif directionToGoTo == DIRECTIONS.BOTTOM then
        return self.map.width
    else -- directionToGoTo == DIRECTIONS.LEFT
        return -1
    end
end

function MapGenerator:carveWallInDrection(cellIndex, nextCellIndex, directionToGoTo)
    if directionToGoTo == DIRECTIONS.TOP then
        self:removeWall(nextCellIndex, Cell.CELL_WALL_BOTTOM)
    elseif directionToGoTo == DIRECTIONS.RIGHT then
        self:removeWall(cellIndex, Cell.CELL_WALL_RIGHT)
    elseif directionToGoTo == DIRECTIONS.BOTTOM then
        self:removeWall(cellIndex, Cell.CELL_WALL_BOTTOM)
    elseif directionToGoTo == DIRECTIONS.LEFT then
        self:removeWall(nextCellIndex, Cell.CELL_WALL_RIGHT)
    end
    self.map.mapData[cellIndex].index = Cell.CELL_WALL_NONE
    self.map.mapData[nextCellIndex].index = Cell.CELL_WALL_NONE
end

function MapGenerator:hasCellDirectionsLeft(cell)
    local dir = cell.directionsDone
    return not(dir.TOP and dir.RIGHT and dir.BOTTOM and dir.LEFT)
end

---carve the corridors in a given number of steps
---@param elevatorMapIndex number
function MapGenerator:carveCorridors(elevatorMapIndex)
    local mapFloorSize = self.map.width * self.map.height
    for z = 0, self.map.depth - 1 do
        local startingPoint = elevatorMapIndex -- elevator tile
          + (z * mapFloorSize) -- floor offset
          + self.map.width -- next row (tile below the elevator tile)

        local cellMapIndexStack = {
            {
                index = startingPoint,
                directionsDone = {
                    TOP = true,
                    RIGHT = false,
                    BOTTOM = false,
                    LEFT = false,
                }
            },
        }
        local cellMapIndexStackCount = 1

        local i = 1
        local corridorStepsAreDone = false
        while not corridorStepsAreDone do
            print("Run corridor step: ", i)
            if cellMapIndexStackCount == 0 then
                print("something is getting wrong")
            end

            local availableCellsIndex = 1
            if (cellMapIndexStackCount > 1) then
                availableCellsIndex = self.prng:next(1, cellMapIndexStackCount)
            end

            local cell = cellMapIndexStack[availableCellsIndex]

            local availableDirections = self:getAvailableCellDirections(cell)
            local directionToGoTo = availableDirections[1]

            if #availableDirections > 1 then
                local dir = self.prng:next(1, #availableDirections);
                directionToGoTo = availableDirections[dir]
            end

            local directionStepOffset = self:getDirectionStepOffset(directionToGoTo)
            local maxDistance = self:getDirectionMaxDistance(cell, directionStepOffset)
            if maxDistance == 0 then
                -- cancel this step and retry
                self:markCellDirectionAsDone(cell, directionToGoTo)
                i = i - 1 -- risky, let's check that
                -- continue loop
            else
                local distanceToCarve = 0
                if (maxDistance == 1) then
                    distanceToCarve = 1
                else
                    distanceToCarve = self.prng:next(1, maxDistance)
                end

                
                local currentCellIndexToCarve = cell.index
                local nextCellIndexToCarve = cell.index + directionStepOffset
                for j = 1, distanceToCarve do
                    self:carveWallInDrection(currentCellIndexToCarve, nextCellIndexToCarve, directionToGoTo)
                    currentCellIndexToCarve = nextCellIndexToCarve
                    nextCellIndexToCarve = nextCellIndexToCarve + directionStepOffset
                end

                self:markCellDirectionAsDone(cell, directionToGoTo)
                if (not self:hasCellDirectionsLeft(cell)) then
                    -- remove current cell from stack as it's finished for this one
                    cellMapIndexStack[availableCellsIndex] = cellMapIndexStack[cellMapIndexStackCount]
                    cellMapIndexStackCount = cellMapIndexStackCount - 1
                end

                cellMapIndexStack[cellMapIndexStackCount + 1] = {
                    index = cell.index + (distanceToCarve * directionStepOffset),
                    directionsDone = {
                        TOP = false,
                        RIGHT = false,
                        BOTTOM = false,
                        LEFT = false,
                    }
                }
                cellMapIndexStackCount = cellMapIndexStackCount + 1
            end

            i = i + 1

            if i > self.options.corridorsStep then
                corridorStepsAreDone = true
            end
        end
    end
end

---Runs the map generation
function MapGenerator:generate()
    self:initialiseMap()
    local elevatorMapIndex = self:placeElevator()
    self:carveCorridors(elevatorMapIndex)
    -- self:generateMaze()

    if (self.options.shouldCarveRoom) then
       -- self:carveRooms()
    end
end
