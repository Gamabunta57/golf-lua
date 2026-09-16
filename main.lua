require("src/data/map")
require("src/generators/generator")

local seed = os.time()

local CELL_SIZE = 6
local map = nil
local tileSet = nil
local generator = nil
local prng = love.math.random
local quads = {}

local maxStepCount = 5

local colors = {
    {0, 0, 0, 1}, -- Cell.LIMIT
    {.5, .5, .5, 1}, -- Cell.UNDEFINED
    {.75, .25, .5, 1}, -- Cell.ELEVATOR
    {1, 1, 1, 1}, -- Cell.CORRIDOR
}

local wasZPressed = false
local wasSPressed = false

function regenerateMap()
    map = Map:new(16, 16, 6)
    love.math.setRandomSeed(seed)
    generator = Generator:new(map, prng)
    generator:generateMap(maxStepCount)
end

function love.load()
    love.graphics.setBackgroundColor(.25, .25, .75, 1)
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
    if isZPressed and not wasZPressed then
        maxStepCount = maxStepCount + 1
        regenerateMap()
    end

    if isSPressed and not wasSPressed then
        maxStepCount = maxStepCount - 1
        regenerateMap()
    end

    wasZPressed = isZPressed
    wasSPressed = isSPressed
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
                love.graphics.setColor(colors[cell.tileRef])
                love.graphics.draw(tileSet, quads[1], origX + xOffset, origY + yOffset)
            end
        end
    end
end
