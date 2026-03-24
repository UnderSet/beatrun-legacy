local chestvec = Vector(0,0,32)
local thoraxvec = Vector(0,0,48)
local neckvec = Vector(0,0,54)
local eyevec = Vector(0,0,64)
local aircheck = Vector(0,0,128)
local mantlevec = Vector(0,0,16)
local vault1vec = Vector(0,0,24)

local vpunch1 = Angle(1,0,-1)
local vpunch2 = Angle(-1,0,-5)
local vpunch3 = Angle(-1,0,-3)

//DT vars
local meta = FindMetaTable("Player")
function meta:GetMantle()
	return self:GetDTInt(13)
end
function meta:SetMantle(value)
	return self:SetDTInt(13, value)
end

function meta:GetMantleLerp()
	return self:GetDTFloat(13)
end
function meta:SetMantleLerp(value)
	return self:SetDTFloat(13, value)
end

function meta:GetMantleStartPos()
	return self:GetDTVector(13)
end
function meta:SetMantleStartPos(value)
	return self:SetDTVector(13, value)
end

function meta:GetMantleEndPos()
	return self:GetDTVector(14)
end
function meta:SetMantleEndPos(value)
	return self:SetDTVector(14, value)
end

local pkweps = { --these already have their own climbing
["parkourmod"] = true,
["m_sprinting"] = true
}

local function PlayVaultAnim(ply, legs)

	local activewep = ply:GetActiveWeapon()
	if IsValid(activewep) then
		if activewep:GetClass() == "runnerhands" then
			if activewep:GetSequence() == 17 then
				activewep:SendWeaponAnim(ACT_VM_DRAW)
			end
		end
	end

	if game.SinglePlayer() and SERVER then
		ply:SendLua('if VManip then VManip:PlayAnim("vault") end')
		local tr = util.QuickTrace(ply:EyePos(), Vector(0,0,-100), ply)
		if !tr.Hit then return end
		if legs == 1 then
			ply:SendLua('if VMLegs then VMLegs:Remove() VMLegs:PlayAnim("test") end')
		elseif legs == 2 then
			ply:SendLua('if VMLegs then VMLegs:Remove() VMLegs:PlayAnim("vaultlong") end')
		end
		return
	end
	if CLIENT and VManip then
		VManip:PlayAnim("vault")
		local tr = util.QuickTrace(ply:EyePos(), Vector(0,0,-100), ply)
		if !tr.Hit then return end
		if legs == 1 then
			VMLegs:Remove()
			VMLegs:PlayAnim("test")
		elseif legs == 2 then
			VMLegs:Remove()
			VMLegs:PlayAnim("vaultlong")
		end
	end
end

local function Vault1(ply, mv, ang, t, h)
	t.start = mv:GetOrigin() + eyevec + ang:Forward()* 25
	t.endpos = t.start - (neckvec)
	t.filter = ply
	t.mask = MASK_PLAYERSOLID
	t.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
	-- t.mins, t.maxs = mins, maxs
	
	t = util.TraceLine(t)
	if (t.Entity and t.Entity.IsNPC) and (t.Entity:IsPlayer()) then
		return false
	end
	
	if IsValid(t.Entity) and t.Entity:GetClass() == "br_swingbar"  then
		return false
	end
	
	if t.Hit and t.Fraction > 0.3 then
		local tsafety = {}
		tsafety.start = t.StartPos - ang:Forward() * 50
		tsafety.endpos = t.StartPos
		tsafety.filter = ply
		tsafety.mask = MASK_PLAYERSOLID
		tsafety.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
		tsafety = util.TraceLine(tsafety)
		
		if tsafety.Hit then return false end
		
		h.start = t.HitPos + mantlevec
		h.endpos = h.start
		h.filter = ply
		h.mask = MASK_PLAYERSOLID
		h.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
		h.mins, h.maxs = ply:GetCollisionBounds()
		local hulltr = util.TraceHull(h)
		if !hulltr.Hit then
			if t.HitNormal.x != 0 then t.HitPos.z = t.HitPos.z + 12 end
			ply:SetMantleStartPos(mv:GetOrigin())
			ply:SetMantleEndPos(t.HitPos + mantlevec)
			ply:SetMantleLerp(0)
			ply:SetMantle(1)
			PlayVaultAnim(ply)
			ply:ViewPunch(vpunch1)
			ply.MantleInitVel = mv:GetVelocity()
			ply.MantleMatType = t.MatType
			ParkourEvent("vault", ply)
			if game.SinglePlayer() then ply:PlayStepSound(1) end
			return true
		end
	end
	return false
