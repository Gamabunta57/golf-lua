---@class Cell
---@field walls number the set of wall the Cell is composed of
---@field index number an index marked by the map generator
Cell = {
    CELL_WALL_NONE = 0x00,
    CELL_WALL_RIGHT = 0x01,
    CELL_WALL_BOTTOM = 0x02,
    CELL_WALL_ALL = 0x03, -- CELL_WALL_RIGHT | CELL_WALL_BOTTOM

    -- minus numbers to block path
    CELL_WALL_BLOCKED = -2,
    CELL_UNWALKED = -1,
}
Cell.__index = Cell

---@ctor
function Cell:new()
    local o = {
        walls = Cell.CELL_WALL_ALL,
        index = Cell.CELL_UNWALKED,
    }
    setmetatable(o, Cell)
    return o
end
