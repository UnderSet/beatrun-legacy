local rx, gx, bx, ry, gy, by = 0, 0, 0, 0, 0, 0
local black = Material("vgui/black")
local ca_r = CreateMaterial("ca_r", "UnlitGeneric", {
    ["$basetexture"] = "vgui/black",
    ["$color2"] = "[1 0 0]",
    ["$additive"] = 1,
    ["$ignorez"] = 1
})

local ca_g = CreateMaterial("ca_g", "UnlitGeneric", {
    ["$basetexture"] = "vgui/black",
    ["$color2"] = "[0 1 0]",
    ["$additive"] = 1,
    ["$ignorez"] = 1
})

local ca_b = CreateMaterial("ca_b", "UnlitGeneric", {
    ["$basetexture"] = "vgui/black",
    ["$color2"] = "[0 0 1]",
    ["$additive"] = 1,
    ["$ignorez"] = 1
})

local zoom = Material("vgui/zoom.vtf")
local function CA(rx, gx, bx, ry, gy, by)
    render.UpdateScreenEffectTexture()
    local screentx = render.GetScreenEffectTexture()
    ca_r:SetTexture("$basetexture", screentx)
    ca_g:SetTexture("$basetexture", screentx)
    ca_b:SetTexture("$basetexture", screentx)
    render.SetMaterial(black)
    render.DrawScreenQuad()
    render.SetMaterial(ca_r)
    render.DrawScreenQuadEx(-rx / 2, -ry / 2, ScrW() + rx, ScrH() + ry)
    render.SetMaterial(ca_g)
    render.DrawScreenQuadEx(-gx / 2, -gy / 2, ScrW() + gx, ScrH() + gy)
    render.SetMaterial(ca_b)
    render.DrawScreenQuadEx(-bx / 2, -by / 2, ScrW() + bx, ScrH() + by)
end

function RenderCA()
    rx = 10
    ry = 10
    gx = 10 * (GlitchIntensity * 5 or 1)
    gy = 10 * (GlitchIntensity * 5 or 1)
    bx = 2 * (GlitchIntensity * 5 or 1)
    by = 2 * (GlitchIntensity * 5 or 1)
    CA(rx, gx, bx, ry, gy, by)
    local gi = math.max(1, GlitchIntensity * 4)
    DrawMotionBlur(0.25, 0.75 * GlitchIntensity, 0.005)
    DrawBloom(0, 2, 2 * gi, 2 * gi, 1, 1, 1, 1, 1)
end

surface.CreateFont("DaisyHUDSmall", {
    font = "x14y24pxHeadUpDaisy",
    extended = false,
    size = ScreenScale(6),
    weight = 500,
    blursize = 0,
    scanlines = 2,
    antialias = false,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = true,
    additive = false,
    outline = false,
})

local deletiontable = {}
local deletiontime = 0
local deletiontypetime = 0
local deletiontype = 0
deletionentry = 0
local garble = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"#$%&()*+,-./:;<=>?@[]^_`{|}~'
local garblelen = #garble
local deletionrare = false
local deletionraretbl = {"I've gone too far", "No more than that", "You know my plight"}
local deletioncredits = {"Beatrun", "   ", "   ", "Programming", "| datae", "   ", "   ", "Various assets & concepts", "| Mirror's Edge (EA)", "| Tetris Effect (Resonair)", "| Dying Light (Techland)", "   ", "   ", "Credits music", '| "Sunrise" from OneShot', "   ", "   ", "Special thanks to", "", "   ", "   ", "   ", "   ", "   ",}
incredits = false
local deletionstring = ""
local deletionlen = 0
function DrawDeletionText()
    surface.SetFont("DaisyHUDSmall")
    local oldgi = GlitchIntensity
    if incredits then GlitchIntensity = math.max(0.15, GlitchIntensity) end
    local deletionstringc = deletionstring:Left(deletiontype)
    if CurTime() > deletiontypetime then
        deletiontype = deletiontype + 1
        deletiontypetime = CurTime() + (((deletionrare or incredits) and 0.125) or 0.025)
    end

    if deletiontype > deletionlen then
        deletionrare = math.random() <= 0.01
        if incredits then
            deletioncredits[19] = LocalPlayer():SteamID() or "Someone..?"
            if deletionentry + 1 > #deletioncredits then
                blindpopulatespeed = 150
                blindfakepopulate = true
                vanishlimit = 100
                return
            end

            deletionstring = deletioncredits[deletionentry + 1]
        else
            deletionstring = (not deletionrare and "Deleting /usr/fragments/mem" .. deletionentry .. ".dat") or deletionraretbl[math.random(#deletionraretbl)]
        end

        deletionlen = #deletionstring
        deletionrare = deletionrare
        deletiontype = 0
        deletionentry = deletionentry + 1
        table.insert(deletiontable, deletionstringc)
        if #deletiontable >= 6 then table.remove(deletiontable, 1) end
    end

    local tw, th = surface.GetTextSize(deletionstringc)
    cam.Start2D()
    local num = 0
    local ply = LocalPlayer()
    local vp = ply:GetViewPunchAngles()
    local vpcl = ply.ViewPunchAngle or angle_zero
    vp:Add(vpcl)
    local GlitchIntensity = (incredits and 2) or GlitchIntensity
    surface.SetTextColor(255, 255, 255, 2.5 * (num + 1) * GlitchIntensity)
    for k, v in ipairs(deletiontable) do
        surface.SetTextColor(255, 255, 255, 2.5 * k * GlitchIntensity)
        local text = v
        for i = 1, 4 do
            local index = math.random(1, #text)
            if text[index] ~= " " then text = text:SetChar(index, garble[math.random(1, garblelen)]) end
        end

        surface.SetTextPos(ScrW() * 0.01 + vp.x, ScrH() * 0.05 + ((k - 1) * th) + vp.y)
        surface.DrawText(text)
        num = k
    end

    if deletiontype > 0 then
        surface.SetTextPos(ScrW() * 0.01 + vp.x, ScrH() * 0.05 + (num * th) + vp.y)
        surface.DrawText(deletionstringc)
    end

    cam.End2D()
    GlitchIntensity = oldgi
end