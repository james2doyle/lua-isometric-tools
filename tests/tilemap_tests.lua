---@see https://edubart.github.io/lester/
local lester = require("lib.lester")
local describe, it, expect = lester.describe, lester.it, lester.expect

lester.parse_args()

local Vector = require("lib.vector")
local TileMap = require("lib.tilemap")
local Tile = require("lib.tile")

local EXAMPLE_MAP_TILES = {
    { "grass", "grass", "grass", "grass", "grass", "grass", "grass", "grass", "grass", "grass" },
    { "grass", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "grass" },
    { "grass", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "grass" },
    { "grass", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "grass" },
    { "grass", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "grass" },
    { "grass", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "grass" },
    { "grass", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "grass" },
    { "grass", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "grass" },
    { "grass", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "ground", "grass" },
    { "grass", "grass", "grass", "grass", "grass", "grass", "grass", "grass", "grass", "grass" },
}

local EXAMPLE_TILE_LIST = {}

local TILE_WIDTH = 32
local TILE_HALF_WIDTH = TILE_WIDTH / 2
local TILE_HEIGHT = TILE_WIDTH
local TILE_HALF_HEIGHT = TILE_HEIGHT / 2
local TILE_QUARTER_HEIGHT = TILE_HALF_HEIGHT / 2

for row = 1, #EXAMPLE_MAP_TILES do
    for column, texture_key in ipairs(EXAMPLE_MAP_TILES[row]) do
        local tile = Tile.new(
            texture_key,
            texture_key,
            Vector.new(column - 1, row - 1),
            Vector.new(
                400 + (TILE_HALF_WIDTH * column) - (row * TILE_HALF_WIDTH),
                150 + (TILE_QUARTER_HEIGHT * column) + (row * TILE_QUARTER_HEIGHT)
            ),
            TILE_WIDTH,
            TILE_HEIGHT
        )
        table.insert(EXAMPLE_TILE_LIST, tile)
    end
end

-- Customize lester configuration.
lester.show_traceback = true
lester.stop_on_fail = true

describe("tilemaps", function()
    it("can create a tilemap", function()
        local t = TileMap.new("ground", EXAMPLE_TILE_LIST)

        expect.equal("ground [ 100 ]", tostring(t))
    end)

    it("can trigger events on a tilemap", function()
        local t = TileMap.new("ground", EXAMPLE_TILE_LIST)

        local didTrigger = false
        expect.equal(false, didTrigger)

        t:on("load", function()
            didTrigger = true
        end)
        t:trigger("load")

        expect.equal(true, didTrigger)
    end)

    it("can use events on a tilemap to manipulate it", function()
        local t = TileMap.new("ground", EXAMPLE_TILE_LIST)

        expect.equal(true, t.visible)
        t:on("load", function(this)
            this.visible = false
        end)
        t:trigger("load")

        expect.equal(false, t.visible)
    end)

    it("can use events on a tilemap with additional data", function()
        local t = TileMap.new("ground", EXAMPLE_TILE_LIST)

        t.visible = false

        local extraDetails = os.time()
        t:on("load", function(this, details)
            t.visible = true
            extraDetails = details
        end)
        t:trigger("load", nil)

        expect.equal(true, t.visible)
        expect.equal(nil, extraDetails)
    end)

    it("can find tiles on the map using coordinates", function()
        local t = TileMap.new("ground", EXAMPLE_TILE_LIST)

        local tileThatExistsViaNumber = t:findTileAt(0, 0)
        local tileThatExistsViaVector = t:findTileAt(EXAMPLE_TILE_LIST[1].coords)
        local tileThatDoesNotExists = t:findTileAt(999, 999)

        expect.equal("0,0,1", tostring(tileThatExistsViaNumber.coords))
        expect.equal("0,0,1", tostring(tileThatExistsViaVector.coords))
        expect.equal(nil, tileThatDoesNotExists)
    end)

    it("can get tiles on the map using a direction and distance", function()
        local t = TileMap.new("ground", EXAMPLE_TILE_LIST)

        local tileList = t:tileLineFrom(EXAMPLE_TILE_LIST[1], "down", 2)

        -- target tile plus the 2 other ones
        expect.equal(3, #tileList)

        expect.equal("0,0,1", tostring(tileList[1].coords))
        expect.equal("0,1,1", tostring(tileList[2].coords))
        expect.equal("0,2,1", tostring(tileList[3].coords))
    end)

    it("can replace one tile on the map with another tile", function()
        local t = TileMap.new("ground", EXAMPLE_TILE_LIST)

        local newTile = EXAMPLE_TILE_LIST[1]:duplicate()

        newTile.name = "changedTile"

        expect.not_equal("changedTile", EXAMPLE_TILE_LIST[1].name)

        t:replace(EXAMPLE_TILE_LIST[1], newTile)

        expect.equal("changedTile", EXAMPLE_TILE_LIST[1].name)
    end)

    it("can find neighbour tiles at a given distance", function()
        local t = TileMap.new("ground", EXAMPLE_TILE_LIST)

        local tile = t:findTileAt(2, 2)

        local nothingFound = t:getNeighboursFor(tile, 0)
        local fourFound = t:getNeighboursFor(tile, 2)
        local fourFoundExclusive = t:getNeighboursFor(tile, 2)
        local eightFoundInclusive = t:getNeighboursFor(tile, 2, true)

        expect.equal(nil, nothingFound)
        expect.equal(4, #fourFound)
        expect.equal(4, #fourFoundExclusive)
        expect.equal(8, #eightFoundInclusive)
    end)
end)

lester.report() -- Print overall statistic of the tests run.
lester.exit() -- Exit with success if all tests passed.
