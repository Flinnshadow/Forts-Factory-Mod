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
        local lastPos = Object.lastPos
        local effectId = Object.effectId

        local drawPos = Vec3Lerp(lastPos, pos, t)
        SetEffectPosition(effectId, drawPos)
    end
end

function PhysLibRender.PhysicsUpdate()
    PhysLibRender.LastFrameTime = GetRealTime()
end