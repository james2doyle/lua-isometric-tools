local Vector = require 'lib.vector'
local fp = require 'lib.fp'

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
    local nodeHeight = self.tiles[tostring(to)]

    return math.abs(neighbourHeight - nodeHeight) <= maxHeightDifference
end

---@param node Vector
---@param maxHeightDifference number
---@return {number:Vector}
function Map:getNeighboursFor(node, maxHeightDifference)
    local matches = {}

    debug.debug()

    for _, v in pairs(node:neighbours()) do
        local exists = self.tiles[tostring(v)]

        if exists ~= nil then
          table.insert(matches, v)
        end
    end

    local canEnter = {}
    for _, match in pairs(matches) do
        if self:enterable(match, node, maxHeightDifference) then
          table.insert(canEnter, node)
        end
    end

    return canEnter
end

---@param from Vector
---@param to Vector
---@return number
function Map:cost(from, to)
    return math.abs(self.tiles[tostring(from)] - self.tiles[tostring(to)]) + 1
end

local function createSortedTable(originalTable, keyFunction)
    -- Create a copy of the original table
    local sortedTable = {}

    -- Copy all elements from the original table to the sorted table
    for _, value in ipairs(originalTable) do
        table.insert(sortedTable, value)
    end

    -- Sort the copied table using the provided key function
    table.sort(sortedTable, function(a, b)
        return keyFunction(a, b)
    end)

    return sortedTable
end

---@param input table
---@param predicate function
---@return table
local function filter(input, predicate)
  local out = {}

  for k, v in ipairs(input) do
    if predicate(v, k, input) then
      out[k] = v
    end
  end

  return out
end

---@param target Vector
---@param maxHeightDifference number
---@return {string:number}
function Map:dijkstra(target, maxHeightDifference)
    local targetName = tostring(target)

    ---@type {string:Vector}
    local unvisited = { [targetName] = target }
    ---@type {string:boolean}
    local visited = {}
    ---@type {string:number}
    local dist = { [targetName] = 0 }

    -- local currentNode = target
    -- local currentName = tostring(targetName)

    -- while fp.length(true)(unvisited) ~= 0 do
    --     local neighbours = self:getNeighboursFor(currentNode, maxHeightDifference)

    --     for _, neighbour in pairs(neighbours) do
    --         local neighbourName = tostring(neighbour)
    --         if visited[neighbourName] == nil then
    --             unvisited[neighbourName] = neighbour
    --         end

    --         local height = dist[currentName] + self:cost(currentNode, neighbour)

    --         if height < dist[neighbourName] then
    --           dist[neighbourName] = height
    --         end
    --     end

    --     unvisited[currentName] = nil
    --     visited[currentName] = true

    --     local sortedNodes = createSortedTable(unvisited, function(a, b)
    --         return dist[tostring(a)] < dist[tostring(b)]
    --     end)

    --     local newNode = table.remove(sortedNodes, 1)

    --     currentNode = newNode
    --     currentName = tostring(currentNode)
    -- end

    return dist
end

return Map
