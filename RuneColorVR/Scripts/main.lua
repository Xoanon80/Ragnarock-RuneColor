-- Rune Color Override for Ragnarock (UE4SS)
-- Overrides the body/glow color of runes based on active_color.cfg.
-- Presets (with optional emissive boost) are defined in rune_palette.cfg.

local function scriptDir()
    local source = debug.getinfo(1, "S").source
    local path = source:match("@(.*)")
    return path and path:match("(.*[/\\])") or ""
end

local BASE_DIR = scriptDir()

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function srgbToLinear(c)
    if c <= 0.04045 then return c / 12.92 end
    return ((c + 0.055) / 1.055) ^ 2.4
end

local function hexToLinear(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not (r and g and b) then return nil end
    return srgbToLinear(r / 255), srgbToLinear(g / 255), srgbToLinear(b / 255)
end

local function hsvToLinear(h, s, v)
    h = h % 360
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    local r, g, b
    if h < 60 then r, g, b = c, x, 0
    elseif h < 120 then r, g, b = x, c, 0
    elseif h < 180 then r, g, b = 0, c, x
    elseif h < 240 then r, g, b = 0, x, c
    elseif h < 300 then r, g, b = x, 0, c
    else r, g, b = c, 0, x end
    r, g, b = r + m, g + m, b + m
    return srgbToLinear(r), srgbToLinear(g), srgbToLinear(b)
end

local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

local palette = {}

local function loadPalette()
    local content = readFile(BASE_DIR .. "rune_palette.cfg")
    if not content then return end
    palette = {}
    for line in content:gmatch("[^\r\n]+") do
        line = trim(line)
        if line ~= "" and not line:match("^#") then
            local name, bodyHex, glowHex, boostStr = line:match("^(%S-)=(#%x+),(#%x+),([%d%.]+)")
            if name then
                local br, bg, bb = hexToLinear(bodyHex)
                local gr, gg, gb = hexToLinear(glowHex)
                if br then
                    palette[name] = {
                        body = { br, bg, bb },
                        glow = { gr, gg, gb },
                        boost = tonumber(boostStr) or 1.0,
                    }
                end
            end
        end
    end
end

-- state.mode: "off" | "color" | "rainbow"
-- state.body / state.glow: {r,g,b} in linear space
-- state.boost: multiplier applied to body for the emissive fill
local state = { mode = "off", boost = 1.0 }

local lastActiveContent = nil

local function loadActiveConfig()
    local content = readFile(BASE_DIR .. "active_color.cfg")
    if not content or content == lastActiveContent then return end
    lastActiveContent = content

    local values = {}
    for line in content:gmatch("[^\r\n]+") do
        line = trim(line)
        if line ~= "" and not line:match("^#") then
            local key, val = line:match("^(%S-)=(.+)$")
            if key then values[trim(key)] = trim(val) end
        end
    end

    local active = values.active
    if not active or active == "off" then
        state.mode = "off"
    elseif active == "rainbow" then
        state.mode = "rainbow"
        state.boost = tonumber(values.rainbow_boost) or 1.3
    elseif active == "custom" then
        local br, bg, bb = hexToLinear(values.custom_body or "#12356B")
        local gr, gg, gb = hexToLinear(values.custom_glow or "#FFFFFF")
        state.mode = "color"
        state.body = { br, bg, bb }
        state.glow = { gr, gg, gb }
        state.boost = tonumber(values.custom_boost) or 1.0
    elseif palette[active] then
        state.mode = "color"
        state.body = palette[active].body
        state.glow = palette[active].glow
        state.boost = palette[active].boost
    else
        state.mode = "off"
    end
end

loadPalette()
loadActiveConfig()

LoopAsync(2000, function()
    loadActiveConfig()
    return false
end)

-- Rainbow mode: continuously rotates the hue, independent of the file poll above.
local rainbowHue = 0
LoopAsync(150, function()
    if state.mode == "rainbow" then
        rainbowHue = (rainbowHue + 12) % 360
        local br, bg, bb = hsvToLinear(rainbowHue, 0.85, 0.45)
        local gr, gg, gb = hsvToLinear(rainbowHue, 0.2, 0.95)
        state.body = { br, bg, bb }
        state.glow = { gr, gg, gb }
    end
    return false
end)

local function applyOverride(structVal, colorTable, boost)
    boost = boost or 1.0
    structVal.R = colorTable[1] * boost
    structVal.G = colorTable[2] * boost
    structVal.B = colorTable[3] * boost
end

local NATIVE_COLOR_HOOKS = {
    "/Script/Engine.MaterialInstanceDynamic:SetVectorParameterValue",
    "/Script/Engine.MeshComponent:SetVectorParameterValueOnMaterials",
}

for _, hookPath in ipairs(NATIVE_COLOR_HOOKS) do
    pcall(function()
        RegisterHook(hookPath, function(context, paramName, colorValue)
            if state.mode == "off" or not state.body or not state.glow then return end

            local okSelf, selfObj = pcall(function() return context:get() end)
            if not okSelf or not selfObj then return end

            local okFull, fullName = pcall(function() return selfObj:GetFullName() end)
            if not okFull or not fullName or not fullName:find("Rune") then return end

            local okName, nameVal = pcall(function() return paramName:get() end)
            if not okName then return end
            local okStr, nameStr = pcall(function() return nameVal:ToString() end)
            if not okStr then return end

            local componentType = fullName:match("%.(%a+)%.MaterialInstanceDynamic")

            local target, boost = nil, 1.0
            if nameStr == "ColorEmissive" then
                target, boost = state.body, state.boost
            elseif nameStr == "Color" and (componentType == "Plane" or componentType == "StaticMesh") then
                target = state.glow
            end
            if not target then return end

            local okVal, structVal = pcall(function() return colorValue:get() end)
            if okVal and structVal then
                pcall(applyOverride, structVal, target, boost)
            end
        end)
    end)
end