---@see https://edubart.github.io/lester/
local lester = require("lib.lester")
local describe, it, expect = lester.describe, lester.it, lester.expect

lester.parse_args()

local Vector = require("lib.vector")
local Tile = require("lib.tile")

local TILE_WIDTH = 32
local TILE_HEIGHT = TILE_WIDTH

-- Customize lester configuration.
lester.show_traceback = true
lester.stop_on_fail = true

describe("tiles", function()
    it("can create a tile", function()
        local t = Tile.new("grassTile", "grass", Vector.zero(), Vector.new(200, 200), TILE_WIDTH, TILE_HEIGHT)

        expect.equal("grass [ 0, 0 ]", tostring(t))
        expect.equal("grassTile", t.name)
        expect.equal("grass", t.texture)
        expect.equal(nil, t.decoration)
        expect.equal(tostring(Vector.zero()), tostring(t.coords))
        expect.equal(tostring(Vector.new(200, 200)), tostring(t.center))
    end)

    it("can duplicate a tile", function()
        local t = Tile.new("grassTile", "grass", Vector.zero(), Vector.new(200, 200), TILE_WIDTH, TILE_HEIGHT)

        local t2 = t:duplicate()

        expect.equal(tostring(t), tostring(t2))
        expect.equal(t.name, t2.name)
        expect.equal(t.texture, t2.texture)
        expect.equal(t.decoration, t2.decoration)
        expect.equal(tostring(t.coords), tostring(t2.coords))
        expect.equal(tostring(t.center), tostring(t2.center))
    end)

    it("can trigger events on a tile", function()
        local t = Tile.new("grassTile", "grass", Vector.zero(), Vector.new(200, 200), TILE_WIDTH, TILE_HEIGHT)

        local didTrigger = false
        expect.equal(false, didTrigger)

        t:on("load", function()
            didTrigger = true
        end)
        t:trigger("load")

        expect.equal(true, didTrigger)
    end)

    it("can use events on a tile to manipulate it", function()
        local t = Tile.new("grassTile", "grass", Vector.zero(), Vector.new(200, 200), TILE_WIDTH, TILE_HEIGHT)

        expect.equal(false, t.hovered)
        t:on("hovered", function(this)
            this.hovered = true
        end)
        t:trigger("hovered")

        expect.equal(true, t.hovered)
    end)

    it("can use events on a tile with additional data", function()
        local t = Tile.new("grassTile", "grass", Vector.zero(), Vector.new(200, 200), TILE_WIDTH, TILE_HEIGHT)

        t.hovered = true
        t.active = true

        local extraDetails = os.time()
        t:on("destroyed", function(this, details)
            this.hovered = false
            this.active = false
            this.visitable = false
            extraDetails = details
        end)
        t:trigger("destroyed", nil)

        expect.equal(false, t.hovered)
        expect.equal(false, t.active)
        expect.equal(false, t.visitable)
        expect.equal(nil, extraDetails)
    end)

    it("can make moves in different directions", function()
        -- {0,0} {1,0} {2,0}
        -- {0,1} {1,1} {2,1}
        -- {0,2} {1,2} {2,2}
        local t = Tile.new("grassTile", "grass", Vector.new(1, 1), Vector.new(200, 200), TILE_WIDTH, TILE_HEIGHT)

        expect.equal("1,0,1", tostring(t:duplicate():up().coords))
        expect.equal("1,2,1", tostring(t:duplicate():down().coords))
        expect.equal("0,1,1", tostring(t:duplicate():left().coords))
        expect.equal("2,1,1", tostring(t:duplicate():right().coords))
    end)

    it("can check if a tile is hovered", function()
        local t = Tile.new("grassTile", "grass", Vector.new(1, 1), Vector.new(200, 200), TILE_WIDTH, TILE_HEIGHT)

        local pointer = Vector.new(201, 201)
        local isHovered = t:isHovered(pointer)
        local pointer2 = Vector.new(190, 190)
        local isNotHovered = t:isHovered(pointer2)

        expect.equal(true, isHovered)
        expect.equal(false, isNotHovered)
    end)
end)

lester.report() -- Print overall statistic of the tests run.
lester.exit() -- Exit with success if all tests passed.
