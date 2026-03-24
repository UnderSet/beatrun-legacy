local push_right = function(self, x)
    assert(x ~= nil)
    self.tail = self.tail + 1
    self[self.tail] = x
end

local push_left = function(self, x)
    assert(x ~= nil)
    self[self.head] = x
    self.head = self.head - 1
end

local pop_right = function(self)
    if self:is_empty() then return nil end
    local r = self[self.tail]
    self[self.tail] = nil
    self.tail = self.tail - 1
    return r
end

local pop_left = function(self)
    if self:is_empty() then return nil end
    local r = self[self.head + 1]
    self.head = self.head + 1
    local r = self[self.head]
    self[self.head] = nil
    return r
end

local length = function(self) return self.tail - self.head end
local is_empty = function(self) return self:length() == 0 end
local iter_left = function(self)
    local i = self.head
    return function()
        if i < self.tail then
            i = i + 1
            return self[i]
        end
    end
end

local iter_right = function(self)
    local i = self.tail + 1
    return function()
        if i > self.head + 1 then
            i = i - 1
            return self[i]
        end
    end
end

local contents = function(self)
    local r = {}
    for i = self.head + 1, self.tail do
        r[i - self.head] = self[i]
    end
    return r
end

local methods = {
    push_right = push_right,
    push_left = push_left,
    peek_right = peek_right,
    peek_left = peek_left,
    pop_right = pop_right,
    pop_left = pop_left,
    rotate_right = rotate_right,
    rotate_left = rotate_left,
    remove_right = remove_right,
    remove_left = remove_left,
    iter_right = iter_right,
    iter_left = iter_left,
    length = length,
    is_empty = is_empty,
    contents = contents,
}

local new = function()
    local r = {
        head = 0,
        tail = 0
    }
    return setmetatable(r, {
        __index = methods
    })
end

hitpoints = new()
hitcolor = new()
hitnormal = new()
soundpoints = new()
GlitchIntensity = 0
local tr = {}
local tr_result = {}
local randvector = Vector()
local box_mins, box_maxs = Vector(-0.5, -0.5, -0.5), Vector(0.5, 0.5, 0.5)
local awareness = CreateClientConVar("blindness_awareness", 10000, true, false, "Awareness in hu")
local quality = CreateClientConVar("blindness_highquality", 1, true, false, "Draws quads instead of lines")
local boxang = Angle()
local vanishvec = Vector()
local vanishvecrand = Vector()
vanishrandx = 0.5
vanishrandy = 0.5
vanishrandz = 0.5
blindrandx = 0.5
blindrandy = 0.5
blindrandz = 0.5
blindrandobeyglitch = true
vanishlimit = 50
vanishusenormal = true
local red = Color(255, 0, 0)
local blue = Color(0, 0, 255)
local white = Color(210, 159, 110, 255)
local green = Color(0, 255, 0)
local circle = Material("circle.png", "nocull")
whiteg = white
customcolors = {Color(210, 159, 110, 255), Color(203, 145, 65, 255), Color(205, 205, 220, 255), Color(150, 50, 150, 255), Color(250, 20, 80, 255), Color(250, 120, 40, 255), Color(250, 20, 40, 255)}
function BlindSetColor(newcol)
    white = newcol
end

function BlindGetColor()
    return white
end

local grass = Color(20, 150, 10)
local sand = Color(76, 70, 50)
local glass = Color(10, 20, 150)
local limit = 3000
local pinged = false
local camvector, camang = Vector(), Angle()
local camlerp = 0
local lerp
local sound = nil
local bgm = nil
blindcolor = {0, 0, 0}
local colors = {
    [MAT_DEFAULT] = blue,
    [MAT_GLASS] = glass,
    [MAT_SAND] = sand,
    [MAT_DIRT] = sand,
    [MAT_GRASS] = grass,
    [MAT_FLESH] = red
}

local colorslist = {green, grass, sand, glass}
blindrandrendermin = 0.9
blindinverted = false
blindpopulate = true
blindpopulatespeed = 1000
blindfakepopulate = false
local sizemult = 1
function InvertColors()
    for k, v in ipairs(colorslist) do
        v.r = 255 - v.r
        v.g = 255 - v.g
        v.b = 255 - v.b
    end

    blindinverted = not blindinverted
    if blindinverted then
        white.r = 0
        white.g = 0
        white.b = 0
        sizemult = 4
        blindcolor[1] = 61
        blindcolor[2] = 61
        blindcolor[3] = 61
        blindrandrendermin = 1
    else
        white.r = 210
        white.g = 159
        white.b = 110
        blindcolor[1] = 0
        blindcolor[2] = 0
        blindcolor[3] = 0
        blindrandrendermin = 0.9
    end
end

function TogglePopulate()
    blindfakepopulate = not blindfakepopulate
end

local colorsclass = {
    ["prop_door_rotating"] = green,
    ["func_door_rotating"] = green,
    ["func_door"] = green
}

