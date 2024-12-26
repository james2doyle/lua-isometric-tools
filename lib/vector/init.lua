--- A Vector class that implements 2D and 3D vector operations with operator overloading
---
--- Features:
--- - Support for both 2D and 3D vectors (z defaults to 1 for 2D)
--- - Operator overloading for +, -, *, == operations
--- - Common vector operations: dot product, cross product, normalization
--- - Distance and magnitude calculations
--- - Vector arithmetic (addition, subtraction, multiplication, division)
--- - Neighbor calculation for grid-based operations
---
--- Example usage:
--- ```lua
--- local v1 = Vector.new(1, 2)    -- 2D vector
--- local v2 = Vector.new(1, 2, 3) -- 3D vector
--- local sum = v1 + v2            -- Operator overloading
--- local dist = v1:distanceTo(v2) -- Method call
--- ```

---@see https://github.com/mlepage/linear-algebra/blob/master/la.lua
---@see https://github.com/vertfire/LuaLinearAlgebra/blob/main/Vector.lua

---@class Vector
---@field x number The x coordinate of the vector
---@field y number The y coordinate of the vector
---@field z number The z coordinate of the vector (defaults to 1 for 2D vectors)
---@field magnitude fun(self: Vector): number Calculates the magnitude (length) of the vector using sqrt(x² + y²)
---@field length fun(self: Vector): number Alias for magnitude()
---@field duplicate fun(self: Vector): Vector Create a copy of the current vector
---@field distanceTo fun(self: Vector, v: Vector): number Calculates Euclidean distance between two points using sqrt((x₂-x₁)² + (y₂-y₁)² + (z₂-z₁)²)
---@field neighbours fun(self: Vector): Vector[] Returns four adjacent neighbors in 2D space at (x±1,y) and (x,y±1)
---@field isNeighbour fun(self: Vector, v: Vector): boolean Checks if the given vector is adjacent to this vector in 2D space
---@field dot fun(self: Vector, v: Vector): number Calculates dot product (x₁x₂ + y₁y₂ + z₁z₂), measuring how parallel vectors are
---@field dotNormalized fun(self: Vector, v: Vector): number Calculates normalized dot product, returns cosine of angle between vectors
---@field cross fun(self: Vector, b: Vector): Vector Calculates cross product, returns vector perpendicular to both inputs
---@field negation fun(self: Vector): Vector Returns vector pointing in opposite direction (-x, -y, -z)
---@field normalization fun(self: Vector): Vector Returns unit vector in same direction (x/|v|, y/|v|, z/|v| where |v| is length)
---@field subtraction fun(self: Vector, v: Vector): Vector Subtracts vector v (x₁-x₂, y₁-y₂, z₁-z₂)
---@field multiplication fun(self: Vector, v: Vector): Vector Multiplies vectors component-wise (x₁x₂, y₁y₂, z₁z₂)
---@field division fun(self: Vector, v: Vector): Vector Divides vectors component-wise (x₁/x₂, y₁/y₂, z₁/z₂)
---@field fromKey fun(key: string): Vector Static method to create Vector from string in "x,y,z" format
---@field zero fun(): Vector Static method that returns a zero vector (0,0,0)
---@field up fun(self: Vector): Vector Returns a new vector moved one unit up (+y)
---@field down fun(self: Vector): Vector Returns a new vector moved one unit down (-y)
---@field left fun(self: Vector): Vector Returns a new vector moved one unit left (-x)
---@field right fun(self: Vector): Vector Returns a new vector moved one unit right (+x)

-- Import math.sqrt for cleaner usage
local sqrt = math.sqrt

-- Vector class definition
local Vector = { __type = "Vector" }
Vector.__index = Vector
setmetatable(Vector, { __index = Vector })

---@param x number X coordinate
---@param y number Y coordinate
---@param z number|nil Z coordinate (optional, defaults to 1)
---@return Vector
function Vector.new(x, y, z)
    local this = {}
    this.x = x
    this.y = y
    this.z = z or 1 -- Makes 2D vectors possible by defaulting z to 1

    -- Set up operator overloading for vector arithmetic
    -- Allows using +, -, *, == operators directly on vectors
    setmetatable(this, {
        __index = Vector,
        -- Implements v1 + v2 or number + vector or vector + number
        __add = function(t1, t2)
            if type(t1) == "number" then
                t1 = Vector.new(t1, t1)
            end
            if type(t2) == "number" then
                t2 = Vector.new(t2, t2)
            end
            return Vector.new(t1.x + t2.x, t1.y + t2.y)
        end,
        -- Implements v1 - v2 or number - vector or vector - number
        __sub = function(t1, t2)
            if type(t1) == "number" then
                t1 = Vector.new(t1, t1)
            end
            if type(t2) == "number" then
                t2 = Vector.new(t2, t2)
            end
            return Vector.new(t1.x - t2.x, t1.y - t2.y)
        end,
        -- Implements v1 * v2 or number * vector or vector * number
        __mul = function(t1, t2)
            if type(t1) == "number" then
                t1 = Vector.new(t1, t1)
            end
            if type(t2) == "number" then
                t2 = Vector.new(t2, t2)
            end
            return Vector.new(t1.x * t2.x, t1.y * t2.y)
        end,
        -- Implements equality comparison (v1 == v2)
        __eq = function(t1, t2)
            if type(t1) == "number" then
                t1 = Vector.new(t1, t1)
            end
            if type(t2) == "number" then
                t2 = Vector.new(t2, t2)
            end
            return t1.x == t2.x and t1.y == t2.y and t1.z == t2.z
        end,
        -- Implements string conversion (tostring(vector))
        __tostring = function(t)
            return string.format("%i,%i,%i", t.x, t.y, t.z)
        end,
    })

    return this
