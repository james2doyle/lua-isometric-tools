---@see https://edubart.github.io/lester/
local lester = require("lib.lester")
local describe, it, expect = lester.describe, lester.it, lester.expect

lester.parse_args()

local Vector = require("lib.vector")

-- Customize lester configuration.
lester.show_traceback = true
lester.stop_on_fail = true

describe("vectors", function()
    it("can create a vector", function()
        local vec = Vector.new(0, 0)

        expect.equal(vec.x, 0)
        expect.equal(vec.y, 0)
        expect.equal(vec.z, 1)
        expect.equal(tostring(vec), "0,0,1")
    end)

    it("can create a zero vector", function()
        local vec = Vector.zero()

        expect.equal(vec.x, 0)
        expect.equal(vec.y, 0)
        expect.equal(vec.z, 1)
        expect.equal(tostring(vec), "0,0,1")
    end)

    it("can duplicate a vector", function()
        local vec = Vector.new(100, 100)

        local vec2 = vec:duplicate()

        expect.equal(vec.x, vec2.x)
        expect.equal(vec.y, vec2.y)
        expect.equal(vec.z, vec2.z)
        expect.equal(tostring(vec), tostring(vec2))
    end)

    it("can create a vector from a key", function()
        local vec = Vector.fromKey("0,0,1")

        expect.equal(vec.x, 0)
        expect.equal(vec.y, 0)
        expect.equal(vec.z, 1)
    end)

    it("can add two vectors", function()
        local vec1 = Vector.new(1, 1)
        local vec2 = Vector.new(1, 1)

        local combined = vec1 + vec2

        expect.equal(combined.x, 2)
        expect.equal(combined.y, 2)
        expect.equal(combined.z, 1)
    end)

    it("can add a number and a vector", function()
        local vec1 = Vector.new(1, 1)

        local combined = vec1 + 1

        expect.equal(combined.x, 2)
        expect.equal(combined.y, 2)
        expect.equal(combined.z, 1)
    end)

    it("can subtract two vectors", function()
        local vec1 = Vector.new(1, 1)
        local vec2 = Vector.new(1, 1)

        local combined = vec1 - vec2

        expect.equal(combined.x, 0)
        expect.equal(combined.y, 0)
        expect.equal(combined.z, 1)
    end)

    it("can subtract a number and a vector", function()
        local vec1 = Vector.new(1, 1)

        local combined = vec1 - 1

        expect.equal(combined.x, 0)
        expect.equal(combined.y, 0)
        expect.equal(combined.z, 1)
    end)

    it("can multiply two vectors", function()
        local vec1 = Vector.new(2, 3)
        local vec2 = Vector.new(4, 5)

        local combined = vec1 * vec2

        expect.equal(combined.x, 8)
        expect.equal(combined.y, 15)
        expect.equal(combined.z, 1)
    end)

    it("can multiply a number and a vector", function()
        local vec1 = Vector.new(1, 1)

        local combined = vec1 * 2

        expect.equal(combined.x, 2)
        expect.equal(combined.y, 2)
        expect.equal(combined.z, 1)
    end)

    it("can compare two vectors", function()
        local vec1 = Vector.new(1, 1)
        local vec2 = Vector.new(1, 1)

        expect.equal(true, vec1 == vec2)
    end)

    it("can calculate the distance to another vector", function()
        local vec1 = Vector.new(1, 1)
        local vec2 = Vector.new(3, 3)

        expect.equal(3, vec1:distanceTo(vec2))
    end)

    it("can calculate the length/magnitude", function()
        local vec1 = Vector.new(1, 1)

        -- cant compare floats like this so just use a string
        expect.equal("1.4142135623731", tostring(vec1:length()))
    end)

    it("can calculate the negation", function()
        local vec1 = Vector.new(1, 1)

        -- cant compare floats like this so just use a string
        expect.equal("-1,-1,-1", tostring(vec1:negation()))
    end)

    it("can calculate the normalization", function()
        local vec1 = Vector.new(1, 3)

        -- cant compare floats like this so just use a string
        expect.equal("0.30151134457776", tostring(vec1:normalization().x))
        expect.equal("0.90453403373329", tostring(vec1:normalization().y))
        expect.equal("0.30151134457776", tostring(vec1:normalization().z))
    end)

    it("can calculate the subtraction of a vector", function()
        local vec1 = Vector.new(1, 1)
        local vec2 = Vector.new(2, 2)

        expect.equal("-1,-1,0", tostring(vec1:subtraction(vec2)))
    end)

    it("can calculate the multiplication of a vector", function()
        local vec1 = Vector.new(1, 1)
        local vec2 = Vector.new(2, 2)

        expect.equal("2,2,1", tostring(vec1:multiplication(vec2)))
    end)

    it("can calculate the division of a vector", function()
        local vec1 = Vector.new(1, 1)
        local vec2 = Vector.new(2, 2)

        -- cant compare floats like this so just use a string
        expect.equal("0.5", tostring(vec1:division(vec2).x))
        expect.equal("0.5", tostring(vec1:division(vec2).y))
        expect.equal("1.0", tostring(vec1:division(vec2).z))
    end)

    it("can calculate the dot", function()
        local vec1 = Vector.new(1, 1)
        local vec2 = Vector.new(2, 2)

        expect.equal(5, vec1:dot(vec2))
    end)

    it("can calculate the dot normalized", function()
        local vec1 = Vector.new(1, 1)
        local vec2 = Vector.new(2, 2)

        -- float compares don't work so we use strings
        expect.equal("1.25", tostring(vec1:dotNormalized(vec2)))
    end)

    it("can calculate the cross", function()
        local vec1 = Vector.new(1, 1)
        local vec2 = Vector.new(2, 2)

        expect.equal("-1,1,0", tostring(vec1:cross(vec2)))
    end)

    it("can get the neighbours", function()
        local vec1 = Vector.new(1, 1)

        local expectedResults = {
            "2,1,1",
            "0,1,1",
            "1,2,1",
            "1,0,1",
        }

        local neighbours = vec1:neighbours()

        for i, v in ipairs(neighbours) do
            expect.equal(expectedResults[i], tostring(v))
        end
    end)

    it("can check if a vector is a neighbour", function()
        local vec1 = Vector.new(1, 1)
        local vec2 = Vector.new(2, 1)
        local vec3 = Vector.new(5, 5)

        expect.equal(false, vec1:isNeighbour(vec1))
        expect.equal(true, vec1:isNeighbour(vec2))
        expect.equal(false, vec1:isNeighbour(vec3))
    end)
end)

lester.report() -- Print overall statistic of the tests run.
lester.exit() -- Exit with success if all tests passed.
