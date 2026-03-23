local checktimer = 0
local errorc = Color(255, 25, 25)
local whitelist = {
["c_ladderanim"]=true
}
local function BodyAnimAntiStuck()
	if !IsValid(BodyAnim) then checktimer = 0 return end
	
	local ply = LocalPlayer()
	if !deleteonend and !whitelist[BodyAnimMDLString] and (!ply:GetSliding() and ply:GetWallrun() == 0) then
		RemoveBodyAnim()
		MsgC(errorc, "Removing potentially stuck anim!!\n")
	end
end
hook.Add("Think", "PacketLossFix", BodyAnimAntiStuck)