end

-- Creates a new Vector from a string key in format "x,y,z"
---@param key string String in format "x,y,z"
---@return Vector
function Vector.fromKey(key)
    local results = {}
    for str in string.gmatch(key, "([^,]+)") do
        table.insert(results, tonumber(str))
    end

    return Vector.new(results[1], results[2], results[3])
end

-- Returns a zero vector (0,0,0)
---@return Vector
function Vector.zero()
    return Vector.new(0, 0)
end

-- Returns a copy of the vector
---@return Vector
function Vector:duplicate()
    return Vector.new(self.x, self.y, self.z)
end

-- Returns a new vector moved one unit up (+y)
---@return Vector
function Vector:up()
    return self + Vector.new(0, 1)
end

-- Returns a new vector moved one unit down (-y)
---@return Vector
function Vector:down()
    return self + Vector.new(0, -1)
end

-- Returns a new vector moved one unit left (-x)
---@return Vector
function Vector:left()
    return self + Vector.new(-1, 0)
end

-- Returns a new vector moved one unit right (+x)
---@return Vector
function Vector:right()
    return self + Vector.new(1, 0)
end

-- Calculates the magnitude (length) of the vector
-- Math: sqrt(x² + y²)
---@return number
function Vector:magnitude()
    return sqrt(self.x * self.x + self.y * self.y)
end

-- Calculates the Euclidean distance between two points
-- Math: sqrt((x₂-x₁)² + (y₂-y₁)² + (z₂-z₁)²)
---@param v Vector Target vector
---@return number
function Vector:distanceTo(v)
    return math.ceil(sqrt((v.x - self.x) ^ 2 + (v.y - self.y) ^ 2 + (v.z - self.z) ^ 2))
end

-- Alias for magnitude()
---@return number
function Vector:length()
    return self:magnitude()
end

-- Returns the four adjacent neighbors in 2D space
-- Returns vectors at (x+1,y), (x-1,y), (x,y+1), (x,y-1)
---@return {number:Vector}
function Vector:neighbours()
    return {
        self + Vector.new(1, 0),
        self + Vector.new(-1, 0),
        self + Vector.new(0, 1),
        self + Vector.new(0, -1),
    }
end

-- Checks if the given vector is a neighbor (adjacent in 2D space)
-- Returns true if the vector is exactly one unit away in x or y direction
---@param v Vector Vector to check
---@return boolean
function Vector:isNeighbour(v)
    -- Get list of neighbors
    local neighborList = self:neighbours()

    -- Check if the given vector matches any neighbor
    for _, neighbor in ipairs(neighborList) do
        if neighbor == v then
            return true
        end
    end

    return false
end

-- Calculates the dot product of two vectors
-- Math: x₁x₂ + y₁y₂ + z₁z₂
-- This measures how parallel two vectors are
---@param v Vector
---@return number
function Vector:dot(v)
    return self.x * v.x + self.y * v.y + self.z * v.z
end

-- Calculates the normalized dot product
-- Math: (x₁/|v₁|)(x₂/|v₂|) + (y₁/|v₁|)(y₂/|v₂|) + (z₁/|v₁|)(z₂/|v₂|)
-- Returns cosine of angle between vectors
---@param v Vector
---@return number
function Vector:dotNormalized(v)
    local lhsLength = self:length()
    local rhsLength = v:length()
    local xDotPart = (self.x / lhsLength) * (v.x / rhsLength)
    local yDotPart = (self.y / lhsLength) * (v.y / rhsLength)
    local zDotPart = (self.z / lhsLength) * (v.z / rhsLength)

    return xDotPart + yDotPart + zDotPart
end

-- Calculates the cross product of two vectors
-- Math: (y₁z₂-z₁y₂, z₁x₂-x₁z₂, x₁y₂-y₁x₂)
-- Returns a vector perpendicular to both input vectors
---@param b Vector
---@return Vector
function Vector:cross(b)
    return Vector.new(self.y * b.z - self.z * b.y, self.z * b.x - self.x * b.z, self.x * b.y - self.y * b.x)
end

-- Returns the negation of the vector
-- Math: (-x, -y, -z)
---@return Vector
function Vector:negation()
    return Vector.new(-self.x, -self.y, -self.z)
end

-- Returns the normalized vector (unit vector in same direction)
-- Math: (x/|v|, y/|v|, z/|v|) where |v| is vector length
---@return Vector
function Vector:normalization()
    local u1, u2, u3 = self.x, self.y, self.z
    local a = sqrt(u1 ^ 2 + u2 ^ 2 + u3 ^ 2)

    return Vector.new(u1 / a, u2 / a, u3 / a)
end

-- Subtracts vector v from this vector
-- Math: (x₁-x₂, y₁-y₂, z₁-z₂)
---@param v Vector
---@return Vector
function Vector:subtraction(v)
    return Vector.new(self.x - v.x, self.y - v.y, self.z - v.z)
end

-- Multiplies this vector by vector v component-wise
-- Math: (x₁x₂, y₁y₂, z₁z₂)
---@param v Vector
---@return Vector
function Vector:multiplication(v)
    return Vector.new(self.x * v.x, self.y * v.y, self.z * v.z)
end

-- Divides this vector by vector v component-wise
-- Math: (x₁/x₂, y₁/y₂, z₁/z₂)
---@param v Vector
---@return Vector
function Vector:division(v)
    return Vector.new(self.x / v.x, self.y / v.y, self.z / v.z)
end

return Vector
