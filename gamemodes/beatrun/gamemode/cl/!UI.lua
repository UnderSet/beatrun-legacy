AEUI = {}
local AEUI = AEUI
local SScaleX_cached = {}
local SScaleY_cached = {}
function SScaleX(sizex)
    local iswide = AEUI.ScrW / AEUI.ScrH > 1.6
    if SScaleX_cached[sizex] then return SScaleX_cached[sizex] end
    SScaleX_cached[sizex] = math.ceil(sizex / (1920 / AEUI.ScrW))
    return SScaleX_cached[sizex]
end

function SScaleY(sizey)
    local iswide = AEUI.ScrW / AEUI.ScrH > 1.6
    if SScaleY_cached[sizey] then return SScaleY_cached[sizey] end
    SScaleY_cached[sizey] = math.ceil(sizey / (1080 / AEUI.ScrH))
    return SScaleY_cached[sizey]
end

local SScaleX, SScaleY = SScaleX, SScaleY
AEUI.Panels = {}
AEUI.Elements = {}
AEUI.MX, AEUI.MY = 0, 0
AEUI.LastClick = 0
AEUI.ScrW, AEUI.ScrH = ScrW(), ScrH()
AEUI.HoveredPanel = nil
function AEUI:DrawPanel(panel)
    local x, y, w, h = SScaleX(panel.x), SScaleY(panel.y), SScaleX(panel.w), SScaleY(panel.h)
    surface.SetDrawColor(panel.bgcolor)
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(panel.outlinecolor)
    surface.DrawOutlinedRect(x, y, w, h)
    render.SetScissorRect(x, y, x + w, y + h, true)
end

function AEUIFonts()
    surface.CreateFont("AEUIDefault", {
        font = "D-DIN",
        extended = false,
        size = ScreenScale(7),
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    })

    surface.CreateFont("AEUILarge", {
        font = "D-DIN",
        extended = false,
        size = ScreenScale(12),
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    })

    surface.CreateFont("AEUIVeryLarge", {
        font = "D-DIN",
        extended = false,
        size = ScreenScale(18),
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    })
end

AEUIFonts()
function AEUI:AddPanel(panel)
    if table.HasValue(AEUI.Panels, panel) then return end
    table.insert(AEUI.Panels, panel)
    gui.EnableScreenClicker(true)
end

function AEUI:RemovePanel(panel)
    table.RemoveByValue(AEUI.Panels, panel)
    if #AEUI.Panels <= 0 then gui.EnableScreenClicker(false) end
end

function AEUI:AddText(panel, str, font, x, y, centered, color)
    font = font or "AEUIDefault"
    x = x or 0
    y = y or 0
    centered = centered or false
    color = color or color_white
    local text = {}
    text.x = x
    text.y = y
    text.centered = centered
    text.color = color
    text.font = font
    text.string = str
    text.type = "Text"
    table.insert(panel.elements, text)
    return text
end

function AEUI:AddButton(panel, str, func, font, x, y, centered, color)
    font = font or "AEUIDefault"
    x = x or 0
    y = y or 0
    centered = centered or false
    color = color or color_white
    func = func or function() end
    local button = {}
    button.x = x
    button.y = y
    button.centered = centered
    button.color = color
    button.font = font
    button.string = str
    button.type = "Button"
    button.onclick = func
    table.insert(panel.elements, button)
    return button
end

function AEUI:AddImage(panel, mat, func, x, y, w, h, color)
    font = font or "AEUIDefault"
    x = x or 0
    y = y or 0
    centered = centered or false
    color = color or color_white
    func = func or function() end
    local image = {}
    image.x = x
    image.y = y
    image.w = w
    image.h = h
    image.centered = centered
    image.color = color
    image.font = font
    image.mat = mat
    image.type = "Image"
    image.onclick = func
    table.insert(panel.elements, image)
    return image
end

function AEUI:Clear()
    table.Empty(AEUI.Panels)
    gui.EnableScreenClicker(false)
end

function AEUI:DrawElement(panel, data)
    AEUI.Elements[data.type](panel, data)
end

