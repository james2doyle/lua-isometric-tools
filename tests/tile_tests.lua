---@see https://edubart.github.io/lester/
local lester = require("lib.lester")
local describe, it, expect = lester.describe, lester.it, lester.expect

lester.parse_args()

local Vector = require("lib.vector")
local Tile = require("lib.tile")

-- Customize lester configuration.
lester.show_traceback = true
lester.stop_on_fail = true

describe("tiles", function()
    it("can create a tile", function()
        local t = Tile.new(
            "grassTile",
            "grass",
            Vector.zero(),
            Vector.new(200, 200),
            nil
        )

        expect.equal(tostring(t), "grass [ 0, 0 ]")
        expect.equal(t.name, "grassTile")
        expect.equal(t.texture, "grass")
        expect.equal(t.decoration, nil)
        expect.equal(tostring(t.coords), tostring(Vector.zero()))
        expect.equal(tostring(t.center), tostring(Vector.new(200, 200)))
    end)

    it("can trigger events on a tile", function()
        local t = Tile.new(
            "grassTile",
            "grass",
            Vector.zero(),
            Vector.new(200, 200),
            nil
        )

        local didTrigger = false
        expect.equal(false, didTrigger)

        t:on("load", function ()
            didTrigger = true
        end)
        t:trigger("load")

        expect.equal(true, didTrigger)
    end)

    it("can use events on a tile to manipulate it", function()
        local t = Tile.new(
            "grassTile",
            "grass",
            Vector.zero(),
            Vector.new(200, 200),
            nil
        )

        expect.equal(false, t.hovered)
        t:on("hovered", function (this)
            this.hovered = true
        end)
        t:trigger("hovered")

        expect.equal(true, t.hovered)
    end)

    it("can use events on a tile with additional data", function()
        local t = Tile.new(
            "grassTile",
            "grass",
            Vector.zero(),
            Vector.new(200, 200),
            nil
        )

        t.hovered = true
        t.active = true

        local extraDetails = os.time()
        t:on("destroyed", function (this, details)
            this.hovered = false
            this.active = false
            this.visitable = false
            extraDetails = details
        end)
        t:trigger("destroyed", nil)

        expect.equal(false, t.hovered)
        expect.equal(false, t.active)
        -- expect.equal(true, t.visitable)
        expect.equal(nil, extraDetails)
    end)
end)

lester.report() -- Print overall statistic of the tests run.
lester.exit() -- Exit with success if all tests passed.
