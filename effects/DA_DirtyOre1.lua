--frame time, not compatible with mods that change hz rate unfortunately
LifeSpan = 10e11

Sprites =
{
    {
        Name = "Haze",

        States =
        {
            Normal =
            {
                Frames =
                {
                    { texture = path .. "/effects/media/developerArt/Haze.png" },


                    duration = 0.04,
                    blendColour = false,
                    blendCoordinates = false,
                },
                --RandomPlayLength = 2,
                NextState = "Normal",
            },
        },
    },
}

Effects =
{

    {
        Type = "sprite",
        TimeToTrigger = 0,
        LocalPosition = { x = 0, y = 0, z = -0.1 },
        LocalVelocity = { x = 0, y = 0, z = 0 },
        Acceleration = { x = 0, y = 0, z = 0 },
        Drag = 0.0,
        Sprite = "Haze",
        Additive = false,
        TimeToLive = 10e11,
        Angle = 0,
        InitialSize = 1.9,
        ExpansionRate = 0,
        AngularVelocity = 0,
        RandomAngularVelocityMagnitude = 0,
        Colour1 = { 255, 255, 255, 255 },
        Colour2 = { 255, 255, 255, 255 },
        KillParticleOnEffectCancel = true,
    },

}