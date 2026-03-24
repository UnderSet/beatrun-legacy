
local vwrtime = 1.5
local hwrtime = 1.5

local tiltdir = 1
local tilt = 0
local view = {}

local animtable = {
    ["AnimString"] = "verticalwallrun",
    ["animmodelstring"] = "mantleanim",
	["lockang"] = false,
	["followplayer"] = true,
	["allowmove"] = true,
	["ignorez"] = true,
    ["usefullbody"] = 2,
    ["BodyAnimSpeed"] = 1.1,
    ["deleteonend"] = false,
}
local function WallrunningAnimSpeed()
	if IsValid(BodyAnim) and BodyAnimString == "verticalwallrun" then
		BodyAnimSpeed = 1.2 * math.Clamp((LocalPlayer():GetWallrunTime() - CurTime()) / vwrtime, 0.1, 1)
	else
		hook.Remove("Think", "WallrunningAnimSpeed")
	end
	
	-- if ply:GetWallrun() == 0 and IsValid(BodyAnim) and BodyAnimString == "verticalwallrun" then --prediction error?
		-- RemoveBodyAnim()
		-- hook.Remove("Think", "WallrunningAnimSpeed")
	-- end
end

local function WallrunningTilt(ply, pos, ang, fov)
	local wr = ply:GetWallrun()
	if wr < 2 and tilt == 0 then
		hook.Remove("CalcView", "WallrunningTilt")
		return
	end
	ang.z = tilt
	
	tilt = math.Approach( tilt, ((wr >= 2 and 10*tiltdir) or 0), RealFrameTime() * ((wr >= 2 and 50) or 65) ) 
end

if SERVER then util.AddNetworkString("BodyAnimWallrun") util.AddNetworkString("WallrunTilt") end
if CLIENT then
	net.Receive("BodyAnimWallrun", function()
		local a = net.ReadBool()
		if a then
			StartBodyAnim(animtable)
			hook.Add("Think", "WallrunningAnimSpeed", WallrunningAnimSpeed)
		else
			RemoveBodyAnim()
		end
	end)
	
	net.Receive("WallrunTilt", function()
		if net.ReadBool() then
			tiltdir = -1
		else
			tiltdir = 1
		end
		hook.Add("CalcView", "WallrunningTilt", WallrunningTilt)
	end)
end

