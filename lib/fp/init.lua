---@meta

---@see https://gist.github.com/sarimarton/fc02d27fa7c06d296d99f858b1143e5a
-- Lua FP lib
-- API is self explanatory.

-- Example usage:
--    fp.pipe({
--      fp.constant(items),
--      fp.map(function(x) return '"' .. x.text .. '"' end),
--      fp.join(' ')
--    })()

local fp = {}

---Returns the input value unchanged
---@generic T
---@param v T
---@return T
fp.identity = function(v)
    return v
end

--- Performs a left-to-right fold over an array or object
---@generic T, U
---@param fun fun(acc: U, value: T, key: number|string): U
---@param start U
---@param asObject? boolean # If true, uses pairs() instead of ipairs()
---@return fun(arr: T[]|table): U
fp.foldl = function(fun, start, asObject)
    local pairsFn = asObject and pairs or ipairs
    return function(arr)
        local acc = start
        if type(arr) == "function" then
            local k = 1
            for v in arr do
                acc = fun(acc, v, k)
                k = k + 1
            end
        else
            for k, v in pairsFn(arr) do
                acc = fun(acc, arr[k], k)
            end
        end
        return acc
    end
end

---Creates a function that always returns the same value
---@generic T
---@param v T
---@return fun(): T
fp.constant = function(v)
    return function()
        return v
    end
end

---Joins array elements with a separator string
---@generic T
---@param str string # The separator string
---@return fun(arr: T[]): string
fp.join = function(str)
    return function(arr)
        return table.concat(arr, str)
    end
end

---Maps a function over an array or object
---@generic T, U
---@param fn fun(value: T, key?: number|string): U
---@param asObject? boolean # If true, uses pairs() instead of ipairs()
---@return fun(arr: T[]|table): U[]|table
fp.map = function(fn, asObject)
    return fp.foldl(function(acc, v, k)
        acc[k] = fn(v)
        return acc
    end, {}, asObject)
end

---Converts an iterator to a table
---@generic T
---@param iter Iterator<T>
---@return T[]
fp.iteratorToTable = fp.map(fp.identity)

---Creates a shallow copy of a table
---@generic T
---@param tbl T
---@return T
fp.clone = fp.map(fp.identity, true)

---Helper function for cloneDeep
---@generic T
---@param val T
---@return T
local function cloneDeep(val)
    if not (type(val) == "table") then
        return val
    else
        return fp.map(cloneDeep, true)(val)
    end
end

---Creates a deep copy of a table
---@generic T
---@param val T
---@return T
fp.cloneDeep = cloneDeep

---Composes functions from left to right
---@param fns function[] # Array of functions to compose
---@return function # The composed function
fp.pipe = function(fns)
    return fp.foldl(function(acc, v)
        return function(y)
            return v(acc(y))
        end
    end, fp.identity)(fns)
end

---Finds the first element that matches a predicate
---@generic T
---@param pred fun(value: T, key: number|string): boolean
---@param asObject? boolean # If true, uses pairs() instead of ipairs()
---@return fun(arr: T[]|table): T|nil
fp.find = function(pred, asObject)
    return fp.foldl(function(acc, v, k)
        return acc or (pred(v, k) and v)
    end, nil, asObject)
end

---Finds the key of the first element that matches a predicate
---@generic T
---@param pred fun(value: T, key: number|string): boolean
---@param asObject? boolean # If true, uses pairs() instead of ipairs()
---@return fun(arr: T[]|table): number|string|nil
fp.findKey = function(pred, asObject)
    return fp.foldl(function(acc, v, k)
        return acc or (pred(v, k) and k)
    end, nil, asObject)
end

---Returns the length of a table
---@param asObject? boolean # If true, uses pairs() instead of ipairs()
---@return fun(tbl: table): number
fp.length = function(asObject)
    return fp.foldl(function(acc)
        return acc + 1
    end, 0, asObject)
end

