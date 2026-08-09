require("src/core/prng")
require("src/core/map")
require("src/generator/mapGenerator")

local seed = os.time()
---@type Map
local map = nil
local tileset = nil
local quadSet = nil
local tilesetCellSize = 16

---@type MapGenerator
local generator = nil

local isRKeyDown = false
local isCKeyDown = false
local isIKeyDown = false
local isMinusKeyDown = false
local isPlusKeyDown = false
local isWidthPlusKeyDown = false
local isWidthMinusKeyDown = false
local isHeightPlusKeyDown = false
local isHeightMinusKeyDown = false

local shouldDisplayIndices = false
local shouldCarveRoom = true
local carveRoomThreshold = 10
local mapWidth = 16
local mapHeight = 16
local mapMaxSize = 50
local mapMinSize = 3 -- 1 cell + 2 for borders

---run a map generation
local function runGeneration()
    local rand = Prng:new(seed)
    map = Map:new(mapWidth, mapHeight, 1)
    generator = MapGenerator:new(rand, map, {shouldCarveRoom = shouldCarveRoom, roomThreshold = carveRoomThreshold})
    generator:generate()
    print(map)
end

function love.load()
    love.graphics.setBackgroundColor(.5, .25, .75, 1)
    tileset = love.graphics.newImage("assets/tilemap-test.png")
    quadSet = {
        love.graphics.newQuad(0 * tilesetCellSize, 0, tilesetCellSize, tilesetCellSize, tilesetCellSize * 5, tilesetCellSize),
        love.graphics.newQuad(1 * tilesetCellSize, 0, tilesetCellSize, tilesetCellSize, tilesetCellSize * 5, tilesetCellSize),
        love.graphics.newQuad(2 * tilesetCellSize, 0, tilesetCellSize, tilesetCellSize, tilesetCellSize * 5, tilesetCellSize),
        love.graphics.newQuad(3 * tilesetCellSize, 0, tilesetCellSize, tilesetCellSize, tilesetCellSize * 5, tilesetCellSize),
        love.graphics.newQuad(4 * tilesetCellSize, 0, tilesetCellSize, tilesetCellSize, tilesetCellSize * 5, tilesetCellSize),

    }

    runGeneration()
end

function love.keypressed( key, scancode, isrepeat )
    print("key: " .. key .. " scancode: " ..scancode.. " isrepeat: " .. (isrepeat and "y" or "n"))
end

function love.update(dt)
    local isRDown = love.keyboard.isDown("r")
    local isCDown = love.keyboard.isDown("c")
    local isIDown = love.keyboard.isDown("i")
    local isMinusDown = love.keyboard.isDown("m")
    local isPlusDown = love.keyboard.isDown("p")

    local isWidthMinusDown = love.keyboard.isDown("q")
    local isWidthPlusDown = love.keyboard.isDown("d")
    local isHeightPlusDown = love.keyboard.isDown("z")
    local isHeightMinusDown = love.keyboard.isDown("s")

    if isRDown and not isRKeyDown then
        isRKeyDown = true
        seed = os.time()
        runGeneration()
    end
    if isCDown and not isCKeyDown then
        isCKeyDown = true
        shouldCarveRoom = not shouldCarveRoom
        runGeneration()
    end
    if isIDown and not isIKeyDown then
        isIKeyDown = true
        shouldDisplayIndices = not shouldDisplayIndices
    end
    if isMinusDown and (not isMinusKeyDown) and carveRoomThreshold > 3 then
        isMinusKeyDown = true
        carveRoomThreshold = carveRoomThreshold - 1
        shouldCarveRoom = true
        runGeneration()
    end
    if isPlusDown and (not isPlusKeyDown) and carveRoomThreshold < 50 then
        isPlusKeyDown = true
        carveRoomThreshold = carveRoomThreshold + 1
        shouldCarveRoom = true
        runGeneration()
    end

    if isWidthPlusDown and (not isWidthPlusKeyDown) and mapWidth < mapMaxSize then
        isWidthPlusKeyDown = true
        mapWidth = mapWidth + 1
        runGeneration()
    end

    if isWidthMinusDown and (not isWidthMinusKeyDown) and mapWidth > mapMinSize then
        isWidthMinusKeyDown = true
        mapWidth = mapWidth - 1
        runGeneration()
    end

    if isHeightPlusDown and (not isHeightPlusKeyDown) and mapHeight < mapMaxSize then
        isHeightPlusKeyDown = true
        mapHeight = mapHeight + 1
        runGeneration()
    end

    if isHeightMinusDown and (not isHeightMinusKeyDown) and mapHeight > mapMinSize then
        isHeightMinusKeyDown = true
        mapHeight = mapHeight - 1
        runGeneration()
    end

    isRKeyDown = isRDown
    isCKeyDown = isCDown
    isIKeyDown = isIDown
    isMinusKeyDown = isMinusDown
    isPlusKeyDown = isPlusDown
    isWidthPlusKeyDown = isWidthPlusDown
    isWidthMinusKeyDown = isWidthMinusDown
    isHeightPlusKeyDown = isHeightPlusDown
    isHeightMinusKeyDown = isHeightMinusDown
end

function love.draw()
    if not quadSet then return end

    local tileSizePx = 16
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local mapWidthPx = tileSizePx * map.width
    local mapHeightPx = (tileSizePx * map.height * map.depth)

    local originX = (windowWidth - mapWidthPx) / 2
    local originY = (windowHeight - mapHeightPx) / 2

    local stringToDisplay = {
        "seed: ".. seed,
        "(q/d) map width +/- (width".. (mapWidth) .. ")",
        "(z/s) map height +/- (height: ".. (mapHeight) .. ")",
        "",
        "togle (c)arve walls (" .. (shouldCarveRoom and "y" or "n") .. ")",
        "(p/m) carve wall threshold (".. (carveRoomThreshold) .. ")",
        "",
        "(r)efresh with new seed",
        "show (i)ndices (".. (shouldDisplayIndices and "y" or "n") .. ")"
    }
    for i = 1, #stringToDisplay do
        love.graphics.print(stringToDisplay[i], 16, 16 * i)
    end

    local i = 1
    --for z=1, map.depth do
        for y=1, map.height do
            local posY = originY + ((y - 1) * tileSizePx) -- + ((z - 1) * tileSizePx * map.height)
            for x=1, map.width do
                local posX = originX + ((x - 1) * tileSizePx)
                local mapCellReference = map.mapData[i].walls
                local mapIndex = map.mapData[i].index

                if mapCellReference == 9 then
                    mapCellReference = 4
                end

                local cell = quadSet[mapCellReference + 1]
                love.graphics.draw(tileset, cell, posX, posY)
                if shouldDisplayIndices then
                    love.graphics.setColor(0, 0, 0, 1)
                    love.graphics.print(mapIndex, posX, posY)
                    love.graphics.setColor(1, 1, 1, 1)
                end
                i = i + 1
            end
        end
    --end
end
