require("src/data/cell")

Anchors = {
    TO_TOP = 1,
    TO_RIGHT = 2,
    TO_BOTTOM = 3,
    TO_LEFT = 4,
}

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
    -- self:_buildFakeCorridors(maxStepCount)
    local anchorsLists = self:_setRoomAnchors()
    self:_placeRooms(anchorsLists)
end

function Generator:_placeRooms(anchorsLists)
    local width = self.map.width
    local height = self.map.height

    local roomIndex = 1 -- avoid 0 has it's the cell defaut value

    for z = 1, self.map.depth do
        local floorCells = self.map.floorCells[z]
        local floorAnchorsLists = anchorsLists[z]
        for l = #floorAnchorsLists, 1, -1 do
            local currentList = floorAnchorsLists[l]
            for i = 1, #currentList do
                local currentCellIndex = currentList[i]
                local currentCell = floorCells[currentCellIndex]

                local growthDirectionOffsets = self:_getGrowthDirectionOffsets(currentCell)

                if #growthDirectionOffsets == 0 then
                    self:_markSingleCellRoom(floorCells, currentCellIndex, roomIndex)
                    roomIndex = roomIndex + 1
                elseif #growthDirectionOffsets == 1 then
                    self:_growInSingleDirection(floorCells, currentCellIndex, growthDirectionOffsets[1], roomIndex)
                    roomIndex = roomIndex + 1
                elseif #growthDirectionOffsets == 2 then
                    self:_growInDiagonalDirection(floorCells, currentCellIndex, growthDirectionOffsets, roomIndex)
                    roomIndex = roomIndex + 1
                end
            end
        end
    end
end

