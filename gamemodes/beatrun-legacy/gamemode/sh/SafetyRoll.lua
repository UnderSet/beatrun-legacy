if game.SinglePlayer() and SERVER then util.AddNetworkString("RollAnimSP") end
local landang = Angle(0,0,0)
local function SafetyRollThink(ply, mv, cmd)
	if !ply:OnGround() and mv:KeyPressed(IN_SPEED) then
		ply:SetSafetyRollKeyTime(CurTime()+0.5)
	end
	
	if ply:GetSafetyRollTime() > CurTime() then
		local ang = ply:GetSafetyRollAng()
		mv:SetSideSpeed(0)
		mv:SetForwardSpeed(0)
		if ang != landang then
			local vel = mv:GetVelocity()
			vel.x = 0
			vel.y = 0
			mv:SetVelocity(ply:GetSafetyRollAng():Forward()*250 + vel)
		else
			mv:SetVelocity(vector_origin)
		end
	end
end
hook.Add("SetupMove", "SafetyRoll", SafetyRollThink)

local roll = {
["AnimString"] = "rollanim",
["animmodelstring"] = "mirroranim",
["lockang"] = true,
["followplayer"] = true,
["deleteonend"] = true,
["showweapon"]=true,
["ignorez"] = true,
}
net.Receive("RollAnimSP", function()
	if net.ReadBool() then
		roll.AnimString = "land"
	else
		roll.AnimString = "rollanim"
	end
	StartBodyAnim(roll)
end)

hook.Add("OnPlayerHitGround", "SafetyRoll", function(ply, water, floater, speed)
	if speed >= 350 and speed < 750 and ply:GetSafetyRollKeyTime() > CurTime() and !ply:Crouching() then
		ParkourEvent("roll", ply)
		local ang = ply:EyeAngles()
		local land = ply:GetVelocity()
		ang.x = 0 ang.z = 0
		land.z = 0
		if land:Length() < 200 then
			land = true
			ply:SetSafetyRollAng(landang)
			ply:SetSafetyRollTime(CurTime()+0.5)
			roll.AnimString = "land"
			roll.usefullbody = true
		else
			land = false
			ply:SetSafetyRollAng(ang)
			ply:SetSafetyRollTime(CurTime()+1.1)
			roll.AnimString = "rollanim"
			roll.usefullbody = false
		end
		if SERVER and !land then
			ply:EmitSound("me_faith_cloth_roll_cloth.wav")
			ply:EmitSound("me_faith_cloth_roll_land.wav")
			ply:EmitSound("me_body_roll.wav")
		end
		
		if CLIENT and IsFirstTimePredicted() then
			StartBodyAnim(roll)
		elseif game.SinglePlayer() then
			net.Start("RollAnimSP")
			net.WriteBool(land)
			net.Send(ply)
		end
	end
end)


if SERVER then
	hook.Add("GetFallDamage", "SafetyRoll", function(ply, speed)
		if speed >= 750 then
			if speed < 750 and ply:GetSafetyRollKeyTime() > CurTime() and !ply:GetCrouchJump() and !ply:Crouching() then
				return 0
			else
				return 1000
			end
		else
			return 0
		end
	end)
end