local Vector = require("lib.vector")

-- Tile dimensions and hitbox constants
local TILE_WIDTH = 32
local TILE_HALF_WIDTH = TILE_WIDTH / 2
local TILE_QUARTER_WIDTH = TILE_HALF_WIDTH / 2
local TILE_HEIGHT = TILE_WIDTH
local TILE_HALF_HEIGHT = TILE_HEIGHT / 2
local TILE_QUARTER_HEIGHT = TILE_HALF_HEIGHT / 2
local TILE_HITBOX_PADDING = 2

---@class Tile
---@field hovered boolean Whether the tile is currently being hovered
---@field active boolean Whether the tile is currently selected/active
---@field visitable boolean Whether entities can move onto this tile
---@field name string Label for this tile
---@field texture string Name of the tile's texture
---@field decoration string? Optional decorative texture overlay
---@field coords Vector Grid coordinates of the tile
---@field center Vector World position center point
---@field events table Table of event callbacks
---@field boundingbox table Visual boundaries of the tile
---@field hitbox table Interaction boundaries of the tile
---@field new fun(name: string, texture: string, coords: Vector, center: Vector, decoration?: string, events?: TileEvents, boundingbox?: table, hitbox?: table): Tile Creates a new Tile instance
---@field on fun(self: Tile, event: string, callback: fun(self: Tile, ...any)) Register a callback function for a specific event
---@field trigger fun(self: Tile, event: string, ...any): any?, nil|string? Trigger a specific event on the tile with optional additional arguments
---@field duplicate fun(self: Tile): Tile Create a copy of the current tile
---@field up fun(self: Tile): Tile Move tile up one grid position
---@field down fun(self: Tile): Tile Move tile down one grid position
---@field left fun(self: Tile): Tile Move tile left one grid position
---@field right fun(self: Tile): Tile Move tile right one grid position

local Tile = { __type = "Tile" }
Tile.__index = Tile

---@class TileEvents
local TileEvents = {
    --- Entity lands on the tile
    ---@param this Tile
    enter = function(this)
        this:trigger("log", "enter", this)
    end,

    --- Entity leaves the tile
    ---@param this Tile
    leave = function(this)
        this:trigger("log", "leave", this)
    end,

    --- Entity is currently on the tile
    ---@param this Tile
    occupied = function(this)
        this:trigger("log", "occupied", this)
    end,

    --- Tile is hovered by cursor or selector
    ---@param this Tile
    hovered = function(this)
        this:trigger("log", "hovered", this)
    end,

    --- Tile is selected
    ---@param this Tile
    active = function(this)
        this:trigger("log", "active", this)
    end,

    --- Tile is disabled
    ---@param this Tile
    disabled = function(this)
        this:trigger("log", "disabled", this)
    end,

    --- Collect details about the tile
    ---@param this Tile
    inspect = function(this)
        this:trigger("log", "inspect", this)
    end,

    --- Buffs/debuffs that apply when occupied
    ---@param this Tile
    effects = function(this)
        this:trigger("log", "effects", this)
    end,

    --- Tile takes damage
    ---@param this Tile
    damaged = function(this)
        this:trigger("log", "damaged", this)
    end,

    --- Tile is destroyed
    ---@param this Tile
    destroyed = function(this)
        this:trigger("log", "destroyed", this)
    end,

    -- System events
    ---@param this Tile
    load = function(this)
        this:trigger("log", "load", this)
    end,
    ---@param this Tile
    loadTexture = function(this)
        this:trigger("log", "loadTexture", this)
    end,
    ---@param this Tile
    unload = function(this)
        this:trigger("log", "unload", this)
    end,
    ---@param this Tile
    beforeUpdate = function(this)
        this:trigger("log", "beforeUpdate", this)
    end,
    ---@param this Tile
    update = function(this)
        this:trigger("log", "update", this)
    end,
    ---@param this Tile
    afterUpdate = function(this)
        this:trigger("log", "afterUpdate", this)
    end,
    ---@param this Tile
    beforeDraw = function(this)
        this:trigger("log", "beforeDraw", this)
    end,
    ---@param this Tile
    draw = function(this)
        this:trigger("log", "draw", this)
    end,
    ---@param this Tile
    afterDraw = function(this)
        this:trigger("log", "afterDraw", this)
    end,
    ---@param ... any # details to log
    log = function(...)
        -- print("tile log", table.unpack(arg))
        print("tile log", ...)
    end,
}