---Adds an item to the end of an array
---@generic T
---@param item T
---@return fun(arr: T[]): T[]
fp.push = function(item)
    return function(arr)
        arr[#arr + 1] = item
        return arr
    end
end

---Filters elements that match a predicate
---@generic T
---@param pred fun(value: T, key: number|string): boolean
---@param asObject? boolean # If true, uses pairs() instead of ipairs()
---@return fun(arr: T[]|table): T[]
fp.filter = function(pred, asObject)
    return fp.foldl(function(acc, v, k)
        if pred(v, k) then
            if asObject then
                acc[k] = v
            else
                acc[#acc + 1] = v
            end
        end
        return acc
    end, {}, asObject)
end

---Filters elements that don't match a predicate
---@generic T
---@param pred fun(value: T, key: number|string): boolean
---@param asObject? boolean # If true, uses pairs() instead of ipairs()
---@return fun(arr: T[]|table): T[]
fp.without = function(pred, asObject)
    return fp.filter(function(v, k)
        return not pred(v, k)
    end, asObject)
end

---Filters elements that don't match a predicate
---@generic T
---@param pred fun(value: T, key: number|string): boolean
---@param asObject? boolean # If true, uses pairs() instead of ipairs()
---@return fun(arr: T[]|table): T[]
fp.remove = fp.without

---Sorts an array using an optional comparison function
---@generic T
---@param pred? fun(a: T, b: T): boolean # Optional comparison function that returns true when a < b
---@return fun(arr: T[]): T[] # Returns a new sorted array
fp.sort = function(pred)
    return function(arr)
        local sorted = fp.clone(arr)
        if pred then
            table.sort(sorted, pred)
        else
            table.sort(sorted, function(a, b)
                return a < b
            end)
        end
        return sorted
    end
end

---Returns the minimum value in an array
---@generic T
---@return fun(arr: T[]): T # Returns the minimum value
fp.min = function()
    return function(arr)
        local sorted = fp.sort()(arr)
        return table.remove(sorted, 1)
    end
end

---Returns the maximum value in an array
---@generic T
---@return fun(arr: T[]): T # Returns the maximum value
fp.max = function()
    return function(arr)
        local sorted = fp.sort(function(a, b)
            return a > b
        end)(arr)
        return table.remove(sorted, 1)
    end
end

---Returns the first element of an array, or nil if array is empty
---@generic T
---@param pred? fun(value: T, key: number|string): boolean
---@param asObject? boolean # If true, uses pairs() instead of ipairs()
---@return fun(arr: T[]): T|T[]|nil # Returns the first element, array of first n elements, or nil if empty
fp.first = function(pred, asObject)
    local pairsFn = asObject and pairs or ipairs
    return function(acc)
        if type(pred) == "function" then
            for k, v in pairsFn(acc) do
                local test = pred(k, v)
                if test then
                    return v
                end
            end
        end

        local copy = fp.clone(acc)
        return table.remove(copy, 1)
    end
end

---Returns the last element of an array or the last key-value pair of an object
---@generic T
---@param asObject? boolean # If true, treats input as object instead of array
---@return fun(acc: T[]|table): T|T[]|nil # Returns last element(s) or nil if empty
fp.last = function(asObject)
    return function(acc)
        if asObject then
            -- Handle objects using pairs
            local lastKey, lastValue = nil, nil
            for k, v in ipairs(acc) do
                lastKey, lastValue = k, v
            end
            return { [lastKey] = lastValue }
        else
            -- Handle arrays
            local len = #acc
            if len == 0 then
                return nil
            end
            return acc[len]
        end
    end
end

---Checks if an array contains a value or if any element matches a predicate
---@generic T
---@param pred T|function # Value to find or predicate function(value: T): boolean
---@param asObject? boolean # If true, uses pairs() instead of ipairs()
---@return fun(arr: T[]): boolean # Returns true if the value is found or predicate matches
fp.contains = function(pred, asObject)
    return function(arr)
        if type(pred) == "function" then
            return fp.length()(fp.filter(pred, asObject)(arr)) > 0
        else
            return fp.length()(fp.filter(function(v)
                return v == pred
            end, asObject)(arr)) > 0
        end
    end
end

return fp
