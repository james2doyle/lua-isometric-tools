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

---@class fp
---@field identity function
---@field foldl function
---@field constant function
---@field join function
---@field map function
---@field iteratorToTable function
---@field clone function
---@field cloneDeep function
---@field pipe function
---@field find function
---@field findKey function
---@field length function
---@field push function
---@field filter function
---@field without function
---@field sort function
---@field remove function
---@field min function
---@field max function
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
        if type(arr) == 'function' then
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
---@param str string # The separator string
---@return fun(arr: string[]): string
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
        acc[k] = fn(v);
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
    if not (type(val) == 'table') then
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
            acc[#acc + 1] = v
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
            table.sort(sorted)
        end
        return sorted
    end
end

---Returns the minimum value in an array
---@generic T
---@param pred? fun(a: T, b: T): boolean # Optional comparison function that returns true when a < b
---@return fun(arr: T[]): T # Returns the minimum value
fp.min = function(pred)
    return function(arr)
        return fp.foldl(function(acc, v)
            if acc == nil then return v end
            if pred then
                return pred(v, acc) and v or acc
            else
                return v < acc and v or acc
            end
        end, nil)(arr)
    end
end

---Returns the maximum value in an array
---@generic T
---@param pred? fun(a: T, b: T): boolean # Optional comparison function that returns true when a < b
---@return fun(arr: T[]): T # Returns the maximum value
fp.max = function(pred)
    return function(arr)
        return fp.foldl(function(acc, v)
            if acc == nil then return v end
            if pred then
                return pred(acc, v) and v or acc
            else
                return v > acc and v or acc
            end
        end, nil)(arr)
    end
end

return fp