end

local function Vault2(ply, mv, ang, t, h)
	local mins, maxs = ply:GetCollisionBounds()
	-- mins.x = mins.x * 0.25
	-- mins.y = mins.y * 0.25
	maxs.z = maxs.z * 0.5
	t.start = mv:GetOrigin() + chestvec + ang:Forward() * 35
	t.endpos = t.start
	t.filter = ply
	t.mask = MASK_PLAYERSOLID
	t.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
	t.mins, t.maxs = mins, maxs

	local vaultpos = t.endpos + ang:Forward() * 35
	t = util.TraceHull(t)
	if (t.Entity and t.Entity.IsNPC) and (t.Entity:IsNPC() or t.Entity:IsPlayer()) then
		return false
	end
	
	if IsValid(t.Entity) and t.Entity:GetClass() == "br_swingbar"  then
		return false
	end
	
	if t.Hit then
		local tsafety = {}
		tsafety.start = mv:GetOrigin() + eyevec
		tsafety.endpos = tsafety.start + ang:Forward() * 100
		tsafety.filter = ply
		tsafety.mask = MASK_PLAYERSOLID
		tsafety.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
		tsafety = util.TraceLine(tsafety)
		
		if tsafety.Hit then return false end
		
		local tsafety = {}
		tsafety.start = mv:GetOrigin() + eyevec + ang:Forward() * 100
		tsafety.endpos = tsafety.start - thoraxvec
		tsafety.filter = ply
		tsafety.mask = MASK_PLAYERSOLID
		tsafety = util.TraceLine(tsafety)
		
		if tsafety.Hit then return false end
		mins.z = mins.z * 1
		h.start = t.StartPos + chestvec
		h.endpos = h.start
		h.filter = ply
		h.mask = MASK_PLAYERSOLID
		h.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
		h.mins, h.maxs = mins, maxs
		local hulltr = util.TraceHull(h)
		local mins, maxs = ply:GetCollisionBounds()
		h.start = vaultpos
		h.endpos = h.start
		h.filter = ply
		h.mask = MASK_PLAYERSOLID
		h.mins, h.maxs = mins, maxs
		local hulltr2 = util.TraceHull(h)
		if !hulltr.Hit and !hulltr2.Hit then
			ply:SetMantleStartPos(mv:GetOrigin())
			ply:SetMantleEndPos(vaultpos)
			ply:SetMantleLerp(0)
			ply:SetMantle(2)
			PlayVaultAnim(ply, 1)
			ply:ViewPunch(vpunch2)
			ply.MantleInitVel = mv:GetVelocity()
			ply.MantleInitVel.z = 0
			ply.MantleMatType = t.MatType
			ParkourEvent("vault", ply)
			if game.SinglePlayer() or (CLIENT and IsFirstTimePredicted()) then
				timer.Simple(0.1, function() ply:EmitSound("Cloth.VaultSwish") ply:FaithVO("Faith.StrainSoft") end)
				ply:EmitSound("Handsteps.ConcreteHard")
			end
			-- if SERVER then ply:EmitSound("vmanip/goprone_0"..math.random(1,3)..".wav") end
			return true
		end
	end
	return false
end

