---@see https://edubart.github.io/lester/
local lester = require("lib.lester")
local describe, it, expect = lester.describe, lester.it, lester.expect

lester.parse_args()

local fp = require("lib.fp")

-- Customize lester configuration.
lester.show_traceback = true
lester.stop_on_fail = true

describe("fp", function()
    it("can join", function()
        local result = fp.join(",")({ 1, 2, 3 })

        expect.equal("1,2,3", result)
    end)

    it("can map", function()
        local result = fp.map(function(n)
            return n + 1
        end)({ 1, 2, 3 })

        expect.equal({ 2, 3, 4 }, result)
    end)

    it("can clone", function()
        local orig = { 1, 2, 3 }
        local result = fp.clone({ 1, 2, 3 })

        expect.equal(orig, result)
    end)

    it("can find", function()
        local result = fp.find(function(n)
            return n == 2
        end)({ 1, 2, 3 })

        expect.equal(2, result)
    end)

    it("can find for object", function()
        local result = fp.find(function(n)
            return n == 2
        end, true)({ one = 1, two = 2, three = 3 })

        expect.equal(2, result)
    end)

    it("can find key", function()
        local result = fp.findKey(function(n)
            return n == 2
        end)({ 1, 2, 3 })

        expect.equal(2, result)
    end)

    it("can find key for object", function()
        local result = fp.findKey(function(n)
            return n == 2
        end, true)({ one = 1, two = 2, three = 3 })

        expect.equal("two", result)
    end)

    it("can get the length", function()
        local result = fp.length()({ 1, 2, 3 })

        expect.equal(3, result)
    end)

    it("can get the length for object", function()
        local result = fp.length(true)({ one = 1, two = 2, three = 3 })

        expect.equal(3, result)
    end)

    it("can push", function()
        local result = fp.push(4)({ 1, 2, 3, 4 })

        expect.equal(4, result[4])
    end)

    it("can filter", function()
        local result = fp.filter(function(n)
            return n == 2
        end)({ 1, 2, 3 })

        expect.equal(2, result[1])
    end)

    it("can filter for object", function()
        local result = fp.filter(function(n)
            return n == 2
        end, true)({ one = 1, two = 2, three = 3 })

        expect.equal(2, result["two"])
    end)

    it("can remove", function()
        local result = fp.remove(function(n)
            return n == 2
        end)({ 1, 2, 3 })

        expect.equal(1, result[1])
        expect.equal(3, result[2])
        expect.equal(nil, result[3])
    end)

    it("can remove for object", function()
        local result = fp.without(function(n)
            return n == 2
        end, true)({ one = 1, two = 2, three = 3 })

        expect.equal(1, result["one"])
        expect.equal(3, result["three"])
        expect.equal(nil, result["two"])
    end)

    it("can sort", function()
        local result = fp.sort()({ 3, 2, 1 })

        expect.equal(1, result[1])
        expect.equal(2, result[2])
        expect.equal(3, result[3])
    end)

    it("can sort with function", function()
        local result = fp.sort(function(a, b)
            return a > b
        end)({ 1, 2, 3 })

        expect.equal(3, result[1])
        expect.equal(2, result[2])
        expect.equal(1, result[3])
    end)

    it("can min", function()
        local result = fp.min()({ 3, 2, 1 })

        expect.equal(1, result)
    end)

    it("can max", function()
        local result = fp.max()({ 3, 2, 1 })

        expect.equal(3, result)
    end)

    it("can first", function()
        local result = fp.first()({ 3, 2, 1 })

        expect.equal(3, result)
    end)

    it("can first with function", function()
        local result = fp.first(function(n)
            return n == 2
        end)({ 3, 2, 1 })

        expect.equal(2, result)
    end)

    it("can last", function()
        local result = fp.last()({ 3, 2, 1 })

        expect.equal(1, result)
    end)

    it("can check contains", function()
        local result = fp.contains(2)({ 3, 2, 1 })

        expect.equal(true, result)
    end)

    it("can check contains with function", function()
        local result = fp.contains(function(n)
            return n > 2
        end)({ 3, 2, 1 })

        expect.equal(true, result)
    end)
end)

lester.report() -- Print overall statistic of the tests run.
lester.exit() -- Exit with success if all tests passed.
