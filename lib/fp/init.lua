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

fp.identity = function(v)
    return v
end

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

fp.constant = function(v)
    return function()
        return v
    end
end

fp.join = function(str)
    -- return fp.foldl(function(acc, x, k) return acc .. (k > 1 and str or '') .. x end, '')
    return function(arr)
        return table.concat(arr, str)
    end
end

fp.map = function(fn, asObject)
    return fp.foldl(function(acc, v, k)
        acc[k] = fn(v);
        return acc
    end, {}, asObject)
end

fp.iteratorToTable = fp.map(fp.identity)

fp.clone = fp.map(fp.identity, true)

local function cloneDeep(val)
    if not (type(val) == 'table') then
        return val
    else
        return fp.map(cloneDeep, true)(val)
    end
end

fp.cloneDeep = cloneDeep

fp.pipe = function(fns)
    return fp.foldl(function(acc, v)
        return function(y)
            return v(acc(y))
        end
    end, fp.identity)(fns)
end

fp.find = function(pred, asObject)
    return fp.foldl(function(acc, v, k)
        return acc or (pred(v, k) and v)
    end, nil, asObject)
end

fp.findKey = function(pred, asObject)
    return fp.foldl(function(acc, v, k)
        return acc or (pred(v, k) and k)
    end, nil, asObject)
end

-- Example: fp.length()(table)
fp.length = function(asObject)
    return fp.foldl(function(acc)
        return acc + 1
    end, 0, asObject)
end

fp.push = function(item)
    return function(arr)
        arr[#arr + 1] = item
        return arr
    end
end

fp.filter = function(pred, asObject)
    return fp.foldl(function(acc, v, k)
        if pred(v, k) then
            acc[#acc + 1] = v
        end
        return acc
    end, {}, asObject)
end

fp.without = function(pred, asObject)
    return fp.filter(function(v, k)
        return not pred(v, k)
    end, asObject)
end

-- fp.assign = function(obj)
--   return fp.foldl()
--     return fp.pipe(
--       fp.constant(arr),
--       fp.clone,
--       fp.
--     )
--   end
-- end

return fp