local wrmins, wrmaxs = Vector(-16, -16, 0), Vector(16, 16, 16)
local function WallrunningThink(ply, mv, cmd)
	local wr = ply:GetWallrun()
	if wr != 0 and ply:OnGround() then
		ply:SetWallrunTime(0)
	end
	
	if mv:KeyPressed(IN_DUCK) then
		ply:SetWallrunTime(0)
		mv:SetButtons(mv:GetButtons()-IN_DUCK)
	end
	
	if wr == 4 then --vertical quickturn
		local ang = cmd:GetViewAngles()
		ang.x = 0
		local vel = ang:Forward()*30
		vel.z = 25
		mv:SetVelocity(vel)
		mv:SetSideSpeed(0)
		mv:SetForwardSpeed(0)
		
		if CurTime() > ply:GetWallrunTime() or mv:GetVelocity():Length() < 10 then
			ply:SetWallrun(0)
			ply:SetQuickturn(false)
			mv:SetVelocity(vel*4)
			local activewep=ply:GetActiveWeapon()
			if IsValid(activewep) then usingrh=activewep:GetClass()=="runnerhands" end 
			if usingrh then
				activewep:SendWeaponAnim(ACT_VM_HITCENTER)
				activewep:SetBlockAnims(false)
			end
			return
		end
		
		if mv:KeyPressed(IN_JUMP) then
			vel.z = 30
			vel:Mul(ply:GetOverdriveMult())
			mv:SetVelocity(vel*8)
			ply:SetWallrun(0)
			ply:SetQuickturn(false)
			ParkourEvent("jumpwallrun", ply)
			local activewep=ply:GetActiveWeapon()
			if IsValid(activewep) then usingrh=activewep:GetClass()=="runnerhands" end 
			if usingrh then
				activewep:SendWeaponAnim(ACT_VM_HITCENTER)
				activewep:SetBlockAnims(false)
			end
		end
		return
	end
	
	if wr == 1 then
		local velz = math.Clamp((ply:GetWallrunTime() - CurTime()) / vwrtime, 0.1, 1)
		local vecvel = Vector()
		vecvel.z = 200*velz
		vecvel:Add(ply:GetWallrunDir():Angle():Forward()*-50)
		vecvel:Mul(ply:GetOverdriveMult())
		mv:SetVelocity(vecvel)
		
		mv:SetForwardSpeed(0)
		mv:SetSideSpeed(0)
	
		local tr = ply.WallrunTrace
		local trout = ply.WallrunTraceOut
		local eyeang = ply.WallrunOrigAng or Angle()
		eyeang.x = 0
		tr.start = ply:EyePos()
		tr.endpos = tr.start + eyeang:Forward()*40
		tr.filter = ply
		tr.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
		tr.output = trout
		util.TraceLine(tr)
		if !trout.Hit then
			ply:SetWallrunTime(0)
		end
	end
	
	if wr >= 2 then
		local dir = (wr == 2 and 1) or -1
		mv:SetForwardSpeed(0)
		mv:SetSideSpeed(0)
		local vecvel = ply:GetWallrunDir():Angle():Right()*dir * math.Clamp(ply.WallrunOrigVel:Length()+50, 75, 405)	
		local tr = ply.WallrunTrace
		local trout = ply.WallrunTraceOut
		local mins, maxs = ply:GetCollisionBounds()
		mins.z = -32
		
		if !ply:GetWallrunElevated() then
			tr.start = mv:GetOrigin()
			tr.endpos = tr.start
			tr.mins, tr.maxs = mins, maxs
			tr.filter = ply
			tr.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
			tr.output = trout
			util.TraceHull(tr)
		end
		if !ply:GetWallrunElevated() and trout.Hit then
			vecvel.z = 100
		elseif !ply:GetWallrunElevated() and !trout.Hit then
			ply:SetWallrunElevated(true)
		end
		
		if ply:GetWallrunElevated() then
			vecvel.z = 5
		end
		
		if vecvel:Length() > 300 then
			vecvel:Mul(ply:GetOverdriveMult())
		end
		mv:SetVelocity(vecvel)
		
		local eyeang = ply:EyeAngles()
		eyeang.x = 0
		
		tr.start = ply:EyePos()
		tr.endpos = tr.start + eyeang:Right() * 45*dir
		tr.mins, tr.maxs = wrmins, wrmaxs
		tr.filter = ply
		tr.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
		tr.output = trout
		util.TraceHull(tr)
		if !trout.Hit then
			tr.start = ply:EyePos()
			tr.endpos = tr.start + eyeang:Forward() * -60
			tr.filter = ply
			tr.output = trout
			util.TraceLine(tr)
			if !trout.Hit then
				ply:SetWallrunTime(0)
			else
				if !ply:GetWallrunDir():IsEqualTol(trout.HitNormal, 0.75) then
					ply:SetWallrunTime(0)
				end
				ply:SetWallrunDir(trout.HitNormal)
			end
		else
			tr.start = ply:EyePos()
			tr.endpos = tr.start + eyeang:Right() * 45*dir
			tr.filter = ply
			tr.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
			tr.output = trout
			util.TraceLine(tr)
			if trout.Hit then
				if !ply:GetWallrunDir():IsEqualTol(trout.HitNormal, 0.75) then
					ply:SetWallrunTime(0)
				end
				ply:SetWallrunDir(trout.HitNormal)
			end
		end
		
		if mv:KeyPressed(IN_JUMP) and ply:GetWallrunTime()-CurTime() != hwrtime then
			ply:SetQuickturn(false)
			ply:SetWallrunTime(0)
			mv:SetVelocity(eyeang:Forward() * math.max(150, vecvel:Length()-50) + Vector(0,0,250))
			
			ParkourEvent("jumpwallrun", ply)
			if IsFirstTimePredicted() then ply:EmitSound("Wallrun.Concrete") end
		end
	end
	
	if CurTime() > ply:GetWallrunSoundTime() then
		local delay
		local wr = ply:GetWallrun()
		if wr == 1 then
			delay = math.Clamp(math.abs((ply:GetWallrunTime() - CurTime() - 2.75)) / vwrtime*0.165, 0.175, 0.3)
		else
			delay = math.Clamp(math.abs((ply:GetWallrunTime() - CurTime() - 2.75)) / hwrtime*0.165, 0.15, 1.75)
		end
		
		if SERVER then
			if (wr == 1 and delay == 0.175) or (wr > 1 and delay == 0.15) then
				ply:EmitSound("Wallrun.Concrete")
			else
				ply:EmitSound("WallrunFast.Concrete")
			end
		end
		ply:SetWallrunSoundTime(CurTime() + delay)
		ply:ViewPunch(Angle(0.25,0,0))
	end
	
	if CurTime() > ply:GetWallrunTime() or mv:GetVelocity():Length() < 10 then
		ply:SetQuickturn(false)
		if CLIENT and IsFirstTimePredicted() and wr == 1 then
			RemoveBodyAnim()
		elseif game.SinglePlayer() then
			net.Start("BodyAnimWallrun")
			net.WriteBool(false)
			net.Send(ply)
		end
		ply:SetWallrun(0)
		return
	end
end

