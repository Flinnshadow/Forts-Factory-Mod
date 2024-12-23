--scripts/math/vector.lua

function SpringDampenedForce(springConst, displacement, dampening, velocity)
   local force = springConst * displacement - dampening * velocity
   return force
end

function IsWithinDistance(vector1, vector2, distance)
    local dx = vector1.x - vector2.x
    local dy = vector1.y - vector2.y
    local distanceSquared = dx * dx + dy * dy
    local givenDistanceSquared = distance * distance

    return distanceSquared <= givenDistanceSquared
end

function Vec2Perp(v)
    return Vec3(-v.y, v.x)
end

function Vec2Normalize(v)
    local mag = Vec2Mag(v)
    if mag > 0 then
        v.x = v.x / mag
        v.y = v.y / mag
    end
    return v
end

function Vec2Dist(v1, v2)
    return math.sqrt((v1.x - v2.x)^2 + (v1.y - v2.y)^2)
end


function Vec2Average(vectors)
    local averageX, averageY = 0, 0
    for _, vector in pairs(vectors) do

        averageX = averageX + vector.x
        averageY = averageY + vector.y
    end
    return Vec3(averageX / #vectors, averageY / #vectors)
end

function Vec2Mag(v)
    return math.sqrt(v.x * v.x + v.y * v.y)

end

function Vec2Dot(v1, v2)
    return v1.x * v2.x + v1.y * v2.y
end
function Vec2Invert(v)
    return Vec3(-v.x, -v.y)
end
function Vec2Cross(v1, v2)
    return v1.x * v2.y - v1.y * v2.x
end
--create a minimum sized rectangle around a polygon
function CalculateSquare(points)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge

    for _, point in pairs(points) do
        if point.x < minX then minX = point.x end
        if point.x > maxX then maxX = point.x end
        if point.y < minY then minY = point.y end
        if point.y > maxY then maxY = point.y end
    end
    
    local pointA = Vec3(minX, minY)
    local pointB = Vec3(minX, maxY)
    local pointC = Vec3(maxX, maxY)
    local pointD = Vec3(maxX, minY)
    
    
    return {pointA, pointB, pointC, pointD}
end

  
function MinimumCircularBoundary(points)
    local square = CalculateSquare(points)
    local radius = Vec2Mag(square[3] - square[1]) / 2
    local pos = Vec2Average(square)
    return {
        x = pos.x, y = pos.y, r = radius, square = square
    }
end

function MinimumWheelCircularBoundary(wheels)
    local points = {}
    for _, wheel in pairs(wheels) do
        table.insert(points, wheel:GetPos())
    end
    return MinimumCircularBoundary(points)
end

function TableToVector3(table)
    local newTable = {}
    for _, value in pairs(table) do
        table.insert(newTable, Vec3(value.x, value.y))
    end
    return newTable
end




--[[ vector.lua
Modifies Vec3 to have expanded functionality
Expects forts.lua or core.lua to be imported beforehand
]]

-- Vector member functions
local VectorMembers = {
    length = function (vec)
        return Vec3Length(vec)
    end,
    lengthSquared = function (vec)
        return (vec.x or 0) * (vec.x or 0) + (vec.y or 0) * (vec.y or 0) + (vec.z or 0) * (vec.z or 0)
    end,
    radians = function(vec)
        return math.atan2(vec.y,vec.x)
    end,
    degrees = function(vec)
        return math.deg(math.atan2(vec.y,vec.x))
    end,
    distance = function(vec1, vec2)
        return (vec1 - vec2).length()
    end,
    distanceSquared = function(vec1, vec2)
        return (vec1 - vec2).lengthSquared()
    end,
    isWithinDistance = function(vec1, vec2, distance)
        return vec1.distanceSquared(vec2) <= distance * distance
    end,

    -- Modifies the existing vector
    normalize = function(vec)
        local vecLength = vec.length()
        if (vecLength == 0) then return end 

        vec.x = vec.x / vecLength
        vec.y = vec.y / vecLength
        vec.z = vec.z / vecLength
    end,
}



--Vanilla Vec3 expansion, made by AlexD

---@class Vector3D
---@field x number
---@field y number
---@field z number
---@field [any] any

-- Metatable implementing operators using metafunctions
-- All member functions are implemented via the __index metafunction
---@class Vec3
---@field [any] any
VectorMetatable = {
        -- Implements member functions, called when a nil item *would*
    -- be accessed in the tables dictionary, instead gives return value. 
    __index = function(table, key)
        local member = VectorMembers[key]
        if (member ~= nil) then
            -- Wraps the member function to avoid the need to explicitly pass in the vector.
            local memberWrapper = function(...)
                return member(table, ...)
            end
            return memberWrapper
        end
        return nil
    end,

    __add = function(value1, value2)
        if type(value1) == "table" and type(value2) == "table" then
            return Vec3(value1.x+value2.x, value1.y+value2.y, value1.z+value2.z)
        end
        error("Error: Addition cannot be calculated on type " .. type(value1) .. " and type " .. type(value2) .. "",2)
    end,
    __sub = function(value1, value2)
        if type(value1) == "table" and type(value2) == "table" then
            return Vec3(value1.x-value2.x, value1.y-value2.y, value1.z-value2.z)
        end
        error("Error: Subtraction cannot be calculated on type " .. type(value1) .. " and type " .. type(value2) .. "",2)
    end,
    __mul = function(value1, value2)
        local type1 = type(value1)
        local type2 = type(value2)
        if type1 == "number" then 
            return Vec3(value2.x*value1, value2.y*value1, value2.z*value1)
        elseif type2 == "number" then 
            return Vec3(value1.x*value2, value1.y*value2, value1.z*value2)
        elseif type1 ~= "table" or type2 ~= "table" then
            error("Error: Multiplication cannot be calculated on type " .. type1 .. " and type " .. type2 .. "", 2)
        end
        
        return Vec3(value1.x*value2.x, value1.y*value2.y, value1.z*value2.z)
    end,
    __div = function(value1, value2)
        local type1 = type(value1)
        local type2 = type(value2)
        if type1 == "number" then 
            return Vec3(value1/value2.x, value1/value2.y, value1/value2.z)
        elseif type2 == "number" then 
            return Vec3(value1.x/value2, value1.y/value2, value1.z/value2)
        elseif type1 ~= "table" or type2 ~= "table" then
            error("Error: Division cannot be calculated on type " .. type1 .. " and type " .. type2 .. "", 2)
        end
        
        return Vec3(value1.x/value2.x, value1.y/value2.y, value1.z/value2.z)
    end,
    __unm = function(vector3)
        return Vec3(-vector3.x, -vector3.y, -vector3.z)
    end,
    __tostring = function(vector3)
        return string.format("(%.2f, %.2f, %.2f)", vector3.x, vector3.y, vector3.z)
    end,
    __concat = function(value1, value2)
        return tostring(value1) .. tostring(value2)
    end,
    __eq = function(vec1, vec2)
        return vec1.x == vec2.x and vec1.y == vec2.y and vec1.z == vec2.z
    end,


    
    x = 0,
    y = 0,
    z = 0
}


---Vector3 class (z is usually unused)
---@param x number?
---@param y number?
---@param z number?
---@return Vec3
function Vec3(x, y, z)
    local vec = {}
    vec.x = x or 0
    vec.y = y or 0
    vec.z = z or 0
    setmetatable(vec, VectorMetatable)
    return vec
end

function Vec3Normalize(v)
    local mag = Vec3Mag(v)
    if mag > 0 then
        v.x = v.x / mag
        v.y = v.y / mag
        v.z = v.z / mag
    end
    setmetatable(v, VectorMetatable)
    return v
end

function Vec3Mag(v)
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

-- Sets properties to be that of a Vector.
function Vec3Restore(vec)
    if (vec) then
        setmetatable(vec, VectorMetatable)
    end
end

function Vec3Lerp(vec1, vec2, t)
    return Vec3(
        vec1.x + (vec2.x - vec1.x) * t,
        vec1.y + (vec2.y - vec1.y) * t,
        vec1.z + (vec2.z - vec1.z) * t
    )
end

function Vec2Lerp(vec1, vec2, t)
    return Vec3(
        vec1.x + (vec2.x - vec1.x) * t,
        vec1.y + (vec2.y - vec1.y) * t
    )
end

function Vec3FromDegrees(degrees)
    local radians = math.rad(degrees)
    return Vec3(math.cos(radians), math.sin(radians))
end

function Vec3AverageTable(vectors)
    local average = Vec3(0,0,0)
    for _, vector in pairs(vectors) do
        average = average + vector
    end
    return Vec3(average.x / #vectors, average.y / #vectors, average.z / #vectors)
end




function IsConcave(a, b, c)
    local ab = b - a
    local bc = c - b
    local cross = Vec2Cross(ab, bc)
    return cross < 0
end

function IsConvex(a, b, c)
    local ab = b - a
    local bc = c - b
    local cross = Vec2Cross(ab, bc)
    return cross > 0
end

function IsObtuse(a, b, c)
    local ab = b - a
    local bc = c - b
    local dot = Vec2Dot(ab, bc)
    return dot > 0
end
function IsAcute(a, b, c)
    local ab = b - a
    local bc = c - b
    local dot = Vec2Dot(ab, bc)
    return dot < 0
end