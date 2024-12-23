---@see https://edubart.github.io/lester/
local lester = require("lib.lester")
local describe, it, expect = lester.describe, lester.it, lester.expect

lester.parse_args()

local Vector = require("lib.vector")
local Map = require("lib.map")

-- Customize lester configuration.
lester.show_traceback = true
lester.stop_on_fail = true

-- MARK: Fixtures
local EXAMPLE_HEIGHTMAP = {
    { 1, 1, 1, 1, 1 },
    { 1, 3, 3, 3, 1 },
    { 1, 3, 4, 4, 1 },
    { 1, 2, 2, 2, 1 },
    { 1, 1, 1, 1, 1 },
    { 1, 1, 1, 1, 1 },
}

local EXAMPLE_HEIGHTMAP_ROW_COUNT = #EXAMPLE_HEIGHTMAP
local EXAMPLE_HEIGHTMAP_COL_COUNT = #EXAMPLE_HEIGHTMAP[1]

local EXAMPLE_HEIGHTMAP_COORDS_OUTSIDE_OF_MAP = {
    Vector.new(-1, EXAMPLE_HEIGHTMAP_ROW_COUNT - 1),
    Vector.new(-1, EXAMPLE_HEIGHTMAP_ROW_COUNT),
    Vector.new(-1, EXAMPLE_HEIGHTMAP_ROW_COUNT + 1),
    Vector.new(0, EXAMPLE_HEIGHTMAP_ROW_COUNT + 1),
    Vector.new(1, EXAMPLE_HEIGHTMAP_ROW_COUNT + 1),

    Vector.new(EXAMPLE_HEIGHTMAP_COL_COUNT - 1, EXAMPLE_HEIGHTMAP_ROW_COUNT + 1),
    Vector.new(EXAMPLE_HEIGHTMAP_COL_COUNT, EXAMPLE_HEIGHTMAP_ROW_COUNT + 1),
    Vector.new(EXAMPLE_HEIGHTMAP_COL_COUNT + 1, EXAMPLE_HEIGHTMAP_ROW_COUNT + 1),
    Vector.new(EXAMPLE_HEIGHTMAP_COL_COUNT + 1, EXAMPLE_HEIGHTMAP_ROW_COUNT),
    Vector.new(EXAMPLE_HEIGHTMAP_COL_COUNT + 1, EXAMPLE_HEIGHTMAP_ROW_COUNT - 1),

    Vector.new(-1, 1),
    Vector.new(-1, 0),
    Vector.new(-1, -1),
    Vector.new(0, -1),
    Vector.new(1, -1),

    Vector.new(EXAMPLE_HEIGHTMAP_COL_COUNT - 1, -1),
    Vector.new(EXAMPLE_HEIGHTMAP_COL_COUNT, -1),
    Vector.new(EXAMPLE_HEIGHTMAP_COL_COUNT + 1, -1),
    Vector.new(EXAMPLE_HEIGHTMAP_COL_COUNT + 1, 0),
    Vector.new(EXAMPLE_HEIGHTMAP_COL_COUNT + 1, 1),
}