local blindedsounds = {
    ["ping.wav"] = true,
    ["music/locloop.wav"] = true,
    ["reset.wav"] = true,
    ["reset2.wav"] = true,
    ["glitch.wav"] = true,
    ["bad.wav"] = true,
    ["good.wav"] = true,
    ["A_TT_CD_01.wav"] = true,
    ["A_TT_CD_02.wav"] = true
}

local trw = {
    collisiongroup = COLLISION_GROUP_WORLD
}

local trwr = {}
local function IsInWorld(pos)
    trw.start = pos
    trw.endpos = pos
    trw.output = trwr
    util.TraceLine(trw)
    return trwr.HitWorld
end

local function RandomizeCam(eyepos, eyeang)
    local ctsin = 1 / (LocalPlayer():GetEyeTrace().Fraction * 200)
    if IsInWorld(eyepos) then ctsin = 100 end
    lerp = Lerp(25 * FrameTime(), camlerp, ctsin)
    camvector.x = eyepos.x + lerp
    camvector.y = eyepos.y + lerp
    camvector.z = eyepos.z + lerp
    camang.p = eyeang.p
    camang.y = eyeang.y
    camang.r = eyeang.r
end

local function populatetrace(eyepos)
    local af = awareness:GetFloat() or 1000
    randvector.x = eyepos.x + math.random(-af, af)
    randvector.y = eyepos.y + math.random(-af, af)
    randvector.z = eyepos.z + math.random(-af, af)
    tr.start = eyepos
    tr.endpos = randvector
    tr.output = tr_result
    if not IsValid(tr.filter) then tr.filter = LocalPlayer() end
    util.TraceLine(tr)
    return tr_result
end

local function Echo(t)
    table.insert(soundpoints, t.Pos)
    if not blindedsounds[t.SoundName] and t.SoundName:Left(3) ~= "te/" then return false end
end

local blindcolor = blindcolor
local fakepopulatevec = Vector(1, 2, 3)
local mathrandom = math.random
local function Blindness(origin, angles)
    local ply = LocalPlayer()
    local eyepos = origin
    local eyeang = angles
    local FT = FrameTime()
    local quality = quality:GetBool()
    local calcview = hook.Run("CalcView", ply, eyepos, eyeang, ply:GetFOV(), 0, 100)
    if istable(calcview) then
        if calcview.origin then eyepos:Set(calcview.origin) end
        if calcview.angles then eyeang:Set(calcview.angles) end
    end

    local hitpointscount
    local vel_l = ply:GetVelocity():Length()
    local vel = vel_l * 0.005
    local randrender = math.Rand(blindrandrendermin, 1)
    render.Clear(blindcolor[1] * randrender, blindcolor[2] * randrender, blindcolor[3] * randrender, 0)
    if blindpopulate then
        for i = 0, FT * blindpopulatespeed do
            if not blindfakepopulate then
                local trace = populatetrace(eyepos)
                if trace.Hit then
                    hitpoints:push_right(trace.HitPos)
                    local hcol = colors[trace.MatType]
                    local hcolclass = colorsclass[trace.Entity:GetClass()]
                    hitcolor:push_right(hcol or hcolclass or white)
                    local invert = mathrandom()
                    if invert < 0.05 then trace.HitNormal:Mul(-1) end
                    hitnormal:push_right(trace.HitNormal)
                    if hitpoints:length() > limit then
                        hitpoints:pop_left()
                        hitcolor:pop_left()
                        hitnormal:pop_left()
                    end
                end
            else
                hitpoints:push_right(fakepopulatevec)
                hitcolor:push_right(white)
                hitnormal:push_right(fakepopulatevec)
                if hitpoints:length() > limit then
                    hitpoints:pop_left()
                    hitcolor:pop_left()
                    hitnormal:pop_left()
                end
            end
        end
    end

    hitpointscount = soundpoints:length()
    while hitpointscount > limit do
        soundpoints:pop_left()
        hitpointscount = soundpoints:length()
    end

    RandomizeCam(eyepos, eyeang)
    if sound then sound:ChangeVolume((lerp - 0.1) * 0.25) end
    cam.Start3D(camvector, camang)
    for k, v in ipairs(Checkpoints) do
        v:DrawLOC()
    end

    local lastpos = hitpoints[hitpoints.tail]
    local f = eyeang:Forward()
    local eyediff = Vector()
    render.SetMaterial(circle)
    local k = limit
    local k2 = 0
    local vanishlimit = vanishlimit
    local vanishrandx = vanishrandx
    local vanishrandy = vanishrandy
    local vanishrandz = vanishrandz
    local blindrandx = blindrandx
    local blindrandy = blindrandy
    local blindrandz = blindrandz
    local blindrandobeyglitch = blindrandobeyglitch
    for v in hitpoints:iter_right() do
        eyediff:Set(v)
        eyediff:Sub(eyepos)
        if f:Dot(eyediff) / eyediff:Length() > 0.4 then
            local col = hitcolor[hitcolor.tail - k2] or white
            col.a = 255 * (k / limit)
            if blindrandobeyglitch then
                randvector[1] = mathrandom(-blindrandx, blindrandx) + lerp + vel
                randvector[2] = mathrandom(-blindrandy, blindrandy) + lerp + vel
                randvector[3] = mathrandom(-blindrandz, blindrandz) + lerp + vel
            else
                randvector[1] = mathrandom(-blindrandx, blindrandx)
                randvector[2] = mathrandom(-blindrandy, blindrandy)
                randvector[3] = mathrandom(-blindrandz, blindrandz)
            end

            if col.a < vanishlimit and v ~= fakepopulatevec then
                if vanishusenormal then
                    vanishvec:Set(hitnormal[hitnormal.tail - k2])
                    vanishvec:Mul(FT * 100)
                    v:Sub(vanishvec)
                end

                vanishvecrand:SetUnpacked(math.random(-vanishrandx, vanishrandx), math.random(-vanishrandy, vanishrandy), math.random(-vanishrandz, vanishrandz))
                v:Add(vanishvecrand)
            end

            eyediff:Set(v)
            eyediff:Add(randvector)
            if v ~= fakepopulatevec then
                if quality then
                    render.DrawQuadEasy(eyediff, f, 1.75 + vel, 1.75 + vel, col)
                else
                    render.DrawLine(eyediff, v, col)
                end
            end

            GlitchIntensity = lerp
            lastpos = v
        end

        k = k - 1
        k2 = k2 + 1
    end

    local ctsin = math.sin(CurTime())
    local col = white
    col.a = alpha
    cam.End3D()
    DrawDeletionText()
    hook.Run("RenderScreenspaceEffects")
    local AEUIDraw = hook.GetTable()["HUDPaint"].AEUIDraw
    if AEUIDraw then
        cam.Start2D()
        AEUIDraw()
        cam.End2D()
    end
    return true
