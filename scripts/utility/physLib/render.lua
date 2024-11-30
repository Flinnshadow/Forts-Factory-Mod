PhysLibRender = {
    LastFrameTime = 0,
    TotalFrameTime = data.updateDelta
}

function PhysLibRender.OnDraw()
    local currentDrawFrameTime = GetRealTime()
    local deltaTime = currentDrawFrameTime - PhysLibRender.LastFrameTime
    local t = deltaTime / PhysLibRender.TotalFrameTime

    for i = 1, #PhysicsObjects do
        local Object = PhysicsObjects[i]
        local pos = Object.pos
        local lastPos = Object.lastFramePos
        local effectId = Object.effectId

        local drawPos = Vec3Lerp(lastPos, pos, t)
        if not Object.InterpolateThisFrame then drawPos = pos end
        SetEffectPosition(effectId, drawPos)
    end
end

function PhysLibRender.BeforePhysicsUpdate()
    for i = 1, #PhysicsObjects do
        local Object = PhysicsObjects[i]
        if not Object.InterpolateThisFrame then Object.InterpolateThisFrame = true end
    end
end

function PhysLibRender.PhysicsUpdate()
    PhysLibRender.LastFrameTime = GetRealTime()

end

