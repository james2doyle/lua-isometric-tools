local lester = require 'lib.lester'
local describe, it, expect = lester.describe, lester.it, lester.expect

lester.parse_args()

local Vector = require 'lib.vector'

-- Customize lester configuration.
lester.show_traceback = false
lester.stop_on_fail = true

describe('vectors', function()
    it('can create a vector', function()
        local vec = Vector.new(0, 0)

        expect.equal(vec.x, 0)
        expect.equal(vec.y, 0)
        expect.equal(vec.z, 1)
        expect.equal(tostring(vec), '0,0,1')
    end)

    it('can create a zero vector', function()
        local vec = Vector.zero()

        expect.equal(vec.x, 0)
        expect.equal(vec.y, 0)
        expect.equal(vec.z, 1)
        expect.equal(tostring(vec), '0,0,1')
    end)

    it('can create a vector from a key', function()
        local vec = Vector.fromKey('0,0,1')

        expect.equal(vec.x, 0)
        expect.equal(vec.y, 0)
        expect.equal(vec.z, 1)
    end)

    it('can add two vectors', function()
        local vec1 = Vector.new(1, 1)
        local vec2 = Vector.new(1, 1)

        local combined = vec1 + vec2

        expect.equal(combined.x, 2)
        expect.equal(combined.y, 2)
        expect.equal(combined.z, 1)
    end)

    it('can add a number and a vector', function()
        local vec1 = Vector.new(1, 1)

        local combined = vec1 + 1

        expect.equal(combined.x, 2)
        expect.equal(combined.y, 2)
        expect.equal(combined.z, 1)
    end)

    it('can subtract two vectors', function()
        local vec1 = Vector.new(1, 1)
        local vec2 = Vector.new(1, 1)

        local combined = vec1 - vec2

        expect.equal(combined.x, 0)
        expect.equal(combined.y, 0)
        expect.equal(combined.z, 1)
    end)

    it('can subtract a number and a vector', function()
        local vec1 = Vector.new(1, 1)

        local combined = vec1 - 1

        expect.equal(combined.x, 0)
        expect.equal(combined.y, 0)
        expect.equal(combined.z, 1)
    end)

    it('can multiply two vectors', function()
        local vec1 = Vector.new(2, 3)
        local vec2 = Vector.new(4, 5)

        local combined = vec1 * vec2

        expect.equal(combined.x, 8)
        expect.equal(combined.y, 15)
        expect.equal(combined.z, 1)
    end)

    it('can multiply a number and a vector', function()
        local vec1 = Vector.new(1, 1)

        local combined = vec1 * 2

        expect.equal(combined.x, 2)
        expect.equal(combined.y, 2)
        expect.equal(combined.z, 1)
    end)

    it('can compare two vectors', function()
        local vec1 = Vector.new(1, 1)
        local vec2 = Vector.new(1, 1)

        expect.equal(true, vec1 == vec2)
    end)
end)

lester.report() -- Print overall statistic of the tests run.
lester.exit()   -- Exit with success if all tests passed.