local function AEUIDraw()
    if AEUI.NoDraw then return end
    for k, v in ipairs(AEUI.Panels) do
        surface.SetAlphaMultiplier(v.alpha or 1)
        AEUI:DrawPanel(v)
        surface.SetAlphaMultiplier(1)
        if v.elements then
            for l, b in ipairs(v.elements) do
                AEUI:DrawElement(v, b)
            end
        end

        render.SetScissorRect(0, 0, 0, 0, false)
        local maxscroll = math.abs(v.maxscroll or 0)
        if (v.maxscroll or 0) > 0 then
            local ratio = math.abs((v.scroll or 0) / maxscroll)
            local visratio = v.h / maxscroll
            local height = maxscroll * visratio * 0.5
            surface.SetDrawColor(255, 255, 255)
            surface.DrawRect(SScaleX(v.x + v.w), SScaleY(v.y + height * ratio), SScaleX(8), SScaleY(height))
        end
    end

    if AEUI.HoveredElement then
        local e = AEUI.HoveredElement
        if e.hover then
            local mx, my = AEUI.MX + SScaleX(20), AEUI.MY + SScaleY(20)
            surface.SetTextColor(255, 255, 255)
            surface.SetFont("AEUIDefault")
            local tw, th = surface.GetTextSize(e.hover)
            if mx + tw > ScrW() then mx = mx - tw end
            surface.SetTextPos(mx + 2, my + 2)
            surface.SetDrawColor(AEUI.HoveredPanel.bgcolor)
            surface.DrawRect(mx, my, tw + 4, th + 4)
            surface.SetDrawColor(AEUI.HoveredPanel.outlinecolor)
            surface.DrawOutlinedRect(mx, my, tw + 4, th + 4)
            surface.DrawText(e.hover)
        end
    end
end

