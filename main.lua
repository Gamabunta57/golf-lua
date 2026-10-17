require("src/data/map")
require("src/generators/generator")

local seed = os.time()

local CELL_SIZE = 16
local map = nil
local tileSet = nil
local generator = nil
local prng = love.math.random
local quads = {}

local drawIndices = false
local fusionLevel = 2
local drawWithWalls = true

local colors = {
    {0, 0, 0, 1}, -- Cell.LIMIT
    {1, 0, 1, 1}, -- Cell.UNDEFINED
    {1, .5, .25, 1}, -- Cell.ELEVATOR
    {1, 1, 1, 1}, -- Cell.CORRIDOR
    {1, 1, 1, .5}, -- Cell.ROOM
    {.5, .75, .25, 1}, -- Cell.hasAnchor // 1
    {.25, 1, .15, 1}, -- Cell.hasAnchor // 2
    {.15, 1, 1, 1}, -- Cell.hasAnchor // 3
    {1, 1, 0, 1}, -- Cell.hasAnchor // 4
}

local roomColors = {
    {0, 0, .5, 1},
    {0, .5, 0, 1},
    {.5, 0, 0, 1},
    {.5, .5, 0, 1},
    {.5, 0, .5, 1},
    {0, .5, .5, 1},

    {0, 0, .5, .75},
    {0, .5, 0, .75},
    {.5, 0, 0, .75},
    {.5, .5, 0, .75},
    {.5, 0, .5, .75},
    {0, .5, .5, .75},

    {0, 0, .5, .5},
    {0, .5, 0, .5},
    {.5, 0, 0, .5},
    {.5, .5, 0, .5},
    {.5, 0, .5, .5},
    {0, .5, .5, .5},

    {0, 0, .5, .25},
    {0, .5, 0, .25},
    {.5, 0, 0, .25},
    {.5, .5, 0, .25},
    {.5, 0, .5, .25},
    {0, .5, .5, .25},
}

local wasZPressed = false
local wasSPressed = false
local wasRPressed = false
local wasCPressed = false
local wasFPressed = false
local wasDPressed = false

function regenerateMap()
    map = Map:new(16, 16, 4)
    love.math.setRandomSeed(seed)
    generator = Generator:new(map, prng)
    generator:generateMap(fusionLevel)
end

function love.load()
    love.graphics.setBackgroundColor(.15, .15, .15, 1)
    tileSet = love.graphics.newImage("assets/images/tileset.png")
    quads[1] = love.graphics.newQuad(0, 0, CELL_SIZE, CELL_SIZE, tileSet)
    quads[2] = love.graphics.newQuad(16, 0, CELL_SIZE, CELL_SIZE, tileSet)
    quads[3] = love.graphics.newQuad(32, 0, CELL_SIZE, CELL_SIZE, tileSet)
    quads[4] = love.graphics.newQuad(48, 0, CELL_SIZE, CELL_SIZE, tileSet)
    quads[5] = love.graphics.newQuad(64, 0, CELL_SIZE, CELL_SIZE, tileSet)
    quads[6] = love.graphics.newQuad(80, 0, CELL_SIZE, CELL_SIZE, tileSet)
    quads[7] = love.graphics.newQuad(96, 0, CELL_SIZE, CELL_SIZE, tileSet)
    quads[8] = love.graphics.newQuad(112, 0, CELL_SIZE, CELL_SIZE, tileSet)

    regenerateMap()
end

function love.keypressed( key, scancode, isrepeat )
    print("key: ", key, "scancode: ", scancode, "isrepeat: ", (isrepeat and "y" or "n"))
end

function love.update(dt)
    local isRPressed = love.keyboard.isDown("r")
    local isCPressed = love.keyboard.isDown("c")
    local isFPressed = love.keyboard.isDown("f")
    local isDPressed = love.keyboard.isDown("d")

    if isRPressed and not wasRPressed then
        -- seed = os.time()
        seed = seed + 1
        regenerateMap()
    end

    if isCPressed and not wasCPressed then
        drawIndices = not drawIndices
    end

    if isFPressed and not wasFPressed then
        fusionLevel = (fusionLevel + 1) % 3
        regenerateMap()
    end

    if isDPressed and not wasDPressed then
        drawWithWalls = not drawWithWalls
        
    end

    wasZPressed = isZPressed
    wasSPressed = isSPressed
    wasRPressed = isRPressed
    wasCPressed = isCPressed
    wasFPressed = isFPressed
    wasDPressed = isDPressed
end

