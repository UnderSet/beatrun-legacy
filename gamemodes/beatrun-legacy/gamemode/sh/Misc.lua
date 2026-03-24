if SERVER then
	local meta = FindMetaTable("Player")
	util.AddNetworkString("SPParkourEvent")
	local spawn = {
	"PlayerGiveSWEP",
	"PlayerSpawnEffect",
	"PlayerSpawnNPC",
	"PlayerSpawnObject",
	"PlayerSpawnProp",
	"PlayerSpawnRagdoll",
	"PlayerSpawnSENT",
	"PlayerSpawnSWEP",
	"PlayerSpawnVehicle",
	}
	local function BlockSpawn(ply)
		if !ply:IsSuperAdmin() then
			return false
		end
	end
	for k,v in ipairs(spawn) do
		hook.Add(v, "BlockSpawn", BlockSpawn)
	end
	
	hook.Add("IsSpawnpointSuitable", "NoSpawnFrag", function(ply)
		return true
	end)
	
	hook.Add( "AllowPlayerPickup", "AllowAdminsPickUp", function( ply, ent )
		local sa = ply:IsSuperAdmin()
		if !sa then
			return false
		end
	end )
	
	function meta:GTAB(minutes)
		local ID = self:SteamID64()
		for k,v in pairs(player.GetAll()) do
			v:EmitSound("gtab.mp3",0,100,1)
		end
		timer.Simple(7.5, function()
			if IsValid(self) and self:SteamID64() == ID then
				self:Ban(minutes, "GTAB")
				for k,v in pairs(player.GetAll()) do
					v:EmitSound("vinethud.mp3",0,100,1)
				end
			end
		end)
	end
end
if CLIENT then
	CreateClientConVar("Beatrun_FOV", 110, true, true, "'Woah how are you moving this fast' and other hilarious jokes", 70, 140)
end
hook.Add( "PlayerSwitchFlashlight", "BlockFlashLight", function( ply, enabled )
	return false
end )

hook.Add( "PlayerNoClip", "BlockNoClip", function( ply, enabled )
	if enabled and Course_Name != "" then
		if ply:GetNW2Int("CPNum", 1) != -1  then
			ply:SetNW2Int("CPNum", -1)
			if CLIENT then
				notification.AddLegacy( "Noclip Enabled: Respawn to run the course", NOTIFY_ERROR, 2 )
			elseif SERVER and game.SinglePlayer() then
				ply:SendLua('notification.AddLegacy( "Noclip Enabled: Respawn to run the course", NOTIFY_ERROR, 2 )')
			end
		end
	end
	
	if enabled and GetGlobalBool(GM_INFECTION) then
		return false
	end
end )

function ParkourEvent(event, ply)
	if IsFirstTimePredicted() then
		hook.Run("OnParkour", event, ply or (CLIENT and LocalPlayer()))
		if game.SinglePlayer() then
			net.Start("SPParkourEvent")
			net.WriteString(event)
			net.Broadcast()
		end
	end
end

hook.Add("CanProperty", "BlockProperty", function(ply)
	if !ply:IsSuperAdmin() then return false end
end)

hook.Add("CanDrive", "BlockDrive", function(ply)
	if !ply:IsSuperAdmin() then return false end
end)

if CLIENT and game.SinglePlayer() then
	net.Receive("SPParkourEvent", function()
		local event = net.ReadString()
		hook.Run("OnParkour", event, LocalPlayer())
	end)
end

if SERVER then
hook.Add("OnEntityCreated", "RemoveMirrors", function(ent)
	if IsValid(ent) and ent:GetClass()=="func_reflective_glass" then
		SafeRemoveEntityDelayed(ent,0.1)
	end
end)
end