---Creates a new Tile instance
---@param name string The label for this tile
---@param texture? string The name of the texture to load
---@param coords Vector The coordinates on the grid
---@param center Vector The center in the world
---@param decoration? string If the tile has an additional texture on the top layer
---@param events? table A table of events to trigger for different actions
---@param boundingbox? table A table of points that make up the bounding box
---@param hitbox? table A table of points that make up the hit box
---@return Tile
function Tile.new(name, texture, coords, center, decoration, events, boundingbox, hitbox)
    local this = {}

    this.hovered = false
    this.active = false
    this.visitable = true

    this.name = name
    this.texture = texture or nil
    this.decoration = decoration or nil

    this.coords = coords
    this.center = center

    -- Merge custom events with base events
    local mergedEvents = TileEvents
    if events ~= nil then
        for event, callback in pairs(events) do
            mergedEvents[event] = callback
        end
    end
    this.events = mergedEvents

    this.boundingbox = boundingbox or {
        left = center.x - TILE_HALF_WIDTH,
        top = center.y - TILE_HEIGHT,
        right = center.x + TILE_HALF_HEIGHT,
        bottom = center.y + TILE_HALF_WIDTH,
    }

    this.hitbox = hitbox or {
        left = center.x,
        top = center.y - (TILE_HALF_HEIGHT + TILE_QUARTER_HEIGHT - (TILE_HITBOX_PADDING * 2)),
        right = center.x + TILE_HALF_HEIGHT,
        bottom = center.y + TILE_HALF_WIDTH,
    }

    setmetatable(this, {
        __index = Tile,
        __tostring = function(t)
            return string.format("%s [ %.0f, %.0f ]", t.texture, t.coords.x, t.coords.y)
        end,
    })

    return this
end

---Register a callback function for a specific event
---@param event string Name of the event to register
---@param callback fun(self:Tile) Callback function to execute when event is triggered
function Tile:on(event, callback)
    assert(TileEvents[event], "No event named " .. event)
    self.events[event] = callback
end

---Trigger a specific event on the tile with optional additional arguments
---@param event string # Name of the event to trigger
---@param ... any # Additional arguments to pass to the event callback
---@return any? result Result of the event callback if successful
---@return nil|string? error Error message if the callback failed
function Tile:trigger(event, ...)
    assert(TileEvents[event], "No event named " .. event)
    -- local status, result = pcall(self.events[event], self, table.unpack(arg))
    local status, result = pcall(self.events[event], self, ...)
    if status then
        return result
    else
        print("Tile Event Error:", result)
    end
end

---@return Tile
function Tile:duplicate()
    return Tile.new(
        self.name,
        self.texture,
        self.coords,
        self.center,
        self.decoration,
        self.events,
        self.boundingbox,
        self.hitbox
    )
end

---Move tile up one grid/iso position
---@return self
function Tile:up()
    self.coords = self.coords + Vector.new(-1, 1)
    return self
end

---Move tile down one grid/iso position
---@return self
function Tile:down()
    self.coords = self.coords + Vector.new(1, 1)
    return self
end

---Move tile left one grid/iso position
---@return self
function Tile:left()
    self.coords = self.coords + Vector.new(-1, -1)
    return self
end

---Move tile right one grid/iso position
---@return self
function Tile:right()
    self.coords = self.coords + Vector.new(-1, 1)
    return self
end

---Check if the tile "top" is being hovered over
---@return boolean
function Tile:isHovered(pointer)
  -- Calculate the squared distances
  local dx_squared = pointer.x - self.hitbox.left
  local dy_squared = pointer.y - self.hitbox.top

  local distance_squared = dx_squared ^ 2 + dy_squared ^ 2

  -- Check if the squared distance is less than or equal to the squared radius
  return distance_squared <= TILE_QUARTER_HEIGHT ^ 2
end

return Tile