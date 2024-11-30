




TestObject = {
    x = 0,
    y = 0,
    nextX = 0,
    nextY = 0,
    nextPos = Vec3(0, 0, 0),
    radius = 50 / 2,
    velocity = Vec3(0, 0, 0),
    effectId = 0,
    extents = {minX = -1000, minY = -1000, maxX = 1000, maxY = 1000}


}

function CalculateObjectsExtents(Objects)
    for i = 1, #Objects do
        CalculateObjectExtents(Objects[i])
    end
end

function CalculateObjectExtents(object)
    local radius = object.radius
    
    local posX = object.x
    local posY = object.y
    local nextPosX = object.nextX
    local nextPosY = object.nextY

    local minX = (posX < nextPosX and posX or nextPosX) - radius
    local minY = (posY < nextPosY and posY or nextPosY) - radius
    local maxX = (posX > nextPosX and posX or nextPosX) + radius
    local maxY = (posY > nextPosY and posY or nextPosY) + radius

    object.extents = {minX = minX, minY = minY, maxX = maxX, maxY = maxY, center = {x = (minX + maxX) / 2, y = (minY + maxY) / 2}}

end

ObjectCasts = {}
ObjectCastTree = {}

function StoreObjectsInTree()

    -- TODO: move SubdivideGroup to it's own file
    ObjectCastTree = SubdivideGroup(ObjectCasts, 0)
end
