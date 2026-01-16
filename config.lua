Config = {}
Config.UseTarget = GetConvar('UseTarget', 'false') == 'true' -- Use qb-target interactions (don't change this, go to your server.cfg and add `setr UseTarget true` to use this and just that from true to false or the other way around)

Config.Jobs = {
    ['electrician'] = 'Electrician'
}

Config.Uniforms = {
    ['male'] = {
        outfitData = {
            ['t-shirt'] = { item = 15, texture = 0 },
            ['torso2'] = { item = 345, texture = 0 },
            ['arms'] = { item = 19, texture = 0 },
            ['pants'] = { item = 3, texture = 7 },
            ['shoes'] = { item = 1, texture = 0 },
        }
    },
    ['female'] = {
        outfitData = {
            ['t-shirt'] = { item = 14, texture = 0 },
            ['torso2'] = { item = 370, texture = 0 },
            ['arms'] = { item = 0, texture = 0 },
            ['pants'] = { item = 0, texture = 12 },
            ['shoes'] = { item = 1, texture = 0 },
        }
    },
}

Config.Locations = {
    freedom = vector4(1740.88, 2476.57, 44.85, 299.49),
    outside = vector4(1848.13, 2586.05, 44.67, 269.5),
    yard = vector4(1765.67, 2565.91, 44.56, 1.5),
    middle = vector4(1693.33, 2569.51, 44.55, 123.5),
    spawns = {
        { coords = vector4(1749.83, 2483.76, 45.85, 125.2) }
    },
    jobs = {
        electrician = {
            { coords = vector4(1749.9, 2470.46, 45.85, 301.2) },
            { coords = vector4(1738.95, 2488.33, 45.84, 313.17) },
            { coords = vector4(1730.59, 2502.72, 45.85, 4.17) },
            { coords = vector4(1730.11, 2501.1, 49.23, 346.91) },
            { coords = vector4(1739.11, 2488.08, 49.24, 311.64) },
            { coords = vector4(1762.91, 2509.84, 49.21, 118.65) },
            { coords = vector4(1769.98, 2479.77, 45.85, 32.48) }
        }
    }
}
--object prop_elecbox_18
