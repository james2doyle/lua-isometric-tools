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
    isMoving = true,
}

local assets = { catalog = {} }

function assets:add(name, image)
    self.catalog[name] = image
end

function assets:get(name)
    return self.catalog[name]
end

local groundLayer = {
    { "box", "box", "box","box", "empty", "box", "empty", "box", "box", "box" },
    { "box", "box", "box","box", "box", "box", "box", "box", "box", "box" },
    { "box", "box", "box","box", "box", "box", "box", "box", "box", "box" },
    { "empty", "empty", "empty","empty", "box", "box", "box", "box", "box", "empty" },
    { "box", "box", "box","box", "box", "box", "box", "box", "box", "box" },
    { "box", "box", "box","box", "box", "box", "box", "box", "box", "box" },
    { "box", "box", "box","box", "box", "box", "box", "box", "box", "box" },
    { "box", "box", "box","box", "box", "box", "box", "box", "box", "box" },
    { "box", "box", "box","box", "box", "box", "box", "box", "empty", "box" },
    { "box", "box", "box","box", "box", "box", "box", "box", "box", "box" },
}

local wallLayer = {
    { "empty", "empty", "empty", "empty", "empty", "empty", "box", "empty", "empty", "empty" },
    { "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty" },
    { "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty" },
    { "box", "box", "box", "box", "empty", "empty", "empty", "empty", "empty", "box" },
    { "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty" },
    { "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty" },
    { "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty" },
    { "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty" },
    { "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "box", "empty" },
    { "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty" },
}

---@param tile Tile
local function drawSelection(tile)
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(
        assets:get("selection"),
        tile.center.x,
        tile.center.y,
        nil,
        nil,
        nil,
        TILE_HALF_WIDTH,
        TILE_HALF_HEIGHT
        )
end

---@param tile Tile
local function drawOverlay(tile)
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(
        assets:get("overlay"),
        tile.center.x,
        tile.center.y,
        nil,
        nil,
        nil,
        TILE_HALF_WIDTH,
        TILE_HALF_HEIGHT
        )
end

---@param tile Tile
local function drawArea(tile)
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

local tiles = {}

local movementMap = TileMap.new("movement", {})
local groundMap = TileMap.new("ground", {}, nil, {
    draw = function(this)
        -- loop over everything again and draw the second layer
        -- this allows use to draw the ground "under" the "wall" layer
        for index = 1, 2 do
            for _, tile in pairs(this.tiles) do
                if tile.center.z == index then
                    tile:trigger("draw")
                end
            end
        end
    end
})

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

        if tileStates.isMoving then
            -- check if this is a movement area tile
            local areaTile = movementMap:findTileAt(tile.coords)

            -- only draw the area tile if this also isn't being hovered
            if areaTile and tileStates.hovered ~= tile then
                drawArea(tile)
            end

            if tileStates.hovered == tile then
                drawOverlay(tile)
            end
        end

        if tileStates.active == tile then
            drawSelection(tile)
        end

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

    tileStates.active = groundMap:findTileAt(4, 4)

    tileStates.hovered = tileStates.active

    -- there are always tiles to move to on this map so ignore nulls
    -- using tilesAtDistance would give you less tiles and it is less accurate to the actual "movement" count
    movementMap.tiles = assert(groundMap:tilesAtDistance(tileStates.active, 4))
end

function love.update(dt)
    --- do updates
end

function love.mousemoved(mx, my)
    if not tileStates.isMoving then
        return
    end

    local mouseVec = Vector.new(mx, my)
    for _, tile in pairs(movementMap.tiles) do
        if tile:isHovered(mouseVec) then
            tileStates.hovered = tile
        end
    end
end

-- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
function love.mousepressed(mx, my, button, istouch, presses)
    if not tileStates.isMoving then
        return
    end

    if button == 1 and tileStates.hovered then
        tileStates.active = tileStates.hovered
        movementMap.tiles = groundMap:tileRadiusWithin(tileStates.active, 4)
        tileStates.isMoving = false
    end
end

function love.keypressed(key, code, isRepeat)
    if code == "`" then
        DEBUG = not DEBUG
    end

    if code == "m" then
        tileStates.isMoving = not tileStates.isMoving
        tileStates.hovered = tileStates.active
    end

    if code == "return" then
        tileStates.active = tileStates.hovered
        movementMap.tiles = groundMap:tileRadiusWithin(tileStates.active, 4)
        tileStates.isMoving = false
    end

    if tileStates.isMoving and tileStates.hovered then
        if code == "up" then
            local moveTo = movementMap:upFrom(tileStates.hovered)
            if moveTo ~= nil then
                tileStates.hovered = moveTo
            end
        end
        if code == "down" then
            local moveTo = movementMap:downFrom(tileStates.hovered)
            if moveTo ~= nil then
                tileStates.hovered = moveTo
            end
        end
        if code == "left" then
            local moveTo = movementMap:leftFrom(tileStates.hovered)
            if moveTo ~= nil then
                tileStates.hovered = moveTo
            end
        end
        if code == "right" then
            local moveTo = movementMap:rightFrom(tileStates.hovered)
            if moveTo ~= nil then
                tileStates.hovered = moveTo
            end
        end
    end
end

function love.draw()
    groundMap:trigger("draw")

    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(1, 1, 1)
    if tileStates.isMoving then
        love.graphics.print("Use arrows/mouse to move, select tile with enter/click", 10, windowHeight - 25)
    else
        love.graphics.print("Press [m] to start moving", 10, windowHeight - 25)
    end

    if DEBUG then
        love.graphics.push()

        local info = {
            "FPS: " .. ("%3d"):format(love.timer.getFPS()),
            "Hovered Tile: " .. (tileStates.hovered and tostring(tileStates.hovered) or "[ ?, ? ]"),
            "Active Tile: " .. (tileStates.active and tostring(tileStates.active) or "[ ?, ? ]"),
        }

        for i, text in ipairs(info) do
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(text, 5, 5 + (i - 1) * 10)
        end

        love.graphics.pop()
    end
end
