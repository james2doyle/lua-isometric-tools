local Vector = require("lib.vector")

---@class Map
---@field colCount number Number of columns in the map grid
---@field rowCount number Number of rows in the map grid
---@field heightMap {number:number} 2D array containing elevation values for each grid position
---@field tiles {string:number} Dictionary mapping Vector string representations to elevation values
---@field new fun(heightMap: table|nil, colCount: number|nil, rowCount: number|nil): Map Creates a new Map instance
---@field convertTo3D fun(self: Map, coord: Vector): Vector Converts a 2D coordinate to 3D with elevation
---@field enterable fun(self: Map, from: Vector, to: Vector, maxHeightDifference: number): boolean Checks if movement between positions is possible
---@field getNeighboursFor fun(self: Map, node: Vector, maxHeightDifference: number): {number:Vector} Gets valid neighboring positions
---@field dijkstra fun(self: Map, start: Vector): {string:number}, {string:number} Performs Dijkstra's pathfinding algorithm
---@field getPath fun(self: Map, previous: table, from: Vector, to: Vector): table|nil Reconstructs path from dijkstra results
---@field heuristicCostEstimate fun(self: Map, nodeA: Vector, nodeB: Vector): number Estimates cost between two nodes
---@field printDijkstra fun(self: Map, distances: table): nil Prints distances in a grid format

local Map = { __type = "Map" }
Map.__index = Map
setmetatable(Map, { __index = Map })

---Creates a new Map instance with specified dimensions and height data
---@param heightMap table|nil 2D array of elevation values for the map
---@param colCount number|nil Number of columns (required if heightMap is nil)
---@param rowCount number|nil Number of rows (required if heightMap is nil)
---@return Map New Map instance
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

---Converts a 2D coordinate to a 3D vector by adding elevation as Z component
---@param coord Vector The 2D coordinate to convert
---@return Vector 3D vector with elevation as Z component
function Map:convertTo3D(coord)
    ---@type number|nil
    local elevation = self.tiles[tostring(coord)]

    if elevation == nil then
        error("Could not find tile with key " .. tostring(coord))
    end

    return Vector.new(coord.x, coord.y, elevation)
end

---Determines if movement is possible between two positions based on height difference
---@param from Vector Starting position
---@param to Vector Target position
---@param maxHeightDifference number Maximum allowed elevation difference for movement
---@return boolean True if movement is possible, false otherwise
function Map:enterable(from, to, maxHeightDifference)
    local neighbourHeight = self.tiles[tostring(from)]
    local nodeHeight = self.tiles[tostring(to)] or 1

    return math.abs(neighbourHeight - nodeHeight) <= maxHeightDifference
end

---Gets all valid neighboring positions for a given node considering height constraints
---@param node Vector Position to find neighbors for
---@param maxHeightDifference number Maximum allowed elevation difference for movement
---@return {number:Vector} Array of valid neighboring positions
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

---Performs Dijkstra's pathfinding algorithm from a start position
---@param start Vector Starting position for pathfinding
---@return {string:number} distances Table of distances from start to all reachable positions
---@return {string:number} previous Table tracking the optimal path to each position
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
        if not current then
            break
        end

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
                -- add the height of the neighbour as part of the distance
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

---Reconstructs the optimal path between two points using Dijkstra results
---@param previous table Previous node lookup table from dijkstra algorithm
---@param from Vector Starting position
---@param to Vector Target position
---@return table|nil Array of positions forming the path, or nil if no path exists
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

---Estimates the cost between two nodes using distance heuristic
---@param nodeA Vector First position
---@param nodeB Vector Second position
---@return number Estimated cost between the positions
function Map:heuristicCostEstimate(nodeA, nodeB)
    return nodeA:distanceTo(nodeB)
end

---Prints the distance values from Dijkstra's algorithm in a grid format
---@param distances table Table of distances from dijkstra algorithm
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
