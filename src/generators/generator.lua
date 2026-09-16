require("src/data/cell")

Generator = {
    CORRIDOR_RATIO = .12,
}
Generator.__index = Generator

function Generator:new(map, prng)
    local o = {
        map = map,
        prng = prng
    }

    setmetatable(o, self)
    return o
end

function Generator:generateMap(maxStepCount)
    self:_initialise()
    self:_buildCorridors(maxStepCount)
end

function Generator:_initialise()
    local width = self.map.width
    local height = self.map.height
    local floorCount = self.map.depth

    local lastRowOffset = width * (height - 1)

    for z = 1, floorCount do
        for x = 1, width do
            self.map.floorCells[z][x].tileRef = Cell.LIMIT
            self.map.floorCells[z][x + lastRowOffset].tileRef = Cell.LIMIT
        end

        for y = 1, height - 1 do
            local yOffset = y  * width
            self.map.floorCells[z][yOffset].tileRef = Cell.LIMIT
            self.map.floorCells[z][yOffset + 1].tileRef = Cell.LIMIT
        end
    end
end

function Generator:_buildCorridors(maxStepCount)
    local corridorStartingIndex = self:_placeElevator()
    local corridorTargetRatio = self.map.width * self.map.height * self.CORRIDOR_RATIO

    local stepCount = 0

    for z = 1, self.map.depth do
        local corridorStartCells = {corridorStartingIndex}
        local corridorStartCellsCount = 1
        local floorCells = self.map.floorCells[z]
        local corridorCellCount = 1

        while corridorCellCount < corridorTargetRatio and stepCount < maxStepCount do
            local pickedCellIndex = self.prng(1, corridorStartCellsCount)
            local pickedCellMapIndex = corridorStartCells[pickedCellIndex]
            local availableDirections = self:_getCellAvailableDirections(floorCells, pickedCellMapIndex)
            if #availableDirections > 0 then
                local pickedDirection = availableDirections[self.prng(1, #availableDirections)]
                local distanceMaxInDirection = self:_getMaxDistanceFromCellInDirection(floorCells, pickedCellMapIndex, pickedDirection)

                if (distanceMaxInDirection > 0) then
                    local distanceToGo = self.prng(1, distanceMaxInDirection)

                    for i = 1, distanceToGo do
                        local step = i * pickedDirection
                        floorCells[pickedCellMapIndex + step].tileRef = Cell.CORRIDOR
                        corridorCellCount = corridorCellCount + 1
                    end

                    corridorStartCells[#corridorStartCells + 1] = pickedCellMapIndex + pickedDirection * distanceToGo
                end
            else
                table.remove(corridorStartCells, pickedCellIndex)
            end

            stepCount = stepCount + 1
        end
    end    
end

function Generator:_getMaxDistanceFromCellInDirection(floorCells, cellIndex, stepInDirection)
    local maxDistance = 0
    local cellIndex = cellIndex + stepInDirection
    local nextCell = floorCells[cellIndex]

    while nextCell.tileRef == Cell.UNDEFINED do
        maxDistance = maxDistance + 1
        cellIndex = cellIndex + stepInDirection
        nextCell = floorCells[cellIndex]
    end

    return maxDistance
end

function Generator:_getCellAvailableDirections(floorCells, cellIndex)
    local topCellIndex = cellIndex - self.map.width
    local bottomCellIndex = cellIndex + self.map.width
    local leftCellIndex = cellIndex - 1
    local rightCellIndex = cellIndex + 1

    local directions = {}

    if floorCells[topCellIndex].tileRef == Cell.UNDEFINED then
        directions[1] = -self.map.width
    end
    if floorCells[bottomCellIndex].tileRef == Cell.UNDEFINED then
        directions[#directions + 1] = self.map.width
    end
    if floorCells[leftCellIndex].tileRef == Cell.UNDEFINED then
        directions[#directions + 1] = -1
    end
    if floorCells[rightCellIndex].tileRef == Cell.UNDEFINED then
        directions[#directions + 1] = 1
    end

    return directions
end

function Generator:_placeElevator()
    local minWidth = 3
    local minHeight = 3
    local maxWidth = self.map.width - 2
    local maxHeight = self.map.height - 3

    local xCoord = self.prng(minWidth, maxWidth)
    local yCoord = self.prng(minHeight, maxHeight)

    local floorCoord = yCoord * self.map.width + xCoord
    
    local nextRowCell = floorCoord + self.map.width

    for z = 1, self.map.depth do
        self.map.floorCells[z][floorCoord].tileRef = Cell.ELEVATOR
        self.map.floorCells[z][nextRowCell].tileRef = Cell.CORRIDOR
    end

    return nextRowCell
end