end

blinded = false
local function BlindnessPreUI()
    if blinded then
        cam.Start3D()
        render.Clear(10, 10, 10, 0)
        cam.End3D()
        draw.NoTexture()
        if not bgm:IsPlaying() then
            bgm:Play()
            sound:Play()
        end
    end
end

local te = "te/metamorphosis/"
local jingles = {
    ["land"] = te .. "3-linedrop",
    ["jump"] = te .. "1-linemove",
    ["jumpwallrun"] = te .. "3-spin",
    ["wallrunh"] = te .. "3-spin",
    ["wallrunv"] = te .. "3-spin",
    ["coil"] = te .. "3-spin"
}

local jinglescount = {
    ["land"] = 11,
    ["jump"] = 6,
    ["jumpwallrun"] = 6,
    ["wallrunh"] = 6,
    ["wallrunv"] = 6,
    ["coil"] = 6,
}

local function BlindnessJingles(event)
    if jingles[event] then LocalPlayer():EmitSound(jingles[event] .. math.random(1, jinglescount[event]) .. ".wav") end
end

function ToggleBlindness(toggle)
    blinded = toggle
    if blinded then
        local activewep = LocalPlayer():GetActiveWeapon()
        local usingrh = IsValid(activewep) and activewep:GetClass() == "runnerhands"
        if usingrh then
            if activewep.RunWind1 then
                activewep.RunWind1:Stop()
                activewep.RunWind2:Stop()
            end
        end

        gui.HideGameUI()
        hook.Add("EntityEmitSound", "Echo", Echo)
        hook.Add("RenderScene", "Blindness", Blindness)
        hook.Add("PreDrawHUD", "Blindness", BlindnessPreUI)
        hook.Add("RenderScreenspaceEffects", "CA", RenderCA)
        if not sound then sound = CreateSound(LocalPlayer(), "glitch.wav") end
        if not bgm then bgm = CreateSound(LocalPlayer(), "music/locloop.wav") end
        sound:PlayEx(0, 100)
        if not incredits then
            bgm:Play()
            bgm:ChangeVolume(0.5)
        else
            EmitSound("music/Sunrise.mp3", vector_origin, -2, 0, 1, 75, SND_SHOULDPAUSE)
        end
    else
        hook.Remove("EntityEmitSound", "Echo")
        hook.Remove("RenderScene", "Blindness")
        hook.Remove("PreDrawHUD", "Blindness")
        hook.Remove("RenderScreenspaceEffects", "CA")
        surface.SetAlphaMultiplier(1)
        if sound then sound:Stop() end
        if bgm then bgm:Stop() end
    end
end

net.Receive("BlindPlayers", function() ToggleBlindness(net.ReadBool()) end)
net.Receive("BlindNPCKilled", function() LocalPlayer():EmitSound("bad.wav", 50, 100 + math.random(-5, 2)) end)
hook.Add("InitPostEntity", "Beatrun_LOC", function()
    if GetGlobalBool("LOC") then ToggleBlindness(true) end
    hook.Remove("EntityEmitSound", "zzz_TFA_EntityEmitSound")
    hook.Remove("InitPostEntity", "Beatrun_LOC")
end)