function Generator:_getGrowthDirectionOffsets(currentCell)
    local growthDirectionOffsets = {}
    local anchor = currentCell.anchor
    local horizontalOffset = 0
    local verticalOffset = 0

    if (anchor.toLeft) then
        horizontalOffset = -1
    end
    if (anchor.toRight) then
        horizontalOffset = horizontalOffset + 1
    end
    if (anchor.toTop) then
        verticalOffset = -self.map.width
    end
    if (anchor.toBottom) then
        verticalOffset = verticalOffset + self.map.width
    end

    if not (horizontalOffset == 0) then
        growthDirectionOffsets[1] = horizontalOffset
    end

    if not (verticalOffset == 0) then
        growthDirectionOffsets[#growthDirectionOffsets +1 ] = verticalOffset
    end

    return growthDirectionOffsets
end

function Generator:_markSingleCellRoom(floorCells, cellIndex, roomIndex)
    local currentCell = floorCells[cellIndex]
    if currentCell.tileRef == Cell.UNDEFINED then -- in case of a growth of a room covered it
        currentCell.anchor = Cell.getEmptyAnchors()
        currentCell.tileRef = Cell.ROOM
        currentCell.roomIndex = roomIndex
    end
end

function Generator:_growInSingleDirection(floorCells, cellIndex, directionOffset, roomIndex)
    local currentCell = floorCells[cellIndex]
    while currentCell.tileRef == Cell.UNDEFINED do
        currentCell.anchor = Cell.getEmptyAnchors()
        currentCell.tileRef = Cell.ROOM
        currentCell.roomIndex = roomIndex
        cellIndex = cellIndex + directionOffset
        currentCell = floorCells[cellIndex]
    end
end

function Generator:_growInDiagonalDirection(floorCells, cellIndex, directionOffset, roomIndex)
    local firstDirection = directionOffset[1]
    local secondDirection = directionOffset[2]

    local currentCellIndexList = {}

    local sizeMaxInFirstDirection = 0
    local currentCellIndex = cellIndex
    local currentCell = floorCells[currentCellIndex]
    while currentCell.tileRef == Cell.UNDEFINED do
        sizeMaxInFirstDirection = sizeMaxInFirstDirection + 1
        currentCellIndex = currentCellIndex + firstDirection
        currentCell = floorCells[currentCellIndex]
    end

    local sizeMaxInSecondDirection = 0
    local canExpandInSecondDirection = true
    while canExpandInSecondDirection do
        for i = 0, sizeMaxInFirstDirection - 1 do
            if canExpandInSecondDirection then
                local currentCellIndex = cellIndex + (secondDirection * (sizeMaxInSecondDirection + 1)) + (firstDirection * i)
                if not (floorCells[currentCellIndex].tileRef == Cell.UNDEFINED) then
                    canExpandInSecondDirection = false
                end
            end
        end
        if canExpandInSecondDirection then
            sizeMaxInSecondDirection = sizeMaxInSecondDirection + 1
        end
    end

    for i = 0, sizeMaxInFirstDirection - 1 do
        local firstDirectionOffset = i * firstDirection
        for j = 0, sizeMaxInSecondDirection do
            local secondDirectionOffset = j * secondDirection
            local currentCellIndex = cellIndex + firstDirectionOffset + secondDirectionOffset

            local currentCell = floorCells[currentCellIndex]
            currentCell.anchor = Cell.getEmptyAnchors()
            currentCell.tileRef = Cell.ROOM
            currentCell.roomIndex = roomIndex
        end
    end
end

function Generator:_setRoomAnchors()
    local width = self.map.width
    local height = self.map.height

    local anchorsLists = {}

    for z = 1, self.map.depth do
        local floorCells = self.map.floorCells[z]
        anchorsLists[z] = {
            {}, -- index 1: zero growth direction anchor (4 direction anchors or 2 directions with only opposites)
            {}, -- index 2: single direction anchor
            {}, -- index 3: diagnoral direction anchor
        }
        for y = 1, height - 1 do
            for x = 1, width - 1 do

                local cellIndex = x + y * width

                local currentCell = floorCells[cellIndex]
                if currentCell.tileRef == Cell.UNDEFINED then
                    local leftCell = floorCells[cellIndex - 1]
                    local rightCell = floorCells[cellIndex + 1]
                    local topCell = floorCells[cellIndex - width]
                    local bottomCell = floorCells[cellIndex + width]
                    local anchorSet = false

                    -- next to a corridor or the elevator
                    if (topCell.tileRef == Cell.CORRIDOR or topCell.tileRef == Cell.ELEVATOR) then
                        self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_BOTTOM)
                        anchorSet = true
                    end
                    if (rightCell.tileRef == Cell.CORRIDOR or rightCell.tileRef == Cell.ELEVATOR) then
                        self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_LEFT)
                        anchorSet = true
                    end
                    if (bottomCell.tileRef == Cell.CORRIDOR or bottomCell.tileRef == Cell.ELEVATOR) then
                        self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_TOP)
                        anchorSet = true
                    end
                    if (leftCell.tileRef == Cell.CORRIDOR or leftCell.tileRef == Cell.ELEVATOR) then
                        self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_RIGHT)
                        anchorSet = true
                    end
                
                    -- next to a corridor or the elevator and next to the border
                    if (rightCell.tileRef == Cell.LIMIT) then 
                        if ((bottomCell.tileRef == Cell.CORRIDOR or bottomCell.tileRef == Cell.ELEVATOR) or (topCell.tileRef == Cell.CORRIDOR or topCell.tileRef == Cell.ELEVATOR)) then
                            self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_LEFT)
                            anchorSet = true
                        end
                    end

                    if (leftCell.tileRef == Cell.LIMIT) then 
                        if ((bottomCell.tileRef == Cell.CORRIDOR or bottomCell.tileRef == Cell.ELEVATOR) or (topCell.tileRef == Cell.CORRIDOR or topCell.tileRef == Cell.ELEVATOR)) then
                            self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_RIGHT)
                            anchorSet = true
                        end
                    end

                    if (topCell.tileRef == Cell.LIMIT) then 
                        if ((leftCell.tileRef == Cell.CORRIDOR or leftCell.tileRef == Cell.ELEVATOR) or (rightCell.tileRef == Cell.CORRIDOR or rightCell.tileRef == Cell.ELEVATOR)) then
                            self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_BOTTOM)
                            anchorSet = true
                        end
                    end

                    if (bottomCell.tileRef == Cell.LIMIT) then 
                        if ((leftCell.tileRef == Cell.CORRIDOR or leftCell.tileRef == Cell.ELEVATOR) or (rightCell.tileRef == Cell.CORRIDOR or rightCell.tileRef == Cell.ELEVATOR)) then
                            self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_TOP)
                            anchorSet = true
                        end
                    end


                    -- in a corner
                    if (topCell.tileRef == Cell.LIMIT and rightCell.tileRef == Cell.LIMIT) then 
                        if ((bottomCell.tileRef == Cell.CORRIDOR or bottomCell.tileRef == Cell.ELEVATOR) or (leftCell.tileRef == Cell.CORRIDOR or leftCell.tileRef == Cell.ELEVATOR)) then
                            self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_BOTTOM)
                            self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_LEFT)
                            anchorSet = true
                        end
                    end

                    if (rightCell.tileRef == Cell.LIMIT and bottomCell.tileRef == Cell.LIMIT) then 
                        if ((leftCell.tileRef == Cell.CORRIDOR or leftCell.tileRef == Cell.ELEVATOR) or (topCell.tileRef == Cell.CORRIDOR or topCell.tileRef == Cell.ELEVATOR)) then
                            self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_LEFT)
                            self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_TOP)
                            anchorSet = true
                        end
                    end

                    if (bottomCell.tileRef == Cell.LIMIT and leftCell.tileRef == Cell.LIMIT) then 
                        if ((topCell.tileRef == Cell.CORRIDOR or topCell.tileRef == Cell.ELEVATOR) or (rightCell.tileRef == Cell.CORRIDOR or rightCell.tileRef == Cell.ELEVATOR)) then
                            self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_TOP)
                            self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_RIGHT)
                            anchorSet = true
                        end
                    end

                    if (leftCell.tileRef == Cell.LIMIT and topCell.tileRef == Cell.LIMIT) then 
                        if ((rightCell.tileRef == Cell.CORRIDOR or rightCell.tileRef == Cell.ELEVATOR) or (bottomCell.tileRef == Cell.CORRIDOR or bottomCell.tileRef == Cell.ELEVATOR)) then
                            self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_RIGHT)
                            self:_placeAnchorAt(floorCells, cellIndex, Anchors.TO_BOTTOM)
                            anchorSet = true
                        end
                    end

                    if anchorSet then
                        local directions = self:_getGrowthDirectionOffsets(currentCell)
                        local anchorsList = anchorsLists[z][#directions + 1]
                        anchorsList[#anchorsList + 1] = cellIndex
                    end
                end
            end
        end
    end
    return anchorsLists
end

function Generator:_placeAnchorAt(floorCells, cellIndex, anchorDirection)
    if anchorDirection == Anchors.TO_TOP then
        floorCells[cellIndex].anchor.toTop = true
    elseif anchorDirection == Anchors.TO_RIGHT then
        floorCells[cellIndex].anchor.toRight = true
    elseif anchorDirection == Anchors.TO_BOTTOM then
        floorCells[cellIndex].anchor.toBottom = true
    elseif anchorDirection == Anchors.TO_LEFT then
        floorCells[cellIndex].anchor.toLeft = true
    end
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

function Generator:_buildFakeCorridors(maxStepCount)
    -- force elevator to the center
    local width = self.map.width
    local height = self.map.height

    local centerIndex = math.ceil(width * height / 2)
    local corridorIndex = centerIndex + width

    self.map.floorCells[1][centerIndex].tileRef = Cell.ELEVATOR
    self.map.floorCells[1][corridorIndex].tileRef = Cell.CORRIDOR

    local distanceToCarveCorridor = (width / 2) - 3
    for i = 1, distanceToCarveCorridor do
        self.map.floorCells[1][corridorIndex + i].tileRef = Cell.CORRIDOR
        self.map.floorCells[1][corridorIndex - i].tileRef = Cell.CORRIDOR
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
