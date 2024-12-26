---
---The TileMap class represents a 2D grid of tiles that can be manipulated and queried.
---It provides functionality for tile movement, area selection, and event handling.
---
---Example usage:
---```lua
---local map = TileMap.new("Level1", tiles, 1, {
---    select = function(tile) print("Selected:", tile) end
---})
---```

local Vector = require("lib.vector")
local Tile = require("lib.tile")

local TileMap = { __type = "TileMap" }
TileMap.__index = TileMap

---@class TileMapEvents
local TileMapEvents = {
    --- Trigger a tile
    ---@param this TileMap
    select = function(this)
        this:trigger("log", "select", this)
    end,

    -- System events
    ---@param this TileMap
    load = function(this)
        this:trigger("log", "load", this)
    end,
    ---@param this TileMap
    loadTexture = function(this)
        this:trigger("log", "loadTexture", this)
    end,
    ---@param this TileMap
    unload = function(this)
        this:trigger("log", "unload", this)
    end,
    ---@param this TileMap
    beforeUpdate = function(this)
        this:trigger("log", "beforeUpdate", this)
    end,
    ---@param this TileMap
    update = function(this)
        this:trigger("log", "update", this)
    end,
    ---@param this TileMap
    afterUpdate = function(this)
        this:trigger("log", "afterUpdate", this)
    end,
    ---@param this TileMap
    beforeDraw = function(this)
        this:trigger("log", "beforeDraw", this)
    end,
    ---@param this TileMap
    draw = function(this)
        this:trigger("log", "draw", this)
    end,
    ---@param this TileMap
    afterDraw = function(this)
        this:trigger("log", "afterDraw", this)
    end,
    ---@param ... any # details to log
    log = function(...)
        -- print("tilemap log", table.unpack(arg))
        print("tilemap log", ...)
    end,
}

---@class TileMap
---@field visible boolean Whether the tile map is currently visible
---@field name string Label for this tile map
---@field tiles Tile[] List of Tile elements in this map
---@field zIndex number The layer/depth this tile map renders at
---@field events table<string, function> Table of event callbacks
---@field new fun(name?: string, tiles: Tile[], zIndex?: number, events?: TileMapEvents): TileMap Creates a new TileMap instance
---@field on fun(self: TileMap, event: string, callback: fun(self: TileMap, ...any)) Register a callback function for a specific event
---@field trigger fun(self: TileMap, event: string, ...any): any?, nil|string? Trigger a specific event on the tile map with optional additional arguments
---@field tileLineFrom fun(self:TileMap, tile: Tile, direction, distance)
---@field findTileAt fun(self:TileMap, coordsOrX: Vector|number, y?: number): Tile|nil
---@field tileRadiusWithin fun(self:TileMap, tile: Tile, radius: number, offset: number)
---@field replace fun(self:TileMap, oldTile: Tile, newTile: Tile)
---@field upFrom fun(self:TileMap, tile: Tile, distance?: number): Tile|nil
---@field downFrom fun(self:TileMap, tile: Tile, distance?: number): Tile|nil
---@field leftFrom fun(self:TileMap, tile: Tile, distance?: number): Tile|nil
---@field rightFrom fun(self:TileMap, tile: Tile, distance?: number): Tile|nil

