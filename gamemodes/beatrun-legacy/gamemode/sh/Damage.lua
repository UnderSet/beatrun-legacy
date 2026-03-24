hook.Add("ScalePlayerDamage", "MissedMe", function( ply, hitgroup, dmginfo )
	 if ply:GetVelocity():Length() > 400 then
		return true
	 end
end)