local upcheck = Vector(0,0,75)
local function WallrunningCheck(ply, mv, cmd)

	if !ply.WallrunTrace then
		ply.WallrunTrace = {}
		ply.WallrunTraceOut = {}
	end
	local eyeang = ply:EyeAngles()
	eyeang.x = 0

	--Vertical
	if !ply:OnGround() and mv:KeyDown(IN_JUMP) then
		local tr = ply.WallrunTrace
		local trout = ply.WallrunTraceOut
		tr.start = ply:EyePos()
		tr.endpos = tr.start + eyeang:Forward()*25
		tr.filter = ply
		tr.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
		tr.output = trout
		util.TraceLine(tr)
		
		if trout.HitNormal:IsEqualTol(ply:GetWallrunDir(), 0.25) then return end
		if (trout.Entity and trout.Entity.IsNPC) and (trout.Entity.NoWallrun or trout.Entity:IsNPC() or trout.Entity:IsPlayer()) then
			return false
		end
		if trout.Hit then
			tr.start = tr.start+Vector(0,0,10)
			tr.endpos = tr.start + eyeang:Forward()*30
			util.TraceLine(tr)
			if trout.Hit then
				if SERVER then ply:EmitSound("Bump.Concrete") end
				ply.WallrunOrigAng = eyeang
				ply:SetWallrunDir(trout.HitNormal)
				ply:ViewPunch(Angle(-5,0,0))
				ply:SetWallrun(1)
				ply:SetWallrunTime(CurTime()+vwrtime)
				ply:SetWallrunSoundTime(CurTime() + 0.1)
				ParkourEvent("wallrunv", ply)
				
				if CLIENT and IsFirstTimePredicted() then
					StartBodyAnim(animtable)
					hook.Add("Think", "WallrunningAnimSpeed", WallrunningAnimSpeed)
				elseif game.SinglePlayer() then
					net.Start("BodyAnimWallrun")
					net.WriteBool(true)
					net.Send(ply)
				end
				return
			end
		end
	end
	
	--Horizontal Right
	if (mv:KeyDown(IN_JUMP) and !ply:OnGround()) or mv:KeyPressed(IN_JUMP) then
		local tr = ply.WallrunTrace
		local trout = ply.WallrunTraceOut
		tr.start = ply:EyePos()
		tr.endpos = tr.start + eyeang:Right()*30
		tr.filter = ply
		tr.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
		tr.output = trout
		util.TraceLine(tr)
		
		if trout.HitNormal:IsEqualTol(ply:GetWallrunDir(), 0.25) then return end
		if trout.Hit and trout.HitNormal:IsEqualTol(ply:GetEyeTrace().HitNormal, 0.1) then
			ply:SetWallrunDir(trout.HitNormal)
			ply.WallrunOrigVel = mv:GetVelocity()
			ply:SetWallrunElevated(false)
			mv:SetVelocity(vector_origin)
			ply.WallrunOrigVel.z = 0
			ply:SetWallrun(2)
			ply:SetWallrunTime(CurTime()+hwrtime)
			ply:SetWallrunSoundTime(CurTime() + 0.1)
			ParkourEvent("wallrunh", ply)
			
			if CLIENT and IsFirstTimePredicted() then
				tiltdir = -1
				hook.Add("CalcView", "WallrunningTilt", WallrunningTilt)
			elseif SERVER then
				net.Start("WallrunTilt")
				net.WriteBool(true)
				net.Send(ply)
			end
			return
		end
	end
	
	--Horizontal Left
	if (mv:KeyDown(IN_JUMP) and !ply:OnGround()) or mv:KeyPressed(IN_JUMP) then
		local tr = ply.WallrunTrace
		local trout = ply.WallrunTraceOut
		tr.start = ply:EyePos()
		tr.endpos = tr.start + eyeang:Right()*-30
		tr.filter = ply
		tr.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
		tr.output = trout
		util.TraceLine(tr)
		
		if trout.HitNormal:IsEqualTol(ply:GetWallrunDir(), 0.25) then return end
		if trout.Hit and trout.HitNormal:IsEqualTol(ply:GetEyeTrace().HitNormal, 0.1) then
			ply:SetWallrunDir(trout.HitNormal)
			ply.WallrunOrigVel = mv:GetVelocity()
			ply:SetWallrunElevated(false)
			mv:SetVelocity(vector_origin)
			ply.WallrunOrigVel.z = 0
			ply:SetWallrun(3)
			ply:SetWallrunTime(CurTime()+hwrtime)
			ply:SetWallrunSoundTime(CurTime() + 0.1)
			ParkourEvent("wallrunh", ply)
			
			if CLIENT and IsFirstTimePredicted() then
				tiltdir = 1
				hook.Add("CalcView", "WallrunningTilt", WallrunningTilt)
			elseif game.SinglePlayer() then
				net.Start("WallrunTilt")
				net.WriteBool(false)
				net.Send(ply)
			end
			return
		end
	end
end

local vecdir = Vector(1000,1000,1000)
hook.Add( "SetupMove", "Wallrunning", function( ply, mv, cmd )

	if ply:GetWallrun() == nil or !ply:Alive() then
		ply:SetWallrun(0)
	end
	
	if ply:GetWallrun() == 0 and mv:GetVelocity().z > -450 and !ply:OnGround() and mv:KeyDown(IN_FORWARD) and !ply:Crouching() and !mv:KeyDown(IN_DUCK) and ply:GetMoveType() != MOVETYPE_NOCLIP then
		WallrunningCheck(ply, mv, cmd)
	end
	
	if ply:GetWallrun() != 0 then
		WallrunningThink(ply, mv, cmd)
	end
	
	if ply:GetWallrun() == 0 and ply:OnGround() then
		ply:SetWallrunDir(vecdir)
	end

end)