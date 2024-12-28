local Vector = require("lib.vector")
local TileMap = require("lib.tilemap")
local Tile = require("lib.tile")

local windowWidth = love.graphics.getWidth()
local windowHeight = love.graphics.getHeight()

-- Tile dimensions and hitbox constants
local TILE_WIDTH = 32
local TILE_HALF_WIDTH = TILE_WIDTH / 2
local TILE_HEIGHT = TILE_WIDTH
local TILE_HALF_HEIGHT = TILE_HEIGHT / 2
local TILE_QUARTER_HEIGHT = TILE_HALF_HEIGHT / 2
local TILE_HITBOX_PADDING = 2

-- press "`" to toggle debugging
local DEBUG = false

local tileStates = {
  active = nil,
  hovered = nil,
  areaTiles = nil,
  areaDistance = 0,
  tileInclusive = false,
  areaRadius = false
}

local assets = { catalog = {} }

function assets:add(name, image)
  self.catalog[name] = image
end

function assets:get(name)
  return self.catalog[name]
end

local groundLayer = {
  { "box", "box", "box", "empty", "box", "box", "box" },
  { "box", "box", "box", "box", "box", "box", "box" },
  { "box", "box", "box", "box", "box", "box", "box" },
  { "empty", "box", "box", "box", "box", "box", "empty" },
  { "box", "box", "box", "box", "box", "box", "box" },
  { "box", "box", "box", "box", "box", "empty", "box" },
  { "box", "box", "box", "box", "box", "box", "box" },
}

local wallLayer = {
  { "empty", "empty", "empty", "box", "empty", "empty", "empty" },
  { "empty", "empty", "empty", "empty", "empty", "empty", "empty" },
  { "empty", "empty", "empty", "empty", "empty", "empty", "empty" },
  { "box", "empty", "empty", "empty", "empty", "empty", "box" },
  { "empty", "empty", "empty", "empty", "empty", "empty", "empty" },
  { "empty", "empty", "empty", "empty", "empty", "box", "empty" },
  { "empty", "empty", "empty", "empty", "empty", "empty", "empty" },
}

local tiles = {}

local groundMap = TileMap.new("ground", {})

function love.resize(w, h)
    if w ~= nil then
        windowWidth = w
    end
    if h ~= nil then
        windowHeight = h
    end
end

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

local function makeTile(center, tex, column, row)
    return Tile.new(tex .. "Tile", tex, Vector.new(column - 1, row - 1), center, TILE_WIDTH, TILE_HEIGHT, nil, nil, tileEvents, {
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
end

function love.load()
    assets:add("box", love.graphics.newImage("assets/box.png"))
    assets:add("overlay", love.graphics.newImage("assets/overlay.png"))
    assets:add("selection", love.graphics.newImage("assets/selection.png"))
    assets:add("area", love.graphics.newImage("assets/area.png"))

    for row = 1, #groundLayer do
        for column, tex in ipairs(groundLayer[row]) do
            if tex == "empty" then
                goto continue
            end
            local center = Vector.new(
                (windowWidth / 2) + (TILE_HALF_WIDTH * column) - (row * TILE_HALF_WIDTH),
                (windowHeight / 4) + (TILE_QUARTER_HEIGHT * column) + (row * TILE_QUARTER_HEIGHT)
            )
            local tile = makeTile(center, tex, column, row)

            table.insert(tiles, tile)
            ::continue::
        end
    end

    for row = 1, #wallLayer do
        for column, tex in ipairs(wallLayer[row]) do
            if tex == "empty" then
                goto continue
            end
            local center = Vector.new(
                (windowWidth / 2) + (TILE_HALF_WIDTH * column) - (row * TILE_HALF_WIDTH),
                -- walls are an extra half step higher
                (windowHeight / 4) + (TILE_QUARTER_HEIGHT * column) + (row * TILE_QUARTER_HEIGHT) - TILE_QUARTER_HEIGHT - TILE_HITBOX_PADDING,
                -- walls are on the level 2
                2
            )
            local tile = makeTile(center, tex, column, row)

            table.insert(tiles, tile)
            ::continue::
        end
    end

    groundMap.tiles = tiles

    tileStates.active = groundMap:findTileAt(3, 3)
end

function love.update(dt)
    -- tileStates.areaTiles = groundMap:getNeighboursFor(tileStates.active, tileStates.areaDistance, tileStates.tileInclusive)
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
        if code == "r" then
          tileStates.areaRadius = not tileStates.areaRadius
        end

        if code == "a" then
            tileStates.areaDistance = tileStates.areaDistance + 1
        end

        if code == "s" and tileStates.areaDistance > 0 then
            tileStates.areaDistance = tileStates.areaDistance - 1
        end

        if code == "d" then
            tileStates.tileInclusive = not tileStates.tileInclusive
        end

        -- the tiles are all part of the same map and their coordinates are not actually taking into account their "z position"
        -- we are just drawing them at different Y positions based on their "layer" which allows us to move to them as if they were higher even though they aren't actually
        if code == "up" then
            local moveTo = groundMap:upFrom(tileStates.active)
            if moveTo ~= nil then
                tileStates.active = groundMap:upFrom(tileStates.active)
            end
        end
        if code == "down" then
            local moveTo = groundMap:downFrom(tileStates.active)
            if moveTo ~= nil then
                tileStates.active = groundMap:downFrom(tileStates.active)
            end
        end
        if code == "left" then
            local moveTo = groundMap:leftFrom(tileStates.active)
            if moveTo ~= nil then
                tileStates.active = groundMap:leftFrom(tileStates.active)
            end
        end
        if code == "right" then
            local moveTo = groundMap:rightFrom(tileStates.active)
            if moveTo ~= nil then
                tileStates.active = groundMap:rightFrom(tileStates.active)
            end
        end

        if tileStates.areaRadius == false then
            tileStates.areaTiles = groundMap:getNeighboursFor(tileStates.active, tileStates.areaDistance, tileStates.tileInclusive)
        else
            tileStates.areaTiles = groundMap:tileRadiusWithin(tileStates.active, tileStates.areaDistance)
        end
    end
end

function love.draw()
    -- loop over everything again and draw the second layer
    -- this allows use to draw the ground "under" the "wall" layer
    for index = 1, 2 do
        for _, tile in pairs(tiles) do
            if tile.center.z == index then
                tile:trigger("draw")
            end

            if tileStates.active ~= nil and tileStates.active.center.z == index then
                love.graphics.setColor(1, 1, 1)

                love.graphics.draw(
                    assets:get("selection"),
                    tileStates.active.center.x,
                    tileStates.active.center.y,
                    nil,
                    nil,
                    nil,
                    TILE_HALF_WIDTH,
                    TILE_HALF_HEIGHT
                    )
            end

            if tileStates.hovered ~= nil and tileStates.hovered.center.z == index then
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
        end
        if tileStates.areaTiles ~= nil and tileStates.areaDistance > 0 then
            for _, tile in pairs(tileStates.areaTiles) do
                if tile.center.z == index then
                    love.graphics.setColor(1, 1, 1)

                    love.graphics.draw(
                        assets:get("area"),
                        tile.center.x,
                        tile.center.y,
                        nil,
                        nil,
                        nil,
                        TILE_HALF_WIDTH,
                        TILE_HALF_HEIGHT
                        )
                end
            end
        end
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
