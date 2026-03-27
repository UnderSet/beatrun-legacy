local bigboy = false
local welcome = {}
welcome.w = 700
welcome.h = 400
welcome.x = 1920 * 0.5 - welcome.w * 0.5
welcome.y = 1080 * 0.5 - welcome.h * 0.5
welcome.bgcolor = Color(32, 32, 32)
welcome.outlinecolor = Color(54, 55, 56)
welcome.alpha = 0.9
welcome.elements = {}
local function closebutton(self)
    LocalPlayer():EmitSound("holygrenade.mp3")
    AEUI:Clear()
end

local function warnclosebutton(self)
    LocalPlayer():EmitSound("holygrenade.mp3")
    AEUI:Clear()
    bigboy = true
end

AEUI:Text(welcome, "Welcome to the public test server\nScroll down for commands\n\nIf you don't know how to do something, ask\n\nPress R to respawn", "AEUILarge", welcome.w / 2, 100, true)
AEUI:Text(welcome, "If you see this again someone refreshed the fucking lua", "AEUIDefault", welcome.w / 2, 375, true)
AEUI:Text(welcome, "Beatrun_FOV - Changes your FOV (70-140)\nToggleWhitescale - Mirror's Edge-ify the map", "AEUILarge", welcome.w / 2, 475, true)
AEUI:AddButton(welcome, "  X  ", closebutton, "AEUILarge", welcome.w - 47, 0)
if not game.SinglePlayer() then return end
local addons = 0
local warning = Material("vgui/warning.png")
local shit = {
    ["2027577882"] = true,
    ["1632091428"] = true,
    ["2316713217"] = true,
    ["142911907"] = true,
    ["240159269"] = true,
    ["1440226338"] = true,
    ["123514260"] = true,
    ["1622199072"] = true,
    ["2416989205"] = true,
    ["1418478031"] = true,
    ["104548572"] = true,
    ["2564569716"] = true
}

local warnpanel = {}
warnpanel.w = 500
warnpanel.h = 350
warnpanel.x = 1920 * 0.5 - warnpanel.w * 0.5
warnpanel.y = 1080 * 0.5 - warnpanel.h * 0.5
warnpanel.bgcolor = Color(32, 32, 32)
warnpanel.outlinecolor = Color(54, 55, 56)
warnpanel.alpha = 0.9
warnpanel.elements = {}
local conflictpanel = {}
conflictpanel.w = 400
conflictpanel.h = 150
conflictpanel.x = 1920 * 0.525 - warnpanel.w * 0.5
conflictpanel.y = 1080 * 0.6 - warnpanel.h * 0.5
conflictpanel.bgcolor = Color(32, 32, 32)
conflictpanel.outlinecolor = Color(54, 55, 56)
conflictpanel.alpha = 1
conflictpanel.elements = {}
local warntext = {}
warntext.type = "Text"
warntext.font = "AEUIDefault"
warntext.x = warnpanel.w * 0.5
warntext.y = warnpanel.h * 0.125
warntext.centered = true
warntext.color = color_white
warntext.string = "NOTICE\nPlease disable the following addons before playing:"
table.insert(warnpanel.elements, warntext)
local quitbutton = {}
quitbutton.type = "Button"
quitbutton.font = "AEUIDefault"
quitbutton.x = warnpanel.w * 0.5
quitbutton.y = warnpanel.h * 0.85
quitbutton.centered = true
quitbutton.color = color_white
quitbutton.string = "Return to Main Menu"
quitbutton.onclick = function(self)
    surface.PlaySound("garrysmod/ui_click.wav")
    MsgC(Color(255, 100, 100), "Quitting Beatrun due to conflicting addons!")
    timer.Simple(0.5, function() RunConsoleCommand("killserver") end)
    self.onclick = nil
end

table.insert(warnpanel.elements, quitbutton)
AEUI:AddButton(warnpanel, "Play, but at my own peril", warnclosebutton, "AEUIDefault", warnpanel.w * 0.5, warnpanel.h * 0.93, true)
local conflictlist = {}
conflictlist.type = "Text"
conflictlist.font = "AEUIDefault"
conflictlist.x = 0
conflictlist.y = 0
conflictlist.centered = false
conflictlist.color = color_white
conflictlist.string = ""
table.insert(conflictpanel.elements, conflictlist)
local function CheckAddons()
    addons = 0
    for k, v in pairs(engine.GetAddons()) do
        if v.mounted and (v.tags:find("tool") or v.tags:find("Fun") or v.tags:find("Realism")) and not v.tags:find("map") and not v.tags:find("Weapon") then addons = addons + 1 end
        if v.mounted and shit[v.wsid] then conflictlist.string = conflictlist.string .. v.title .. "\n" end
    end

    print(conflictlist.string)
    return addons
end

local sealplead = Material("vgui/sealplead.png")
local lightlerp = Vector()
local function Seal()
    local ply = LocalPlayer()
    local vpang = ply:GetViewPunchAngles()
    local x, y = vpang.z + ply.ViewPunchAngle.z * 500, vpang.x + ply.ViewPunchAngle.x * 500 - 10
    local w, h = sealplead:Width(), sealplead:Height()
    local eyepos = EyePos()
    local eyeang = EyeAngles()
    LocalPlayer():DrawViewModel(false)
    render.RenderView({
        origin = eyepos,
        angles = (-eyeang:Forward()):Angle(),
        x = 0,
        y = 0,
        w = w,
        h = h
    })

    render.SetScissorRect(0, 0, w, h, true)
    local light = render.GetLightColor(eyepos)
    col = lightlerp
    local colx, coly, colz = col[1], col[2], col[3]
    col[1] = Lerp(25 * FrameTime(), colx, light[1] * 500)
    col[2] = Lerp(25 * FrameTime(), coly, light[2] * 500)
    col[3] = Lerp(25 * FrameTime(), colz, light[3] * 500)
    colx, coly, colz = col[1], col[2], col[3]
    surface.SetDrawColor(math.min(colx, 255), math.min(coly, 255), math.min(colz, 255), 255)
    surface.SetMaterial(sealplead)
    surface.DrawTexturedRectRotated(x + (w * 0.5), y + (h * 0.5), w + x, h + y + math.abs(math.sin(CurTime()) * 10), -MMRot + eyeang.z)
    render.SetScissorRect(0, 0, 0, 0, false)
    surface.SetFont("BeatrunHUD")
    surface.SetTextPos(2, 0)
    surface.SetTextColor(220, 20, 20, math.abs(math.sin(CurTime() * 2) * 255))
    surface.DrawText("�� LIVE PLAYER CAM")
    LocalPlayer():DrawViewModel(true)
end

local function WarningIcon()
    surface.SetMaterial(warning)
    if bigboy then
        Seal()
        return
    else
        surface.SetDrawColor(15, 15, 15, 125)
    end

    surface.DrawRect(0, 0, 33, 29)
    surface.SetDrawColor(255, 255, 255, 125)
    surface.DrawTexturedRect(0, 1, 32, 26)
end

if CheckAddons() > 80 then
    hook.Add("HUDPaint", "AddonWarning", WarningIcon)
else
    hook.Remove("HUDPaint", "AddonWarning")
end

if conflictlist.string ~= "" then
    timer.Simple(0, function()
        AEUI:AddPanel(warnpanel)
        AEUI:AddPanel(conflictpanel)
    end)
end