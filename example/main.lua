local Vector = require("lib.vector")
local TileMap = require("lib.tilemap")
local Tile = require("lib.tile")

-- Tile dimensions and hitbox constants
local TILE_WIDTH = 32
local TILE_HALF_WIDTH = TILE_WIDTH / 2
local TILE_QUARTER_WIDTH = TILE_HALF_WIDTH / 2
local TILE_HEIGHT = TILE_WIDTH
local TILE_HALF_HEIGHT = TILE_HEIGHT / 2
local TILE_QUARTER_HEIGHT = TILE_HALF_HEIGHT / 2
local TILE_HITBOX_PADDING = 2

local loadTimeStart = love.timer.getTime()

-- press "`" to toggle debugging
local DEBUG = false

local tileStates = {
    active = nil,
    hovered = nil,
}

local assets = { catalog = {} }

function assets:add(name, image)
    self.catalog[name] = image
end

function assets:get(name)
    return self.catalog[name]
end

local map = {
    { "box", "box", "box", "box", "box", "box", "box" },
    { "box", "box", "box", "box", "box", "box", "box" },
    { "box", "box", "box", "box", "box", "box", "box" },
    { "box", "box", "box", "box", "box", "box", "box" },
    { "box", "box", "box", "box", "box", "box", "box" },
    { "box", "box", "box", "box", "box", "box", "box" },
    { "box", "box", "box", "box", "box", "box", "box" },
}

local tiles = {}

local tileMap = TileMap.new("ground", {})

function love.load()
    assets:add("box", love.graphics.newImage("assets/box.png"))
    assets:add("overlay", love.graphics.newImage("assets/overlay.png"))

    local tileEvents = {
        ---@param tile Tile
        draw = function(tile)
            love.graphics.setColor(1, 1, 1)

            love.graphics.draw(
                assets:get(tile.texture),
                tile.center.x,
                tile.center.y,
                nil,
                nil,
                nil,
                TILE_HALF_WIDTH,
                TILE_HALF_HEIGHT
            )

            if DEBUG then
                -- green
                love.graphics.setColor(0, 1, 0)
                love.graphics.rectangle("line", tile.boundingbox.left, tile.boundingbox.top, TILE_HEIGHT, TILE_WIDTH)

                -- blue
                love.graphics.setColor(0, 0, 1)
                love.graphics.circle(
                    "line",
                    tile.hitbox.left,
                    tile.hitbox.top,
                    TILE_QUARTER_HEIGHT + (TILE_HITBOX_PADDING * 2)
                )

                -- red
                love.graphics.setColor(1, 0, 0)
                love.graphics.points(tile.center.x, tile.center.y)
            end
        end,
    }

    for row = 1, #map do
        for column, tex in ipairs(map[row]) do
            local center = Vector.new(
                400 + (TILE_HALF_WIDTH * column) - (row * TILE_HALF_WIDTH),
                150 + (TILE_QUARTER_HEIGHT * column) + (row * TILE_QUARTER_HEIGHT)
            )
            local tile = Tile.new("boxTile", tex, Vector.new(column - 1, row - 1), center, nil, tileEvents, {
                left = center.x - TILE_HALF_WIDTH,
                top = center.y - TILE_HALF_HEIGHT,
                right = center.x + TILE_HALF_HEIGHT,
                bottom = center.y + TILE_HALF_WIDTH,
            }, {
                left = center.x,
                top = center.y + TILE_HITBOX_PADDING,
                right = center.x + TILE_HALF_HEIGHT,
                bottom = center.y + TILE_HALF_WIDTH,
            })
            table.insert(tiles, tile)
        end
    end

    tileMap.tiles = tiles

    tileStates.active = tileMap:findTileAt(3, 3)
end

function love.update(dt)
    ---@todo update
end

function love.mousemoved(mx, my)
    tileStates.hovered = nil
    local mouseVec = Vector.new(mx, my)
    for _, tile in pairs(tiles) do
        if tile:isHovered(mouseVec) then
            tileStates.hovered = tile
        end
    end
end

-- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
function love.mousepressed(mx, my, button, istouch, presses)
    if button == 1 then
        tileStates.active = tileStates.hovered
    end
end

function love.keypressed(key, code, isRepeat)
    if code == "`" then
        DEBUG = not DEBUG
    end
    if tileStates.active ~= nil then
        if code == "up" then
            tileStates.active = tileMap:upFrom(tileStates.active)
        end
        if code == "down" then
            tileStates.active = tileMap:downFrom(tileStates.active)
        end
        if code == "left" then
            tileStates.active = tileMap:leftFrom(tileStates.active)
        end
        if code == "right" then
            tileStates.active = tileMap:rightFrom(tileStates.active)
        end
    end
end

function love.draw()
    for _, tile in pairs(tiles) do
        love.graphics.setColor(1, 1, 1)
        tile:trigger("draw")
    end

    if tileStates.hovered ~= nil then
        love.graphics.setColor(1, 1, 1)

        love.graphics.draw(
            assets:get("overlay"),
            tileStates.hovered.center.x,
            tileStates.hovered.center.y,
            nil,
            nil,
            nil,
            TILE_HALF_WIDTH,
            TILE_HALF_HEIGHT
        )
    end

    if tileStates.active ~= nil then
        love.graphics.setColor(1, 1, 1)

        love.graphics.draw(
            assets:get("overlay"),
            tileStates.active.center.x,
            tileStates.active.center.y,
            nil,
            nil,
            nil,
            TILE_HALF_WIDTH,
            TILE_HALF_HEIGHT
        )
    end

    if DEBUG then
        love.graphics.push()

        local info = {
            "FPS: " .. ("%3d"):format(love.timer.getFPS()),
            "Hovered Tile: " .. (tileStates.hovered and tostring(tileStates.hovered) or "[ ?, ? ]"),
            "Active Tile: " .. (tileStates.active and tostring(tileStates.active) or "[ ?, ? ]"),
        }

        love.graphics.setFont(love.graphics.newFont(12))
        for i, text in ipairs(info) do
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(text, 5, 5 + (i - 1) * 10)
        end

        love.graphics.pop()
    end
end
