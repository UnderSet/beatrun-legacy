if CLIENT then
local circle = Material("circlesmooth.png","nocull smooth")
hook.Add("HUDPaint", "grappleicon", function()
	local ply = LocalPlayer()
	if !ply:Alive() or (Course_Name != "" and ply:GetNW2Int("CPNum", 1) != -1) then return end
	if GetGlobalBool(GM_INFECTION) then
		return
	end
	if !ply.GrappleHUD_tr then
		ply.GrappleHUD_tr = {}
		ply.GrappleHUD_trout = {}
		ply.GrappleHUD_tr.output = ply.GrappleHUD_trout
		
		ply.GrappleHUD_tr.collisiongroup = COLLISION_GROUP_WEAPON
	end
	
	if ply:GetGrappling() then
		local w2s = ply:GetGrapplePos():ToScreen()
		surface.SetDrawColor(255,255,255)
		surface.SetMaterial(circle)
		surface.DrawTexturedRect(w2s.x-SScaleX(8*0.5), w2s.y-SScaleY(8*0.5), SScaleX(8), SScaleY(8))
		return
	end
	
	if ply:EyeAngles().x > -30 or ply:GetWallrun() != 0 then return end
	
	local tr = ply.GrappleHUD_tr
	local trout = ply.GrappleHUD_trout
	tr.start = ply:GetEyeTrace().HitPos + ply:GetAngles():Forward() * 2 + Vector(0,0,400)
	tr.endpos = tr.start - Vector(0,0,600)
	util.TraceLine(tr)
	local dist = trout.HitPos:DistToSqr(ply:GetPos())
	if !trout.HitSky and trout.HitPos.z > ply:GetPos().z and trout.HitNormal.z == 1 and trout.Fraction > 0 and (dist < 1750000 and dist > 200000) then
	local w2s = trout.HitPos:ToScreen()
	surface.SetDrawColor(255,255,255)
	surface.SetMaterial(circle)
	surface.DrawTexturedRect(w2s.x-SScaleX(8*0.5), w2s.y-SScaleY(8*0.5), SScaleX(8), SScaleY(8))
	end
end)
end

local zpunchstart = Angle(2,0,0)
hook.Add("SetupMove", "Grapple", function(ply, mv, cmd)
	if !ply:Alive() or Course_Name != "" and ply:GetNW2Int("CPNum", 1) != -1 then return end
	if GetGlobalBool(GM_INFECTION) then
		return
	end

	if !ply.Grapple_tr then
		ply.Grapple_tr = {}
		ply.Grapple_trout = {}
		ply.Grapple_tr.output = ply.Grapple_trout
		
		ply.Grapple_tr.collisiongroup = COLLISION_GROUP_WEAPON
	end
	
	if !ply:GetGrappling() and ply:GetWallrun() == 0 and cmd:GetViewAngles().x <= -30 then
		local tr = ply.Grapple_tr
		local trout = ply.Grapple_trout
		tr.start = ply:GetEyeTrace().HitPos + mv:GetAngles():Forward() * 2 + Vector(0,0,400)
		tr.endpos = tr.start - Vector(0,0,600)
		tr.filter = ply
		util.TraceLine(tr)
		local dist = trout.HitPos:DistToSqr(mv:GetOrigin())
		if !trout.HitSky and trout.HitPos.z > mv:GetOrigin().z and trout.HitNormal.z == 1 and trout.Fraction > 0 and (dist < 1750000 and dist > 200000) then
			if mv:KeyDown(IN_ATTACK) then
				ply:SetGrapplePos(trout.HitPos)
				ply:SetGrappling(true)
				ply:EmitSound("MirrorsEdge/Gadgets/ME_Magrope_Fire.wav", 40, 100 + math.random(-25,10))
				ply.ZiplineSound = CreateSound(ply, "MirrorsEdge/zipline_loop.wav")
				ply.ZiplineSound:PlayEx(0.5, 100)
				ply:ViewPunch(zpunchstart)
			end
		end
	end
	
	
	if ply:GetGrappling() then
		local gpos = ply:GetGrapplePos()
		local pos = mv:GetOrigin()
		local eyepos = mv:GetOrigin()
		eyepos.z = eyepos.z+64
		
		if !ply:Alive() or !mv:KeyDown(IN_ATTACK) or gpos.z < pos.z then
			ply:SetGrappling(false)
			if ply.ZiplineSound and ply.ZiplineSound.Stop then
				ply.ZiplineSound:Stop()
				ply.ZiplineSound = nil
				ply:EmitSound("MirrorsEdge/zipline_detach.wav", 40, 100 + math.random(-25,10))
			end
			return
		end
		
		-- local tr = ply.Grapple_tr
		-- local trout = ply.Grapple_trout
		-- tr.start = eyepos
		-- tr.endpos = gpos
		-- util.TraceLine(tr)
		-- if trout.Fraction < 0.5 then
			-- ply:SetGrappling(false)
			-- if ply.ZiplineSound and ply.ZiplineSound.Stop then
				-- ply.ZiplineSound:Stop()
				-- ply.ZiplineSound = nil
				-- ply:EmitSound("MirrorsEdge/zipline_detach.wav", 40, 100 + math.random(-25,10))
			-- end
			-- return
		-- end
		
		gpos.z = gpos.z - 60
		if ply:OnGround() then
			mv:SetButtons(mv:GetButtons()+IN_JUMP)
		end
		local vel = mv:GetVelocity()
		vel.z = math.max(vel.z, -350)
		cmd:ClearMovement()
		mv:SetSideSpeed(0)
		local newvel = vel + (gpos - pos):Angle():Forward() * (500 / math.max(vel:Length()/700, 0.1)) * FrameTime()

		mv:SetVelocity( newvel )
	elseif ply.ZiplineSound and ply.ZiplineSound.Stop then
		ply.ZiplineSound:Stop()
		ply.ZiplineSound = nil
		ply:EmitSound("MirrorsEdge/zipline_detach.wav", 40, 100 + math.random(-25,10))
	end

end)

local cablemat = Material("cable/cable2")
hook.Add("PostDrawTranslucentRenderables", "GrappleBeam", function()
	local ply = LocalPlayer()
	if ply:GetGrappling() then
		local pos = ply:GetPos()
		pos.z = pos.z + 32
		render.SetMaterial(cablemat)
		render.DrawBeam(pos, ply:GetGrapplePos(), 3, 0, 1)
	end
end)