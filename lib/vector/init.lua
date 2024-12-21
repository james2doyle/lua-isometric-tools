local sqrt = math.sqrt;

local Vector = { __type = "Vector" }
Vector.__index = Vector
setmetatable(Vector, { __index = Vector })

---@see https://github.com/mlepage/linear-algebra/blob/master/la.lua
---@see https://github.com/vertfire/LuaLinearAlgebra/blob/main/Vector.lua

---@class Vector
---@field x number
---@field y number
---@field z number
---@field magnitude function
---@field length function
---@field neighbours function
---@field dot function
---@field dotNormalized function
---@field cross function
---@field negation function
---@field normalization function
---@field subtraction function
---@field multiplication function
---@field division function

---@param x number
---@param y number
---@param z number|nil
---@return Vector
function Vector.new(x, y, z)
    local this = {}
    this.x = x
    this.y = y
    this.z = z or 1

    setmetatable(this, {
        __index = Vector,
        __add = function(t1, t2)
            return Vector.new(t1.x + t2.x, t1.y + t2.y)
        end,
        __sub = function(t1, t2)
            return Vector.new(t1.x - t2.x, t1.y - t2.y)
        end,
        __mul = function(t1, t2)
            return Vector.new(t1.x * t2.x, t1.y * t2.y)
        end,
        __tostring = function(t)
            return string.format("%i,%i,%i", t.x, t.y, t.z)
        end
    })

    return this
end

---@param key string
---@return Vector
function Vector.fromKey(key)
    local results = {}
    for str in string.gmatch(key, "([^,]+)") do
        table.insert(results, tonumber(str))
    end

    return Vector.new(results[1], results[2], results[3])
end

---@return number
function Vector:magnitude()
    return sqrt(self.x * self.x + self.y * self.y)
end

---@return number
function Vector:length()
    return self:magnitude()
end

---@return {number:Vector}
function Vector:neighbours()
    return {
        self + Vector.new(1, 0),
        self + Vector.new(-1, 0),
        self + Vector.new(0, 1),
        self + Vector.new(0, -1),
    }
end

---@param v Vector
---@return number
function Vector:dot(v)
    return self.x * v.x + self.y * v.y + self.z * v.z
end

---@param v Vector
---@return number
function Vector:dotNormalized(v)
    local lhsLength = self:length()
    local rhsLength = v:length()
    local xDotPart = (self.x / lhsLength) * (v.x / rhsLength)
    local yDotPart = (self.y / lhsLength) * (v.y / rhsLength)

    return xDotPart + yDotPart
end

---@param b Vector
---@return Vector
function Vector:cross(b)
    return Vector.new(self.y * b.z - self.z * b.y, self.z * b.x - self.x * b.z, self.x * b.y - self.y * b.x)
end

---@param r Vector
---@return Vector
function Vector:negation(r)
    if r then
        r.x, r.y, r.z = -self.x, -self.y, -self.z

        return Vector.new(r.x, r.y, r.z)
    end

    return Vector.new(-self.x, -self.y, -self.z)
end

---@param r Vector
---@return Vector
function Vector:normalization(r)
    local u1, u2, u3 = self.x, self.y, self.z
    local a = sqrt(u1 ^ 2 + u2 ^ 2 + u3 ^ 2)

    if r then
        r.x, r.y, r.z = u1 / a, u2 / a, u3 / a

        return Vector.new(r.x, r.y, r.z)
    end

    return Vector.new(u1 / a, u2 / a, u3 / a)
end

---@param v Vector
---@param r Vector
---@return Vector
function Vector:subtraction(v, r)
    if r then
        r.x, r.y, r.z = self.x - v.x, self.y - v.y, self.z - v.z

        return Vector.new(r.x, r.y, r.z)
    end

    return Vector.new(self.x - v.x, self.y - v.y, self.z - v.z)
end

---@param a Vector
---@param r Vector
---@return Vector
function Vector:multiplication(a, r)
    if r then
        r.x, r.y, r.z = self.x * a, self.y * a, self.z * a

        return Vector.new(r.x, r.y, r.z)
    end

    return Vector.new(self.x * a, self.y * a, self.z * a)
end

---@param a Vector
---@param r Vector
---@return Vector
function Vector:division(a, r)
    if r then
        r.x, r.y, r.z = self.x / a, self.y / a, self.z / a

        return Vector.new(r.x, r.y, r.z)
    end

    return Vector.new(self.x / a, self.y / a, self.z / a)
end

return Vector
