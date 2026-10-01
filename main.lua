require("src/data/map")
require("src/generators/generator")

local seed = os.time()

local CELL_SIZE = 18
local map = nil
local tileSet = nil
local generator = nil
local prng = love.math.random
local quads = {}

local maxStepCount = 5

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
    {0, 0, .25, .3},
    {0, .25, 0, .3},
    {.25, 0, 0, .3},
    {.25, .25, 0, .3},

    {0, 0, .5, .3},
    {0, .5, 0, .3},
    {.75, 0, 0, .3},
    {.5, .5, 0, .3},

    {0, 0, .75, .3},
    {0, .75, 0, .3},
    {.5, 0, 0, .3},
    {.75, .75, 0, .3},

    {0, 0, 1, .3},
    {0, 1, 0, .3},
    {1, 0, 0, .3},
    {1, .25, .15, .3},
}

local wasZPressed = false
local wasSPressed = false
local wasRPressed = false

function regenerateMap()
    map = Map:new(15, 15, 3)
    love.math.setRandomSeed(seed)
    generator = Generator:new(map, prng)
    generator:generateMap(maxStepCount)
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

    wasZPressed = isZPressed
    wasSPressed = isSPressed
    wasRPressed = isRPressed
end

function love.draw()
    local floorHeightPx = map.height * CELL_SIZE
    local origX = love.graphics.getWidth() / 2 - (map.width * CELL_SIZE / 2)
    local origY = love.graphics.getHeight() / 2 - (floorHeightPx * map.depth / 2)

    for z = 1, map.depth do
        local i = 0
        for y = 0, (map.height - 1) do
            local yOffset = y * CELL_SIZE + floorHeightPx * (z - 1)
            for x = 0, (map.width - 1) do
                local xOffset = x * CELL_SIZE
                i = i + 1

                local cell = map.floorCells[z][i]
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
                love.graphics.draw(tileSet, quads[1], origX + xOffset, origY + yOffset)
            end
        end
    end
end