hook.Add("HUDPaint", "AEUIDraw", AEUIDraw)
hook.Add("StartCommand", "AEUI_StartCommand", function(ply, cmd)
    local mx, my = gui.MouseX(), gui.MouseY()
    AEUI.MX, AEUI.MY = mx, my
    for i = 1, #AEUI.Panels do
        local panel = AEUI.Panels[#AEUI.Panels + 1 - i]
        local x, y, w, h = SScaleX(panel.x), SScaleY(panel.y), SScaleX(panel.w), SScaleY(panel.h)
        if (mx > x and mx < x + w) and (my > y and my < y + h) then
            AEUI.HoveredPanel = panel
            break
        else
            AEUI.HoveredPanel = nil
        end
    end

    local wheelup = input.WasMousePressed(MOUSE_WHEEL_UP) and 63 or 0
    local wheeldown = input.WasMousePressed(MOUSE_WHEEL_DOWN) and -63 or 0
    local scrolldelta = wheelup + wheeldown
    local hoveredpanel = AEUI.HoveredPanel
    if scrolldelta ~= 0 and hoveredpanel and (hoveredpanel.maxscroll or 0) > 0 then hoveredpanel.scroll = math.Clamp((hoveredpanel.scroll or 0) + scrolldelta, -hoveredpanel.maxscroll, 0) end
    local click = input.WasMousePressed(MOUSE_LEFT)
    if hoveredpanel then
        for k, v in ipairs(hoveredpanel.elements) do
            if (v.onclick or v.hover) and (not v.greyed or not v.greyed()) and (v.w and v.h) then
                local x, y, w, h = SScaleX(hoveredpanel.x) + SScaleX(v.x), SScaleY(hoveredpanel.y) + SScaleY(v.y) + (hoveredpanel.scroll or 0), v.w, v.h
                if v.centered then
                    x = x - (w * 0.5)
                    y = y - (h * 0.5)
                end

                if (mx > x and mx < x + w) and (my > y and my < y + h) then
                    AEUI.HoveredElement = v
                    if v.onclick and click and CurTime() > AEUI.LastClick then
                        v.onclick(v)
                        AEUI.LastClick = CurTime() + 0.1
                    end

                    break
                else
                    AEUI.HoveredElement = nil
                end
            end
        end
    else
        AEUI.HoveredElement = nil
    end
end)

hook.Add("OnScreenSizeChanged", "AEUI_ScreenSize", function()
    AEUI.ScrW, AEUI.ScrH = ScrW(), ScrH()
    table.Empty(SScaleX_cached)
    table.Empty(SScaleY_cached)
    AEUIFonts()
end)

AEUI.Elements["Text"] = function(panel, data)
    local ox, oy = SScaleX(panel.x), SScaleY(panel.y) + (panel.scroll or 0)
    local isgreyed = false
    if data.greyed then isgreyed = data.greyed() end
    surface.SetFont(data.font)
    if isgreyed then
        local colr, colg, colb = data.color:Unpack()
        surface.SetDrawColor(colr, colg, colb, 50)
        surface.SetTextColor(colr, colg, colb, 50)
    else
        surface.SetDrawColor(data.color)
        surface.SetTextColor(data.color)
    end

    if not isgreyed and AEUI.HoveredElement == data then surface.SetTextColor(0, 230, 0) end
    local posy = 0
    local dataw, datah = 0, 0
    local str = data.string
    if isfunction(str) then str = str() or "" end
    for k, v in ipairs(string.Split(str, "\n")) do
        if v == "" then continue end
        if data.centered then
            local tw, th = surface.GetTextSize(v)
            local x, y = ox + SScaleX(data.x) - tw * 0.5, oy + SScaleY(data.y) - th * 0.5 + (th * (k - 1))
            datah = datah + th
            if tw > dataw then dataw = tw end
            if y > posy then posy = y + th * (k - 1) end
            surface.SetTextPos(x, y)
        else
            local tw, th = surface.GetTextSize(v)
            local x, y = ox + SScaleX(data.x), oy + SScaleY(data.y) + (th * (k - 1))
            datah = datah + th
            if tw > dataw then dataw = tw end
            if y > posy then posy = y + th * (k - 1) end
            surface.SetTextPos(x, y)
        end

        surface.DrawText(v)
    end

    data.w, data.h = dataw, datah
    posy = posy - oy - SScaleY(panel.h)
    if not panel.maxscroll or posy > panel.maxscroll then panel.maxscroll = posy end
end

AEUI.Elements["Button"] = function(panel, data)
    local ox, oy = SScaleX(panel.x), SScaleY(panel.y) + (panel.scroll or 0)
    surface.SetFont(data.font)
    local isgreyed = false
    if data.greyed then isgreyed = data.greyed() end
    if isgreyed then
        local colr, colg, colb = data.color:Unpack()
        surface.SetDrawColor(colr, colg, colb, 50)
        surface.SetTextColor(colr, colg, colb, 50)
    else
        surface.SetDrawColor(data.color)
        surface.SetTextColor(data.color)
    end

    if not isgreyed and AEUI.HoveredElement == data then
        surface.SetDrawColor(0, 230, 0)
        surface.SetTextColor(0, 230, 0)
    end

    local posy = 0
    local v = data.string
    local tw, th = surface.GetTextSize(v)
    local dataw, datah = 0, 0
    if data.centered then
        dataw, datah = tw + 4, th + 4
        surface.DrawOutlinedRect(ox + SScaleX(data.x) - tw * 0.5 - 2, oy + SScaleY(data.y) - th * 0.5 - 2, dataw, datah)
        local x, y = ox + SScaleX(data.x) - tw * 0.5, oy + SScaleY(data.y) - th * 0.5
        if y > posy then posy = y + th end
        surface.SetTextPos(x, y)
    else
        dataw, datah = tw, th
        surface.DrawOutlinedRect(ox + SScaleX(data.x), oy + SScaleY(data.y), tw, th)
        local x, y = ox + SScaleX(data.x), oy + SScaleY(data.y)
        if y > posy then posy = y + th end
        surface.SetTextPos(x, y)
    end

    data.w, data.h = dataw, datah
    surface.DrawText(v)
    posy = posy - oy - SScaleY(panel.h)
    if not panel.maxscroll or posy > panel.maxscroll then panel.maxscroll = posy end
end

AEUI.Elements["Image"] = function(panel, data)
    if not data.wo then data.wo, data.ho = data.w, data.h end
    local isgreyed = false
    if data.greyed then isgreyed = data.greyed() end
    local ox, oy = SScaleX(panel.x), SScaleY(panel.y) + (panel.scroll or 0)
    local dataw, datah = SScaleX(data.wo), SScaleY(data.ho)
    if not isgreyed and AEUI.HoveredElement == data then
        surface.SetDrawColor(0, 230, 0)
        surface.DrawOutlinedRect(ox + SScaleX(data.x), oy + SScaleY(data.y), dataw, datah)
    end

    local posy = 0
    local x, y = ox + SScaleX(data.x), oy + SScaleY(data.y)
    if isgreyed then
        local colr, colg, colb = data.color:Unpack()
        surface.SetDrawColor(colr, colg, colb, 50)
    else
        surface.SetDrawColor(data.color)
    end

    if y > posy then posy = y + datah end
    data.w, data.h = dataw, datah
    surface.SetMaterial(data.mat)
    surface.DrawTexturedRect(ox + SScaleX(data.x), oy + SScaleY(data.y), dataw, datah)
    posy = posy - oy - SScaleY(panel.h)
    if not panel.maxscroll or posy > panel.maxscroll then panel.maxscroll = posy end
end