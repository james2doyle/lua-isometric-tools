local lester = require 'lib.lester'
local describe, it, expect = lester.describe, lester.it, lester.expect

-- Customize lester configuration.
lester.show_traceback = false

describe('my project', function()
  lester.before(function()
    -- This function is run before every test.
  end)

  describe('module1', function() -- Describe blocks can be nested.
    it('feature1', function()
      expect.equal('something', 'something') -- Pass.
    end)

    it('feature2', function()
      expect.truthy(false) -- Fail.
    end)

    local feature3_test_enabled = false
    it('feature3', function() -- This test will be skipped.
      expect.truthy(false) -- Fail.
    end, feature3_test_enabled)
  end)
end)

lester.report() -- Print overall statistic of the tests run.
lester.exit() -- Exit with success if all tests passed.