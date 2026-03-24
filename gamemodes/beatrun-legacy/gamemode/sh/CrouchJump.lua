local usingrh
local punch = Angle(-7.5,0,0)
local punchland = Angle(10,0,5)

if SERVER then
	util.AddNetworkString("CrouchJumpSP")
elseif CLIENT and game.SinglePlayer() then
	net.Receive("CrouchJumpSP", function()
		if net.ReadBool() then
			local ply = LocalPlayer()
			ply.OrigEyeAng = ply:EyeAngles()
			if ply.OrigEyeAng.x > 30 then
				ply.OrigEyeAng.x = 30
				ply:SetEyeAngles(ply.OrigEyeAng)
			end
			VMLegs:PlayAnim("crouchjump")
			VMLegs.LegParent:ManipulateBonePosition(VMLegs.LegParent:LookupBone("ValveBiped.Bip01_Neck1"),Vector(0,0,-2500))
		else
			if IsValid(VMLegs.LegModel) then
				VMLegs:Remove()
			end
		end
	end)
end

hook.Add("SetupMove","CrouchJump",function(ply, mv, cmd)

if ply:Alive() and !ply:OnGround() and ply:GetVelocity().z > -800 and CurTime() > ply:GetCrouchJumpTime() and ply:GetWallrun() == 0 and mv:KeyPressed(IN_DUCK) then
	local activewep=ply:GetActiveWeapon()
	if IsValid(activewep) then usingrh=activewep:GetClass()=="runnerhands" end 
	if CLIENT then
		ply.OrigEyeAng = ply:EyeAngles()
		if ply.OrigEyeAng.x > 30 then
			ply.OrigEyeAng.x = 30
			ply:SetEyeAngles(ply.OrigEyeAng)
		end
		if IsFirstTimePredicted() then
			VMLegs:PlayAnim("crouchjump")
			VMLegs.LegParent:ManipulateBonePosition(VMLegs.LegParent:LookupBone("ValveBiped.Bip01_Neck1"),Vector(0,0,-2500))
		end
	end
	
	if game.SinglePlayer() then
		net.Start("CrouchJumpSP")
		net.WriteBool(true)
		net.Send(ply)
	end
	ParkourEvent("coil", ply)
	ply:SetCrouchJump(true)
	ply:SetCrouchJumpTime(CurTime()+1)
	ply:ViewPunch(punch)
	if usingrh then
		activewep:SendWeaponAnim(ACT_VM_HOLSTER)
	end
	
elseif (ply:OnGround() or CurTime() > ply:GetCrouchJumpTime() or !ply:Alive()) and ply:GetCrouchJump() then
	local activewep=ply:GetActiveWeapon()
	if IsValid(activewep) then usingrh=activewep:GetClass()=="runnerhands" end
	if game.SinglePlayer() then
		net.Start("CrouchJumpSP")
		net.WriteBool(false)
		net.Send(ply)
	end
	if CLIENT and IsValid(VMLegs.LegModel) then VMLegs:Remove() end
	ply:SetCrouchJump(false)
	if usingrh and IsValid(activewep) then
		activewep:SendWeaponAnim(ACT_VM_DRAW)
	end
	if ply:OnGround() then
		ply:ViewPunch(punchland)
	end
	ply:SetCrouchJumpTime(0)
end

end)


hook.Add("PostDrawOpaqueRenderables","CrouchJumpLegs",function()

local activewep=LocalPlayer():GetActiveWeapon()
if IsValid(activewep) then usingrh=activewep:GetClass()=="runnerhands" end
if LocalPlayer():GetCrouchJump() and IsValid(VMLegs.LegModel) and usingrh then
	cam.IgnoreZ(true)
	VMLegs.LegModel:DrawModel()
	cam.IgnoreZ(false)
end

end)

hook.Add("CreateMove","VManipCrouchJumpDuck",function(cmd)

local ply = LocalPlayer()
if ply:GetCrouchJump() and ply:GetMoveType()==MOVETYPE_WALK and !ply:OnGround() then cmd:SetButtons(IN_DUCK) end

end)

local lasteyeang = Angle()
hook.Add("InputMouseApply","CrouchJump_Mouse", function(cmd,x,y)
	if LocalPlayer():GetCrouchJump() then
		local ply = LocalPlayer()
		local nang = cmd:GetViewAngles()
		local oang = ply.OrigEyeAng
		local limitx = 30
		if (math.AngleDifference(nang.x, oang.x)) > limitx then
			cmd:SetViewAngles(lasteyeang)
			return true
		end
		lasteyeang = nang
	end
end)