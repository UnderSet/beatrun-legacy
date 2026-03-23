local qslide_duration = 4
local qslide_speedmult = 1

local slide_sounds = {
    [MAT_DIRT] = {"datae/fol_slide_dirt_01.wav", "datae/fol_slide_dirt_02.wav", "datae/fol_slide_dirt_03.wav", "datae/fol_slide_dirt_04.wav"},
    [MAT_SAND] = {"datae/fol_slide_sand_01.wav", "datae/fol_slide_sand_02.wav", "datae/fol_slide_sand_03.wav", "datae/fol_slide_sand_04.wav"},
    [MAT_METAL] = {"datae/fol_slide_metal_01.wav", "datae/fol_slide_metal_02.wav", "datae/fol_slide_metal_03.wav"},
    [MAT_GLASS] = {"datae/fol_slide_glass_01.wav", "datae/fol_slide_glass_02.wav", "datae/fol_slide_glass_03.wav", "datae/fol_slide_glass_04.wav"},
    [MAT_GRATE] = {"datae/fol_slide_grate_01.wav",},
    [MAT_SLOSH] = {"ambient/water/water_splash1.wav", "ambient/water/water_splash2.wav", "ambient/water/water_splash3.wav"},
    [0] = {"datae/fol_slide_generic_01.wav", "datae/fol_slide_generic_02.wav", "datae/fol_slide_generic_03.wav"}
}

local slideloop_sounds = {
	[MAT_GLASS] = "MirrorsEdge/Slide/ME_FootStep_GlassSlideLoop.wav",
	[0] = "MirrorsEdge/Slide/ME_FootStep_ConcreteSlideLoop.wav",
}

slide_sounds[MAT_GRASS] = slide_sounds[MAT_DIRT]
slide_sounds[MAT_SNOW] = slide_sounds[MAT_DIRT]
slide_sounds[MAT_VENT] = slide_sounds[MAT_METAL]

local animtable = {
    ["AnimString"] = "slidestart",
    ["animmodelstring"] = "climbanim",
	["lockang"] = false,
	["followplayer"] = true,
	["allowmove"] = true,
	["ignorez"] = true,
    ["usefullbody"] = 2,
    ["BodyAnimSpeed"] = 1.1,
    ["deleteonend"] = false,
}

local blocked = false

local function SlidingAnimThink()
	local ba = BodyAnim
	local ply = LocalPlayer()
	if !ply:GetSliding() then
		hook.Remove("Think", "SlidingAnimThink")
	end
	if IsValid(ba) and ba:GetSequence() == 1 and BodyAnimCycle >= 1 then
		ba:ResetSequence(2)
		BodyAnimCycle = 0
		BodyAnim:SetCycle(0)
	end
	
	if IsValid(ba) then
		local tr = util.QuickTrace(ply:GetPos(), Vector(0,0,-32), ply)
		local normal = tr.HitNormal
		local oldang = ba:GetAngles()
		local ang = ba:GetAngles()
		ang.x = math.max(normal:Angle().x+90, 360)
		
		local newang = LerpAngle(20*FrameTime(), oldang, ang)
		ba:SetAngles(newang)
	end
end

local function SlidingAnimStart()
	if !IsFirstTimePredicted() and !game.SinglePlayer() then return end
	local ply = LocalPlayer()
    ply.SlidingAngle = ply:GetVelocity():Angle()
    if VManip then
        VManip:PlayAnim("vault")
    end
	deleteonend = false
	RemoveBodyAnim()
	StartBodyAnim(animtable)
	BodyAnim:SetAngles(ply.SlidingAngle)
	ply.OrigEyeAng = ply.SlidingAngle
	if ply:Crouching() then
		BodyAnim:SetCycle(0.2)
		BodyAnimCycle = 0.2
	end
	
	hook.Add("Think", "SlidingAnimThink", SlidingAnimThink)
end

