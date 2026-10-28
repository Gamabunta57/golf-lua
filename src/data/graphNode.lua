GraphNode = {
}

GraphNode.__index = GraphNode

function GraphNode:new(name)
    local o = {
        name = name or "no-name",
        location = {
            floor = 0,
            roomIndex = 0,
        },
        linkedTo = {},
        pathTo = {},
        browsed = false,
        isCorridor = false,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function GraphNode:connect(other)
    self.linkedTo[#(self.linkedTo) + 1] = other
end

function GraphNode:isPhysicallyConnectedTo(other)
    for _, node in ipairs(self.pathTo) do
        if (node == other) then
            return true
        end
    end
    return false
end
