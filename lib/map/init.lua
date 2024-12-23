local Vector = require 'lib.vector'

---@class Map
---@field colCount number
---@field rowCount number
---@field heightMap {number:number}
---@field tiles {string:number}
---@field convertTo3D Map:convertTo3D
---@field enterable Map:enterable
---@field getNeighboursFor Map:getNeighboursFor
---@field cost Map:cost
---@field dijkstra Map:dijkstra
---@field heuristicCostEstimate Map:heuristicCostEstimate
---@field printDijkstra Map:printDijkstra

local Map = { __type = "Map" }
Map.__index = Map;
setmetatable(Map, { __index = Map })

---@param heightMap table|nil
---@param colCount number|nil
---@param rowCount number|nil
---@return Map
function Map.new(heightMap, colCount, rowCount)
    local this = {}
    this.heightMap = heightMap or {}

    if heightMap == nil then
        this.rowCount = rowCount or 0
        this.colCount = colCount or 0
    else
        this.rowCount = rowCount or #heightMap
        this.colCount = #heightMap[1]
    end

    local tiles = {}

    for row = 1, this.rowCount do
        for col = 1, this.colCount do
            local elevation = this.heightMap[row][col]
            local vec = Vector.new(col - 1, row - 1)
            tiles[tostring(vec)] = elevation
        end
    end

    this.tiles = tiles

    setmetatable(this, Map)

    return this
end

---@param coord Vector
---@return Vector
function Map:convertTo3D(coord)
    ---@type number|nil
    local elevation = self.tiles[tostring(coord)]

    if elevation == nil then
        error("Could not find tile with key " .. tostring(coord))
    end

    return Vector.new(coord.x, coord.y, elevation)
end

---@param from Vector
---@param to Vector
---@param maxHeightDifference number
---@return boolean
function Map:enterable(from, to, maxHeightDifference)
    local neighbourHeight = self.tiles[tostring(from)]
    local nodeHeight = self.tiles[tostring(to)] or 1

    return math.abs(neighbourHeight - nodeHeight) <= maxHeightDifference
end

---@param node Vector
---@param maxHeightDifference number
---@return {number:Vector}
function Map:getNeighboursFor(node, maxHeightDifference)
    local matches = {}

    for _, v in pairs(node:neighbours()) do
        local exists = self.tiles[tostring(v)]

        if exists ~= nil then
            table.insert(matches, v)
        end
    end

    local canEnter = {}
    for _, match in pairs(matches) do
        if self:enterable(match, node, maxHeightDifference) then
            table.insert(canEnter, match)
        end
    end

    return canEnter
end

---@param start Vector
---@return {string:number} {string:number}
function Map:dijkstra(start)
    ---@type {string:number}
    local distances = {}
    ---@type {string:number}
    local previous = {}
    ---@type {string:boolean}
    local unvisited = {}

    -- Set initial distances to infinity and add all nodes to unvisited set
    for vecKey, _ in pairs(self.tiles) do
        distances[vecKey] = math.huge
        previous[vecKey] = nil
        unvisited[vecKey] = true
    end

    local startName = tostring(start)

    -- Set distance to start node as 0
    distances[startName] = 0

    -- Main algorithm loop
    while next(unvisited) do
        -- Find unvisited node with minimum distance
        local minDist = math.huge
        local current = nil
        for nodeStr, _ in pairs(unvisited) do
            if distances[nodeStr] < minDist then
                minDist = distances[nodeStr]
                current = nodeStr
            end
        end

        -- If no reachable unvisited nodes remain, break
        if not current then break end

        -- Remove current node from unvisited set
        unvisited[current] = nil

        --- Get current node coordinates
        local currentVec = Vector.fromKey(current)

        -- Update distances to neighbours
        for _, neighbour in pairs(self:getNeighboursFor(currentVec, math.huge)) do
            local neighborStr = tostring(neighbour)
            if unvisited[neighborStr] then
                local newNeighbor = Vector.fromKey(neighborStr)
                local weight = currentVec:distanceTo(newNeighbor)
                local newDist = math.abs(distances[current] + weight + self.tiles[neighborStr] - 1)

                if newDist < distances[neighborStr] then
                    distances[neighborStr] = newDist
                    previous[neighborStr] = current
                end
            end
        end
    end

    return distances, previous
end

-- Helper function to reconstruct path from start to end node
function Map:getPath(previous, from, to)
    local path = {}

    local current = tostring(to)
    local start = tostring(from)

    while current do
        table.insert(path, 1, current)
        current = previous[current]
    end

    -- Check if path exists (starts with start node)
    if not path[1] or path[1] ~= start then
        return nil -- No path exists
    end

    return path
end

---@param nodeA Vector
---@param nodeB Vector
---@return number
function Map:heuristicCostEstimate(nodeA, nodeB)
    return nodeA:distanceTo(nodeB)
end

---@param distances table
function Map:printDijkstra(distances)
    for y = 1, self.rowCount do
        local line = ""
        for x = 1, self.colCount do
            local vec = Vector.new(x - 1, y - 1)
            if distances[tostring(vec)] == nil then
                line = line .. "X"
            else
                line = line .. distances[tostring(vec)] .. " "
            end
        end
        print(line)
    end
end

return Map