describe("maps", function()
    it("has zero width and height", function()
        local map = Map.new()
        expect.equal(map.colCount, 0)
        expect.equal(map.rowCount, 0)
    end)

    it("can set the height and width", function()
        local map = Map.new(EXAMPLE_HEIGHTMAP)
        expect.equal(map.colCount, EXAMPLE_HEIGHTMAP_COL_COUNT)
        expect.equal(map.rowCount, EXAMPLE_HEIGHTMAP_ROW_COUNT)
    end)

    it("can get the elevation", function()
        local map = Map.new({
            -- [0,0], [1,0]
            { 1, 10 },
            -- [0,1], [1,1]
            { 2, 20 },
            -- [0,2], [1,2]
            { 3, 30 },
        })
        local coord = Vector.zero()
        local result = map:convertTo3D(coord)
        expect.equal(result.z, map.tiles[tostring(coord)])
        expect.equal(result.z, 1)

        local coord2 = Vector.new(1, 2)
        local result2 = map:convertTo3D(coord2)
        expect.equal(result2.z, map.tiles[tostring(coord2)])
        expect.equal(result2.z, 30)
    end)

    it("handles coords outside of the map", function()
        local map = Map.new(EXAMPLE_HEIGHTMAP)
        for _, tile in pairs(EXAMPLE_HEIGHTMAP_COORDS_OUTSIDE_OF_MAP) do
            expect.equal(map.tiles[tostring(tile)], nil)
        end
    end)

    it("can calculate move costs", function()
        local map = Map.new({
            { 1, 1, 1, 1 },
            { 1, 1, 1, 1 },
            { 1, 1, 1, 1 },
            { 1, 1, 1, 1 },
        })

        local starting = Vector.new(0, 0)
        local ending = Vector.new(0, 1)

        local result = map:heuristicCostEstimate(starting, ending)

        expect.equal(1, result)
    end)

    it("can calculate complex move costs", function()
        local map = Map.new({
            { 1, 1, 1, 1 },
            { 1, 1, 1, 1 },
            { 1, 1, 1, 1 },
            { 1, 1, 1, 1 },
        })

        local starting = Vector.new(0, 0)
        local ending = Vector.new(3, 2)

        local result = map:heuristicCostEstimate(starting, ending)

        expect.equal(4, result)
    end)

    it("can get the dijkstra map for a flat map", function()
        local map = Map.new({
            { 1, 1, 1, 1 },
            { 1, 1, 1, 1 },
            { 1, 1, 1, 1 },
            { 1, 1, 1, 1 },
        })

        local expectedResults = {
            { 0, 1, 2, 3 },
            { 1, 2, 3, 4 },
            { 2, 3, 4, 5 },
            { 3, 4, 5, 6 },
        }

        local target = Vector.zero()

        local distances, previous = map:dijkstra(target)

        for y = 1, map.rowCount do
            for x = 1, map.colCount do
                local vec = Vector.new(x - 1, y - 1)
                expect.equal(distances[tostring(vec)], expectedResults[y][x])
            end
        end
    end)

    it("can get the dijkstra map for a height map", function()
        local map = Map.new({
            { 1, 1, 1, 1 },
            { 1, 2, 2, 1 },
            { 1, 1, 3, 1 },
            { 1, 1, 1, 1 },
        })

        local expectedResults = {
            { 0, 1, 2, 3 },
            { 1, 3, 4, 4 },
            { 2, 3, 6, 5 },
            { 3, 4, 5, 6 },
        }

        local target = Vector.zero()

        local distances, previous = map:dijkstra(target)

        for y = 1, map.rowCount do
            for x = 1, map.colCount do
                local vec = Vector.new(x - 1, y - 1)
                expect.equal(distances[tostring(vec)], expectedResults[y][x])
            end
        end
    end)

    it("can get the dijkstra map for a height map starting elsewhere", function()
        local map = Map.new({
            { 1, 1, 1, 1 },
            { 1, 2, 2, 1 },
            { 1, 1, 3, 1 },
            { 1, 1, 1, 1 },
        })

        local expectedResults = {
            { 3, 3, 4, 5 },
            { 2, 2, 4, 5 },
            { 1, 0, 3, 4 },
            { 2, 1, 2, 3 },
        }

        local target = Vector.new(1, 2)

        local distances, previous = map:dijkstra(target)

        for y = 1, map.rowCount do
            for x = 1, map.colCount do
                local vec = Vector.new(x - 1, y - 1)
                expect.equal(distances[tostring(vec)], expectedResults[y][x])
            end
        end
    end)

    it("can get the dijkstra map for a the example map", function()
        local map = Map.new(EXAMPLE_HEIGHTMAP)

        local expectedResults = {
            { 0, 1, 2, 3, 4 },
            { 1, 4, 5, 6, 5 },
            { 2, 5, 9, 10, 6 },
            { 3, 5, 7, 9, 7 },
            { 4, 5, 6, 7, 8 },
            { 5, 6, 7, 8, 9 },
        }

        local target = Vector.zero()

        local distances, previous = map:dijkstra(target)

        for y = 1, map.rowCount do
            for x = 1, map.colCount do
                local vec = Vector.new(x - 1, y - 1)
                expect.equal(distances[tostring(vec)], expectedResults[y][x])
            end
        end
    end)

    it("can get the path for the example map", function()
        local map = Map.new(EXAMPLE_HEIGHTMAP)

        local expectedResults = {
            "0,0,1",
            "1,0,1",
            "2,0,1",
            "3,0,1",
            "3,1,1",
        }

        local target = Vector.zero()
        local ending = Vector.new(3, 1)

        local distances, previous = map:dijkstra(target)

        local path = map:getPath(previous, target, ending)

        for i, expected in pairs(expectedResults) do
            expect.equal(path[i], expected)
        end
    end)

    it("can handle the a bad target path", function()
        local map = Map.new(EXAMPLE_HEIGHTMAP)

        local expectedResults = {
            "0,0,1",
            "1,0,1",
            "2,0,1",
            "3,0,1",
            "3,1,1",
        }

        local target = Vector.zero()
        local ending = Vector.new(9, 9)

        local distances, previous = map:dijkstra(target)

        local path = map:getPath(previous, target, ending)

        expect.equal(path, nil)
    end)
end)

lester.report() -- Print overall statistic of the tests run.
lester.exit() -- Exit with success if all tests passed.
