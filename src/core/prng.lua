---@class Prng
---@field seed number
---@private rng
Prng = {}
Prng.__index = Prng

---@ctor
---@param seed number intial seed for the prng
function Prng:new(seed)
    seed = seed or 0
    local rng = love.math.newRandomGenerator( seed )

    local o = {
        seed = seed,
        rng = rng
    }

    setmetatable(o, self)
    return o
end

---Get a random number within the given inclusive boundaries
---@param min number
---@param max number
---@return number
---@see https://www.love2d.org/wiki/love.math.random
function Prng:next(min, max)
    return self.rng:random(min, max)
end