local function SlidingAnimEnd()
	if !IsValid(BodyAnim) then return end
	deleteonend = true
	BodyAnim:ResetSequence("slideend")
	BodyAnimCycle = 0
	BodyAnim:SetCycle(0)
	BodyAnimSpeed = 1.3
	
	if blocked then
		timer.Simple(0.1, function()
			if IsValid(BodyAnim) then
				RemoveBodyAnim()
			end
		end)
	end
	hook.Remove("Think", "SlidingAnimThink")
end

if game.SinglePlayer() then
    if SERVER then
        util.AddNetworkString("sliding_spfix")
        util.AddNetworkString("sliding_spend")
    else
        net.Receive("sliding_spfix", function()
			SlidingAnimStart()
        end)
        net.Receive("sliding_spend", function()
			blocked = net.ReadBool()
			SlidingAnimEnd()
        end)
    end
end

local slidepunch = Angle(-5, 0, -5.5)
local slidepunchend = Angle(3, 0, -3.5)
local trace_down = Vector(0, 0, 32)
local trace_up = Vector(0, 0, 32)
local trace_tbl = {}

local function SlideSurfaceSound(ply, pos)
    trace_tbl.start = pos
    trace_tbl.endpos = pos - trace_down
    trace_tbl.filter = ply
    local tr = util.TraceLine(trace_tbl)
    local sndtable = slide_sounds[tr.MatType] or slide_sounds[0]
    ply:EmitSound(sndtable[math.random(#sndtable)], 75, 100 + math.random(-4, 4))
    ply:EmitSound("datae/fol_sprint_rustle_0" .. math.random(1, 5) .. ".wav")

    if ply:WaterLevel() > 0 then
        sndtable = slide_sounds[MAT_SLOSH]
        ply:EmitSound(sndtable[math.random(#sndtable)])
    end
	
	return tr.MatType
end

local function SlideLoopSound(ply, pos, mat)
    local sndtable = slideloop_sounds[mat] or slideloop_sounds[0]
    ply.SlideLoopSound = CreateSound(ply, sndtable)
	ply.SlideLoopSound:PlayEx(0.25, 100)
end

hook.Add("SetupMove", "qslide", function(ply, mv, cmd)
    if not ply.OldDuckSpeed then
        ply.OldDuckSpeed = ply:GetDuckSpeed()
        ply.OldUnDuckSpeed = ply:GetUnDuckSpeed()
    end

    local sliding = ply:GetSliding()
    local speed = mv:GetVelocity():Length()
    local runspeed = ply:GetRunSpeed()
    local slidetime = math.max(0.1, qslide_duration)
    local ducking = mv:KeyDown(IN_DUCK)
    local crouching = ply:Crouching()
    local sprinting = mv:KeyDown(IN_SPEED)
    local onground = ply:OnGround()
    local CT = CurTime()

    if CurTime() > ply:GetSlidingDelay() and ducking and sprinting and onground and not sliding and speed > runspeed * 0.5 then
        ParkourEvent("slide", ply)
		ply:SetSliding(true)
        ply:SetSlidingTime(CT + slidetime)
        ply:ViewPunch(slidepunch)
        ply:SetDuckSpeed(0.1)
        ply:SetUnDuckSpeed(0.05)
        ply.SlidingAngle = mv:GetVelocity():Angle()
		ply.SlidingVel = math.min(mv:GetVelocity():Length()*1.5, 541.44)*ply:GetOverdriveMult()

        if SERVER then
            local pos = mv:GetOrigin()
            local mat = SlideSurfaceSound(ply, pos)
			SlideLoopSound(ply, pos, mat)
        end
		
        if game.SinglePlayer() then
            net.Start("sliding_spfix")
            net.Send(ply)
		end
		
		if CLIENT then
			SlidingAnimStart()
			hook.Add("Think", "SlidingAnimThink", SlidingAnimThink)
		end
    elseif (not ducking or not onground) and sliding then
		blocked = false
		if not ducking then
			ply.SlideHull = ply.SlideHull or {}
			ply.SlideHullOut = ply.SlideHullOut or {}
			local hulltr = ply.SlideHull
			local hulltrout = ply.SlideHullOut
			local mins, maxs = ply:GetHull()
			local origin = mv:GetOrigin()
			hulltr.start = origin
			hulltr.endpos = origin
			hulltr.mins, hulltr.maxs = mins, maxs
			hulltr.filter = ply
			hulltr.mask = MASK_PLAYERSOLID
			hulltr.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
			hulltr.output = hulltrout
			
			util.TraceHull(hulltr)
			if hulltrout.Hit then
				blocked = true
			end
		end
		
		local slidedelta = (ply:GetSlidingTime() - CT) / slidetime
		if slidedelta > 0.5 and ply.SlidingVel > 350 then
			ply:SetMEMoveLimit(405)
			ply:SetMESprintDelay(0)
		end
		
		ply:SetSliding(false)
		ply:SetSlidingTime(0)
		if game.SinglePlayer() then
			net.Start("sliding_spend")
			net.WriteBool(blocked)
			net.Send(ply)
		elseif CLIENT then
			SlidingAnimEnd()
		end
		ply:SetSlidingDelay(CurTime()+0.5)
		if SERVER then
			if ply.SlideLoopSound then
				ply.SlideLoopSound:Stop()
			end
			ply:EmitSound("datae/fol_sprint_rustle_0" .. math.random(1, 5) .. ".wav")
		end
		ply:ConCommand("-duck")
    end

    sliding = ply:GetSliding()

    if sliding then
        local slidedelta = (ply:GetSlidingTime() - CT) / slidetime
        local FT = FrameTime()
        local TargetTick = ((1 / FT) / 66.66) * 2.0831 --wtf
        local speed = ((ply.SlidingVel) * math.min(0.85, ((ply:GetSlidingTime() - CT + 0.5) / slidetime)) * (1 / engine.TickInterval()) * engine.TickInterval()) * qslide_speedmult
        mv:SetVelocity(ply.SlidingAngle:Forward() * speed)
        local pos = mv:GetOrigin()

        if not ply.SlidingLastPos then
            ply.SlidingLastPos = pos
        end

        if pos.z > ply.SlidingLastPos.z + 1 then
            ply:SetSlidingTime(ply:GetSlidingTime() - 0.025)
        elseif slidedelta < 0.75 and pos.z < ply.SlidingLastPos.z - 0.25 then
            ply:SetSlidingTime(CT + slidetime)
        end

        ply.SlidingLastPos = pos

        if CT > ply:GetSlidingTime() then
            ply:SetSliding(false)
            ply:SetSlidingTime(0)
			if SERVER and game.SinglePlayer() then
				net.Start("sliding_spend")
				net.Send(ply)
			elseif CLIENT then
				SlidingAnimEnd()
			end
			ply:SetSlidingDelay(CurTime()+0.5)
			if SERVER then
				ply.SlideLoopSound:Stop()
				ply:EmitSound("datae/fol_sprint_rustle_0" .. math.random(1, 5) .. ".wav")
			end
			ply:ConCommand("-duck")
        end
    end

    sliding = ply:GetSliding()

    if not crouching and not sliding then
        ply:SetDuckSpeed(ply.OldDuckSpeed)
        ply:SetUnDuckSpeed(ply.OldUnDuckSpeed)
    end
end)

hook.Add("PlayerFootstep", "qslidestep", function(ply)
    if ply:GetSliding() then return true end
end)

hook.Add("StartCommand", "qslidespeed", function(ply, cmd)
    if ply:GetSliding() then
        cmd:RemoveKey(IN_SPEED)
        cmd:RemoveKey(IN_JUMP)
        cmd:ClearMovement()
        local slidetime = math.max(0.1, qslide_duration)

        if (ply:GetSlidingTime() - CurTime()) / slidetime > 0.95 then
            cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_DUCK))
        end
    end
end)
