local rtcache = {}
local rtmatcache = {}
local propspanel = {}
propspanel.w = 64 * 6
propspanel.h = 400
propspanel.x = 1920 * 0.85 - propspanel.w * 0.5
propspanel.y = 1080 * 0.65 - propspanel.h * 0.5
propspanel.bgcolor = Color(32, 32, 32)
propspanel.outlinecolor = Color(55, 55, 55)
propspanel.alpha = 0.9
propspanel.elements = {}
local bmbuttons = {}
bmbuttons.w = 190
bmbuttons.h = 25 * 4
bmbuttons.x = 1920 * 0.85 - propspanel.w * 0.5
bmbuttons.y = 1080 * 0.9 - bmbuttons.h * 0.5
bmbuttons.bgcolor = Color(32, 32, 32)
bmbuttons.outlinecolor = Color(55, 55, 55)
bmbuttons.alpha = 0.45
bmbuttons.elements = {}
local bminfo = {}
bminfo.w = 190
bminfo.h = 25 * 4
bminfo.x = 1920 * 0.85 + 2
bminfo.y = 1080 * 0.9 - bminfo.h * 0.5
bminfo.bgcolor = Color(32, 32, 32)
bminfo.outlinecolor = Color(55, 55, 55)
bminfo.alpha = 0.45
bminfo.elements = {}
local function infostring()
    local p, y, r = BuildModeAngle:Unpack()
    p, y, r = math.Round(p), math.Round(y), math.Round(r)
    local a = "Index: " .. BuildModeIndex .. "\nSelected: " .. table.Count(buildmode_selected) .. "\nAngle: " .. p .. ", " .. y .. ", " .. r
    return a
end

AEUI:AddText(bminfo, infostring, "AEUIDefault", bminfo.w / 2, bminfo.h / 2 - 20, true)
local function BuildModeHUDButton(e)
    buildmodeinputs[e.key](true)
end

local function GreyButtons()
    return table.Count(buildmode_selected) == 0
end

local b = AEUI:AddButton(bmbuttons, "Drag (G)", BuildModeHUDButton, "AEUIDefault", 2, 25 * 0, false)
b.key = KEY_G
b.greyed = GreyButtons
local b = AEUI:AddButton(bmbuttons, "Dupe (SHIFT+D)", BuildModeHUDButton, "AEUIDefault", 2, 25 * 1, false)
b.key = KEY_D
b.greyed = GreyButtons
local b = AEUI:AddButton(bmbuttons, "Delete (DEL/BCKSPC)", BuildModeHUDButton, "AEUIDefault", 2, 25 * 2, false)
b.key = KEY_DELETE
b.greyed = GreyButtons
local b = AEUI:AddButton(bmbuttons, "Highlight (T)", BuildModeHUDButton, "AEUIDefault", 2, 25 * 3, false)
b.key = KEY_T
b.greyed = GreyButtons
blur = Material("pp/blurscreen")
function draw_blur(a, d)
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)
    for i = 1, d do
        blur:SetFloat("$blur", (i / d) * a)
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
    end
end

local dummy = ClientsideModel("models/hunter/blocks/cube025x025x025.mdl")
dummy:SetNoDraw(true)
function GenerateBuildModeRT(model)
    if not rtcache[model] then
        local texw = 64
        local texh = 64
        local tex = GetRenderTarget("BMRT-" .. model, texw, texh)
        render.PushFilterMag(TEXFILTER.ANISOTROPIC)
        render.PushFilterMin(TEXFILTER.ANISOTROPIC)
        render.PushRenderTarget(tex, 0, 0, texw, texh)
        render.SuppressEngineLighting(true)
        dummy:SetModel(model)
        local sicon = PositionSpawnIcon(dummy, vector_origin)
        print(sicon.origin)
        cam.Start3D(sicon.origin, sicon.angles, sicon.fov)
        render.Clear(0, 0, 0, 0)
        render.ClearDepth()
        render.SetWriteDepthToDestAlpha(false)
        render.SetModelLighting(0, 4, 4, 4)
        render.SetModelLighting(1, 2, 2, 2)
        render.SetModelLighting(2, 2, 2, 2)
        render.SetModelLighting(3, 4, 4, 4)
        render.SetModelLighting(4, 3, 3, 3)
        render.SetModelLighting(5, 4, 4, 4)
        dummy:DrawModel()
        cam.End3D()
        render.PopRenderTarget()
        render.PopFilterMag()
        render.PopFilterMin()
        render.SuppressEngineLighting(false)
        rtcache[model] = tex
        local mat = CreateMaterial("BM-" .. model, "UnlitGeneric", {
            ['$basetexture'] = tex:GetName(),
            ["$translucent"] = 1,
            ["$vertexcolor"] = 1,
            ["$vertexalpha"] = 1,
        })

        rtmatcache[model] = mat
    end
    return rtmatcache[model]
end

local function BMPropClick(e)
    BuildModeIndex = e.prop or 0
    print(e.prop)
    LocalPlayer():EmitSound("buttonclick.wav")
    if BuildModeIndex == 0 then
        SafeRemoveEntity(GhostModel)
        return
    end

    BuildModeCreateGhost()
    GhostModel:SetModel(buildmode_props[BuildModeIndex])
end

local img = AEUI:AddImage(propspanel, Material("vgui/empty.png"), BMPropClick, 0, 0, 64, 64)
img.prop = 0
img.hover = "Select"
local row = 1
local col = 0
for k, v in pairs(buildmode_props) do
    local spawnicon = "spawnicons/" .. v:Left(-5) .. ".png"
    if file.Exists("materials/" .. spawnicon, "GAME") then
        rtmatcache[v] = Material(spawnicon)
    else
        GenerateBuildModeRT(v)
    end

    local img = AEUI:AddImage(propspanel, rtmatcache[v], BMPropClick, 64 * row, 64 * col, 64, 64)
    img.prop = k
    img.hover = v
    row = row + 1
    if row > 5 then
        col = col + 1
        row = 0
    end
end

local img = AEUI:AddImage(propspanel, Material("vgui/empty.png"), BMPropClick, 64 * row, 64 * col, 64, 64)
img.prop = 0
img.hover = "Select"
local function BMPanel(state)
    if state then
        AEUI:AddPanel(propspanel)
        AEUI:AddPanel(bmbuttons)
        AEUI:AddPanel(bminfo)
    else
        AEUI:RemovePanel(propspanel)
        AEUI:RemovePanel(bmbuttons)
        AEUI:RemovePanel(bminfo)
    end
end

hook.Add("BuildModeState", "BMPanel", BMPanel)