local function Vault3(ply, mv, ang, t, h)
	local mins, maxs = ply:GetCollisionBounds()
	-- mins.x = mins.x * 0.25
	-- mins.y = mins.y * 0.25
	maxs.z = maxs.z * 0.5
	t.start = mv:GetOrigin() + chestvec + ang:Forward() * 35
	t.endpos = t.start
	t.filter = ply
	t.mask = MASK_PLAYERSOLID
	t.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
	t.mins, t.maxs = mins, maxs

	local vaultpos = t.endpos + ang:Forward() * 60
	t = util.TraceHull(t)
	if (t.Entity and t.Entity.IsNPC) and (t.Entity:IsNPC() or t.Entity:IsPlayer()) then
		return false
	end
	
	if IsValid(t.Entity) and t.Entity:GetClass() == "br_swingbar"  then
		return false
	end
	
	if t.Hit then
		local tsafety = {}
		tsafety.start = mv:GetOrigin() + eyevec
		tsafety.endpos = tsafety.start + ang:Forward() * 150
		tsafety.filter = ply
		tsafety.mask = MASK_PLAYERSOLID
		tsafety.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
		tsafety = util.TraceLine(tsafety)
		
		if tsafety.Hit then return false end
		
		local tsafety = {}
		tsafety.start = mv:GetOrigin() + eyevec + ang:Forward() * 150
		tsafety.endpos = tsafety.start - thoraxvec
		tsafety.filter = ply
		tsafety.mask = MASK_PLAYERSOLID
		tsafety.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
		tsafety = util.TraceLine(tsafety)
		
		if tsafety.Hit then return false end
		tsafety.start = mv:GetOrigin() + eyevec + ang:Forward() * 150
		tsafety.endpos = tsafety.start - aircheck
		tsafety.filter = ply
		tsafety.mask = MASK_PLAYERSOLID
		tsafety = util.TraceLine(tsafety)
		if !tsafety.Hit then return false end
		
		mins.z = mins.z * 1
		h.start = t.StartPos + chestvec
		h.endpos = h.start
		h.filter = ply
		h.mask = MASK_PLAYERSOLID
		h.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
		h.mins, h.maxs = mins, maxs
		local hulltr = util.TraceHull(h)
		local mins, maxs = ply:GetCollisionBounds()
		h.start = vaultpos
		h.endpos = h.start
		h.filter = ply
		h.mask = MASK_PLAYERSOLID
		h.mins, h.maxs = mins, maxs
		local hulltr2 = util.TraceHull(h)
		if !hulltr.Hit and !hulltr2.Hit then
			ply:SetMantleStartPos(mv:GetOrigin())
			ply:SetMantleEndPos(vaultpos)
			ply:SetMantleLerp(0)
			ply:SetMantle(2)
			PlayVaultAnim(ply, 2)
			ply:ViewPunch(vpunch3)
			ply.MantleInitVel = mv:GetVelocity()
			ply.MantleInitVel.z = 0
			ply.MantleMatType = t.MatType
			ParkourEvent("vault", ply)
			if game.SinglePlayer() or (CLIENT and IsFirstTimePredicted()) then
				timer.Simple(0.1, function() ply:EmitSound("Cloth.VaultSwish") ply:FaithVO("Faith.StrainSoft") end)
				ply:EmitSound("Handsteps.ConcreteHard")
			end
			-- if SERVER then ply:EmitSound("vmanip/goprone_0"..math.random(1,3)..".wav") end
			return true
		end
	end
	return false
end

