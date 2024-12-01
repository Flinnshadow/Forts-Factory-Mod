--scripts/utility/physLib/render.lua


local Render = PhysLib.Render
Render.LastFrameTime = 0
Render.TotalFrameTime = data.updateDelta
Render.Objects = PhysLib.PhysicsObjects.Objects
function PhysLib.Render:OnUpdate()
    local objects = self.Objects
    local currentDrawFrameTime = GetRealTime()
    local deltaTime = currentDrawFrameTime - self.LastFrameTime
    local t = deltaTime / self.TotalFrameTime

    for i = 1, #objects do
        local object = objects[i]
        local pos = object.pos
        local lastPos = object.lastFramePos
        local effectId = object.effectId

        local drawPos = Vec2Lerp(lastPos, pos, t)
        if not object.InterpolateThisFrame then drawPos = pos end
        SetEffectPosition(effectId, drawPos)
    end
end

function PhysLib.Render:BeforePhysicsUpdate()
    local objects = self.Objects
    for i = 1, #objects do
        local object = objects[i]
        if not object.InterpolateThisFrame then object.InterpolateThisFrame = true end
    end
end

function PhysLib.Render:PhysicsUpdate()
    local currentTime = GetRealTime()
    self.TotalFrameTime = currentTime - self.LastFrameTime
    self.LastFrameTime = currentTime

end

