require("src/data/map")
require("src/generators/generator")

local seed = os.time()

local CELL_SIZE = 12
local map = nil
local tileSet = nil
local generator = nil
local prng = love.math.random
local quads = {}

local maxStepCount = 250

local displayCorridors = true
local fusionLevel = 2

local colors = {
    {0, 0, 0, 1}, -- Cell.LIMIT
    {1, 0, 1, 1}, -- Cell.UNDEFINED
    {1, .5, .25, 1}, -- Cell.ELEVATOR
    {1, 1, 1, 1}, -- Cell.CORRIDOR
    {1, 0, 1, 1}, -- Cell.ROOM
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

function regenerateMap()
    map = Map:new(12, 12, 12)
    love.math.setRandomSeed(seed)
    generator = Generator:new(map, prng)
    generator:generateMap(maxStepCount, fusionLevel)
end

function love.load()
    love.graphics.setBackgroundColor(.15, .15, .15, 1)
    tileSet = love.graphics.newImage("assets/images/tileset.png")
    quads[1] = love.graphics.newQuad(0, 0, CELL_SIZE, CELL_SIZE, 0, 0)

    regenerateMap()
end

function love.keypressed( key, scancode, isrepeat )
    print("key: ", key, "scancode: ", scancode, "isrepeat: ", (isrepeat and "y" or "n"))
end

function love.update(dt)
    local isZPressed = love.keyboard.isDown("z")
    local isSPressed = love.keyboard.isDown("s")
    local isRPressed = love.keyboard.isDown("r")
    local isCPressed = love.keyboard.isDown("c")
    local isFPressed = love.keyboard.isDown("f")
    if isZPressed and not wasZPressed then
        maxStepCount = maxStepCount + 1
        regenerateMap()
    end

    if isSPressed and not wasSPressed then
        maxStepCount = maxStepCount - 1
        regenerateMap()
    end

    if isRPressed and not wasRPressed then
        seed = os.time()
        regenerateMap()
    end

    if isCPressed and not wasCPressed then
        displayCorridors = not displayCorridors
    end

    if isFPressed and not wasFPressed then
        fusionLevel = (fusionLevel + 1) % 3
        regenerateMap()
    end

    wasZPressed = isZPressed
    wasSPressed = isSPressed
    wasRPressed = isRPressed
    wasCPressed = isCPressed
    wasFPressed = isFPressed
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

        displayFloor(floorCells, map.width, map.height, currentOriginX, currentOriginY)
        
        floorDisplayedInColumn = floorDisplayedInColumn + 1
        currentOriginY = currentOriginY + floorHeightPx

        if (floorDisplayedInColumn >= maxFloorDisplayOn1Column) then
            floorDisplayedInColumn = 0
            currentOriginX = currentOriginX + floorWidthPx
            currentOriginY = origY
        end
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
            local drawIndex = false
            if cell.tileRef == Cell.ROOM then
                love.graphics.setColor(roomColors[(cell.roomIndex % #roomColors) + 1])
                drawIndex = true
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
            if drawIndex or not displayCorridors then
                love.graphics.setColor(0, 0, 0, 1)
                -- love.graphics.print(cell.roomIndex, xOffset, yOffset)
            end
        end
    end
end