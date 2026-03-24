local function Quickturn(ply, mv, cmd)
	if ply:GetWallrun() == 0 then return end
	if !ply:GetQuickturn() and mv:KeyPressed(IN_ATTACK2) and ((!mv:KeyDown(IN_MOVELEFT) and !mv:KeyDown(IN_MOVERIGHT)) or !ply:OnGround()) then
		ply:SetQuickturn(true)
		ply:SetQuickturnTime(CurTime())
		ply:SetQuickturnAng(cmd:GetViewAngles())
		if ply:GetWallrun() == 1 then
			ply:SetWallrun(4)
			ply:SetWallrunTime(CurTime()+0.75)
			if CLIENT and IsFirstTimePredicted() then
				RemoveBodyAnim()
			elseif game.SinglePlayer() then
				ply:SendLua("RemoveBodyAnim()") -- lol
			end

			local activewep=ply:GetActiveWeapon()
			if IsValid(activewep) then usingrh=activewep:GetClass()=="runnerhands" end 
			if usingrh then
				activewep:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
				activewep:SetBlockAnims(true)
			end
		end
	end
	
	if ply:GetQuickturn() then
		local wr = ply:GetWallrun()
		local target = ply:GetQuickturnAng()
		local dir = (wr == 2 and 1) or -1
		target.y = target.y + (((wr == 2 or wr == 3) and 90*dir) or 180)
		local lerptime = (CurTime() - ply:GetQuickturnTime())*8
		local lerp = Lerp(lerptime, ply:GetQuickturnAng().y, target.y)
		target.y = lerp
		if CLIENT or game.SinglePlayer() then ply:SetEyeAngles(target) end
		if lerptime >= 1 then
			ply:SetQuickturn(false)
		end
	end
end
hook.Add("SetupMove","Quickturn",Quickturn)
