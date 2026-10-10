GraphNode = {
}

GraphNode.__index = GraphNode

function GraphNode:new(name)
    local o = {
        name = name or "no-name",
        linkedTo = {},
        pathTo = {},
        browsed = false
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function GraphNode:connect(other)
    self.linkedTo[#(self.linkedTo) + 1] = other
end