hook.Add("SetupMove", "BeatrunVaulting", function(ply, mv, cmd)

	if ply.MantleDisabled or IsValid(ply:GetSwingbar()) or ply:GetClimbing() != 0 or (ply.InHWallrun or HWallrunning) or (ply.InVWallrun or VWallrunning) or (ply.InMantle or inmantle) then
		return
	end
	
	if !ply:Alive() then
		if ply:GetMantle() != 0 then 
			ply:SetMantle(0)
		end
		return
	end
	
	if ply:GetMantle() == 0 then
		local mvtype = ply:GetMoveType()
		if (ply:OnGround() or mv:GetVelocity().z < -600 or mvtype == MOVETYPE_NOCLIP or mvtype == MOVETYPE_LADDER) then
			return
		end
	end
	
	local activewep = ply:GetActiveWeapon()
	if IsValid(activewep) and activewep.GetClass then
		if pkweps[activewep:GetClass()] then
			return
		end
	end
	
	ply.mantletr = ply.mantletr or {}
	ply.mantlehull = ply.mantlehull or {}
	local t = ply.mantletr
	local h = ply.mantlehull
	
	if ply:GetMantle() == 0 and !ply:OnGround() and mv:KeyDown(IN_FORWARD) and !mv:KeyDown(IN_DUCK) and !ply:Crouching() then
		local ang = mv:GetAngles()
		ang.x = 0 ang.z = 0
		if !Vault2(ply, mv, ang, t, h) then
			if !Vault3(ply, mv, ang, t, h) then
				Vault1(ply, mv, ang, t, h)
			end
		end
	end
	
	if ply:GetMantle() != 0 then
		if mv:KeyDown(IN_JUMP) then
			mv:SetButtons(IN_JUMP)
			ply:ViewPunch(Angle(0.1,0,0))
		else
			mv:SetButtons(0)
		end
		mv:SetMaxClientSpeed(0)
		mv:SetSideSpeed(0) mv:SetUpSpeed(0) mv:SetForwardSpeed(0)
		mv:SetVelocity(vector_origin)
		ply:SetMoveType(MOVETYPE_NOCLIP)
		
		local mantletype = ply:GetMantle()
		local mlerp = ply:GetMantleLerp()
		local FT = FrameTime()
		local TargetTick = (1/FT)/66.66
		local mlerpend = ((mantletype == 1 and 0.8) or 1)
		local mlerprate = ((mantletype == 1 and 0.075) or 0.06)/TargetTick

		if mantletype == 1 then
			ply:SetMantleLerp(Lerp(mlerprate, mlerp, 1))
		else
			mlerprate = mlerprate * math.Clamp(ply.MantleInitVel:Length() / 300, 0.75, 2)
			ply:SetMantleLerp(math.Approach(mlerp, 1, mlerprate))
		end
		local mvec = LerpVector(ply:GetMantleLerp(), ply:GetMantleStartPos(), ply:GetMantleEndPos())
		mv:SetOrigin(mvec)
		h.start = mvec
		h.endpos = h.start
		h.filter = ply
		h.mask = MASK_PLAYERSOLID
		h.mins, h.maxs = ply:GetCollisionBounds()
		local hulltr = util.TraceHull(h)
		if mlerp >= mlerpend or (!hulltr.Hit and ((mantletype == 1 and mlerp > 0.3) or (mantletype == 2 and mlerp > 0.5))) then
			local ang = mv:GetAngles()
			ang.x = 0 ang.z = 0
			if ply:GetMantle() >= 2 then
				mv:SetVelocity(ang:Forward()*math.Clamp(ply.MantleInitVel:Length(), 200, 600)) --o: 300m
			end
			ply:SetMantle(0)
			ply:SetMoveType(MOVETYPE_WALK)
			if hulltr.Hit then
				mv:SetOrigin(ply:GetMantleEndPos())
			end
			if mv:KeyDown(IN_JUMP) and mlerp > 0.3 then
				ply:ViewPunch(Angle(-2.5,0,0))
				ParkourEvent("springboard", ply)
				if IsFirstTimePredicted() then
					if game.SinglePlayer() or CLIENT then ply:EmitSound("Cloth.VaultSwish") end
					if ply.MantleMatType == 77 or ply.MantleMatType == 86 then
						ply:EmitSound("Metal.Ringout")
					end
					hook.Run("PlayerFootstep", ply, mv:GetOrigin(), 1, "Footsteps.Concrete", 1)
				end
				local springboardvel = ang:Forward() * math.Clamp((ply.MantleInitVel or vector_origin):Length() * 0.75, 200, 300) + Vector(0,0,350)
				springboardvel:Mul(ply:GetOverdriveMult())
				springboardvel[3] = springboardvel[3] / ply:GetOverdriveMult()
				mv:SetVelocity(springboardvel) --250
				local activewep = ply:GetActiveWeapon()
				if IsValid(activewep) then
					if activewep:GetClass() == "runnerhands" then
						if mantletype == 1 then
							activewep:SendWeaponAnim(ACT_VM_RECOIL1)
						end
						if CLIENT then
							VManip:Remove()
							VMLegs.Speed = 3.5
						elseif game.SinglePlayer() then
							ply:SendLua("VManip.Lerp_Peak = CurTime() VMLegs.Speed = 3.5")
						end
					end
				end
			end
		end
	end

end)