function love.draw()
    local floorHeightPx = map.height * CELL_SIZE
    local floorWidthPx = map.width * CELL_SIZE

    local width, height = love.graphics.getDimensions()

    local maxFloorDisplayOn1Column = math.floor(height / floorHeightPx)
    local columnCountToDisplay = math.ceil(map.depth / maxFloorDisplayOn1Column)

    local columnHeightPx = floorHeightPx * maxFloorDisplayOn1Column

    local origX = width / 2 - (columnCountToDisplay * floorWidthPx / 2)
    local origY = height / 2 - (columnHeightPx / 2)

    local currentOriginX = origX
    local currentOriginY = origY

    local floorDisplayedInColumn = 0

    for z = 1, map.depth do

        local floorCells = map.floorCells[z];

        if drawWithWalls then
            displayFloorWithWalls(floorCells, map.width, map.height, currentOriginX, currentOriginY)
            displayFloorRoomNames(map.roomLists[z], currentOriginX, currentOriginY)
        else
            displayFloor(floorCells, map.width, map.height, currentOriginX, currentOriginY)
        end
        
        
        floorDisplayedInColumn = floorDisplayedInColumn + 1
        currentOriginY = currentOriginY + floorHeightPx

        if (floorDisplayedInColumn >= maxFloorDisplayOn1Column) then
            floorDisplayedInColumn = 0
            currentOriginX = currentOriginX + floorWidthPx
            currentOriginY = origY
        end
    end

    -- draw quick UI
    local strings = {
        "(r) regenerate",
        "(d) draw color or walls: " .. (drawWithWalls and "wall" or "colors"),
        "(f) fusion mode:" .. ((fusionLevel == 2 and "full") or (fusionLevel == 1 and "shared edges") or "none"),
        "(c) show cell room indices: " .. (drawIndices and "Yes" or "No"),
    }

    love.graphics.setColor({1, 1, 1, 1})
    for i = 1, #strings do
        local s = strings[i]
        love.graphics.print(s, 16, i * 16)
    end
end

function displayFloor(floorCells, width, height, origX, origY, lastDisplayedRoom)
    local i = 0
    for y = 0, (height - 1) do
        local yOffset = y * CELL_SIZE + origY
        for x = 0, (width - 1) do
            local xOffset = x * CELL_SIZE + origX
            i = i + 1

            local cell = floorCells[i]
            local anchorCount = cell:anchorCount()

            if cell.tileRef == Cell.ROOM then
                love.graphics.setColor(roomColors[(cell.roomIndex % #roomColors) + 1])
            elseif anchorCount == 1 then
                love.graphics.setColor(colors[6])
            elseif anchorCount == 2 then
                love.graphics.setColor(colors[7])
            elseif anchorCount == 3 then
                love.graphics.setColor(colors[8])
            elseif anchorCount == 4 then
                love.graphics.setColor(colors[9])
            else
                love.graphics.setColor(colors[cell.tileRef])
            end
            love.graphics.draw(tileSet, quads[1], xOffset, yOffset)
            if drawIndices then
                love.graphics.setColor(0, 0, 0, 1)
                love.graphics.print(cell.roomIndex, xOffset, yOffset, 0, .6, .6)
            end
        end
    end
end

function displayFloorWithWalls(floorCells, width, height, origX, origY, lastDisplayedRoom)
    local i = 0
    for y = 0, (height - 1) do
        local yOffset = y * CELL_SIZE + origY
        for x = 0, (width - 1) do
            local xOffset = x * CELL_SIZE + origX
            i = i + 1

            local cell = floorCells[i]
            love.graphics.setColor(colors[cell.tileRef])
            love.graphics.draw(tileSet, quads[cell.wallRef], xOffset, yOffset)
            if drawIndices then
                love.graphics.setColor(0, 0, 0, 1)
                love.graphics.print(cell.roomIndex, xOffset, yOffset, 0, .6, .6)
            end

            if not (cell.openings == Cell.NO_OPENINGS) then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(tileSet, quads[cell.openings + 4], xOffset, yOffset)
            end
        end
    end
end

function displayFloorRoomNames(roomList, origX, origY)
    love.graphics.setColor(0, 0, 0, 1)
    for rI = 1, #roomList do
        local room = roomList[rI]
        local xOffset = origX + (room.x - 1) * CELL_SIZE
        local yOffset = origY + (room.y - 1) * CELL_SIZE
        love.graphics.print(room.name or rI, xOffset, yOffset, 0, .6, .6)
    end
end