---Creates a new TileMap instance
---@param name? string The label for this tile map
---@param tiles? Tile[] The list of Tile elements
---@param zIndex? number The "layer" that this tile map is on
---@param events? table A table of events to trigger for different actions
---@return TileMap
function TileMap.new(name, tiles, zIndex, events)
    local this = {}

    this.visible = true

    this.name = name or "TileMap"
    this.tiles = tiles or {}
    this.zIndex = zIndex or 1

    -- Merge custom events with base events
    local mergedEvents = TileMapEvents
    if events ~= nil then
        for event, callback in pairs(events) do
            mergedEvents[event] = callback
        end
    end
    this.events = mergedEvents

    setmetatable(this, {
        __index = TileMap,
        __tostring = function(t)
            return string.format("%s [ %.0f ]", t.name, #t.tiles)
        end,
    })

    return this
end

---Register a callback function for a specific event
---@param event string Name of the event to register
---@param callback fun(self:TileMap) Callback function to execute when event is triggered
function TileMap:on(event, callback)
    assert(TileMapEvents[event], "No event named " .. event)
    self.events[event] = callback
end

---Trigger a specific event on the tile map with optional additional arguments
---@param event string # Name of the event to trigger
---@param ... any # Additional arguments to pass to the event callback
---@return any? result Result of the event callback if successful
---@return nil|string? error Error message if the callback failed
function TileMap:trigger(event, ...)
    assert(TileMapEvents[event], "No event named " .. event)
    -- local status, result = pcall(self.events[event], self, table.unpack(arg))
    local status, result = pcall(self.events[event], self, ...)
    if status then
        return result
    else
        print("TileMap Event Error:", result)
    end
end

local directionVec = {
    up = Vector.new(0, -1),
    down = Vector.new(0, 1),
    left = Vector.new(-1, 0),
    right = Vector.new(1, 0),
}

--- Get the tiles that are in a "straight" line from the given tile
---@param tile Tile
---@param direction string # up, down, left, or right
---@param distance? number # how far to go to get the target tile
---@return Tile[]
function TileMap:tileLineFrom(tile, direction, distance)
    local step = distance or 1

    local moveVec = assert(directionVec[direction], "No direction for " .. direction)

    local tileLine = { tile }

    for i = 1, step do
        local newCoords = tile.coords + (moveVec * i)
        local foundTile = self:findTileAt(newCoords)
        table.insert(tileLine, foundTile)
    end

    return tileLine
end

--- Find the tile at the give grid/iso coordinates
---@param coordsOrX Vector|number
---@param y? number
---@return Tile|nil
function TileMap:findTileAt(coordsOrX, y)
    local coords = type(coordsOrX) == "number" and y and Vector.new(coordsOrX, y)
    if coords == false then
        ---@type Vector
        coords = coordsOrX
    end

    local foundTile = nil

    for _, tile in ipairs(self.tiles) do
        if tostring(tile.coords) == tostring(coords) then
            foundTile = tile
        end
    end

    return foundTile
end

---@todo TileMap:findWorldTile(position: Vector)

--- Gets the tiles that are within a certain radius of a given tile (area of effect)
---@param tile Tile
---@param radius number
---@param offset number
function TileMap:tileRadiusWithin(tile, radius, offset)
    ---@todo implementation
end

--- Replaces a Tile with a new one. Returns true on success and false on missing tile
---@param oldTile Tile
---@param newTile Tile
---@return boolean
function TileMap:replace(oldTile, newTile)
    local replace = nil
    for index, tile in ipairs(self.tiles) do
        if tostring(oldTile.coords) == tostring(tile.coords) then
            replace = index
        end
    end

    if replace == nil then
        return false
    end

    self.tiles[replace] = newTile

    return true
end

---Get the tile up by a given grid/iso distance (y coord -)
---@param tile Tile
---@param distance? number
---@return Tile|nil
function TileMap:upFrom(tile, distance)
    local step = distance or 1
    local newCoords = tile.coords + (directionVec.up * step)

    return self:findTileAt(newCoords)
end

---Get the tile down by a given grid/iso distance (y coord +)
---@param tile Tile
---@param distance? number
---@return Tile|nil
function TileMap:downFrom(tile, distance)
    local step = distance or 1
    local newCoords = tile.coords + (directionVec.down * step)

    return self:findTileAt(newCoords)
end

---Get the tile left by a given grid/iso distance (x coord -)
---@param tile Tile
---@param distance? number
---@return Tile|nil
function TileMap:leftFrom(tile, distance)
    local step = distance or 1
    local newCoords = tile.coords + (directionVec.left * step)

    return self:findTileAt(newCoords)
end

---Get the tile right by a given grid/iso distance (x coord +)
---@param tile Tile
---@param distance? number
---@return Tile|nil
function TileMap:rightFrom(tile, distance)
    local step = distance or 1
    local newCoords = tile.coords + (directionVec.right * step)

    return self:findTileAt(newCoords)
end

return TileMap
