local function SwingpipeCheck(ply, mv, cmd)
	local mins, maxs = ply:GetCollisionBounds()
	mins.x, maxs.x = mins.x * 4, maxs.x * 4
	mins.y, maxs.y = mins.y * 4, maxs.y * 4
	
	local tr, trout = ply.Monkey_tr, ply.Monkey_trout
	tr.start = mv:GetOrigin()
	tr.endpos = tr.start
	tr.mins, tr.maxs = mins, maxs
	tr.filter = ply
	util.TraceHull(tr)
	if IsValid(trout.Entity) and trout.Entity:GetClass() == "br_swingpipe" and (ply:GetSwingbarLast() != trout.Entity or CurTime() > ply:GetSBDelay()) then
		local swingpipe = trout.Entity
		local dot = cmd:GetViewAngles():Forward():Dot(swingpipe:GetAngles():Forward())
		if CLIENT then swingpipe:SetPredictable(true) end
		local pos = swingpipe:GetPos()
		pos.z = mv:GetOrigin().z
		ply:SetSwingpipe(swingpipe)
		ply:SetWallrunTime(0)
		ply:SetSBDir(dir)
		ply:SetSBStartLerp(0)
		ply:SetSBOffset(0)
		ply:SetSBPeak(0)
		ply:SetClimbingStart(pos)
		
		mv:SetVelocity( vector_origin )
		if mv:KeyDown(IN_FORWARD) or mv:GetVelocity():Length() > 150 then
			ply:SetSBOffsetSpeed(2)
		else
			ply:SetSBOffsetSpeed(0)
		end
		
		if (CLIENT and IsFirstTimePredicted()) or game.SinglePlayer() then ply:EmitSound("Handsteps.ConcreteHard") end
	end
end

local radius = 40
local red = Color(255, 0, 0, 200)
local circlepos = Vector()
local axis = Vector(0,1,0)
local function SwingpipeThink(ply, mv, cmd)
	local swingpipe = ply:GetSwingpipe()
	if !ply:Alive() then
		ply:SetMoveType(MOVETYPE_WALK)
		ply:SetSwingbar(nil)
		ply:SetSBDelay(CurTime()+1)
		if CLIENT then swingpipe:SetPredictable(false) end
		return
	end
	mv:SetForwardSpeed(0)
	mv:SetSideSpeed(0)
	local pos = ply:GetClimbingStart()
	local dir = (ply:GetSBDir() and 1) or -1
	local ang = swingpipe:GetAngles()
	local startlerp = ply:GetSBStartLerp()
	ang:RotateAroundAxis(axis, 90)
	ply:SetMoveType(MOVETYPE_NONE)
	local angle = ply:GetSBOffset() * math.pi*2 / 180
	circlepos:SetUnpacked(0, math.cos(angle)*radius*dir, -math.sin(angle)*radius)
	circlepos:Rotate(ang)
	pos = pos + circlepos
	local origin = (startlerp < 1 and LerpVector(startlerp, mv:GetOrigin(), pos)) or pos
	
	ply:SetSBStartLerp( math.min(startlerp + (5 * FrameTime()), 1) )
	
	ply:SetSBOffset(ply:GetSBOffset() + 150 * FrameTime())
	mv:SetOrigin(origin)
	if CLIENT or game.SinglePlayer() then ply:SetEyeAngles(circlepos:Angle()) end

	if ply:GetSBOffset() > 75 then
		ply:SetMoveType(MOVETYPE_WALK)
		ply:SetSwingbarLast(ply:GetSwingpipe())
		ply:SetSwingpipe(nil)
		mv:SetVelocity( cmd:GetViewAngles():Forward()*250 + Vector(0,0,100) )
		ply:SetSBDelay(CurTime()+1)
	end
end

local function Swingpipe(ply, mv, cmd)
	-- if !ply.Monkey_tr then
		-- ply.Monkey_tr = {}
		-- ply.Monkey_trout = {}
		-- ply.Monkey_tr.output = ply.Monkey_trout
	-- end
	
	-- if !ply:OnGround() and !IsValid(ply:GetSwingpipe()) and ply:GetMoveType() == MOVETYPE_WALK then
		-- SwingpipeCheck(ply, mv, cmd)
	-- end
	
	-- if IsValid(ply:GetSwingpipe()) then
		-- SwingpipeThink(ply, mv, cmd)
	-- end
end
hook.Add("SetupMove", "Swingpipe", Swingpipe)