
AddCSLuaFile()
DEFINE_BASECLASS( "player_default" )

if ( CLIENT ) then

	CreateConVar( "cl_playercolor", "0.24 0.34 0.41", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The value is a Vector - so between 0-1 - not between 0-255" )
	CreateConVar( "cl_weaponcolor", "0.30 1.80 2.10", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The value is a Vector - so between 0-1 - not between 0-255" )
	CreateConVar( "cl_playerskin", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The skin to use, if the model has any" )
	CreateConVar( "cl_playerbodygroups", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The bodygroups to use, if the model has any" )

end

local PLAYER = {}

PLAYER.DuckSpeed			= 0.1		-- How fast to go from not ducking, to ducking
PLAYER.UnDuckSpeed			= 0.1		-- How fast to go from ducking, to not ducking

--
-- Creates a Taunt Camera
--
PLAYER.TauntCam = TauntCamera()

--
-- See gamemodes/base/player_class/player_default.lua for all overridable variables
--
PLAYER.WalkSpeed 			= 200
PLAYER.RunSpeed				= 400

--
-- Set up the network table accessors
--
function PLAYER:SetupDataTables()

	BaseClass.SetupDataTables( self )
	self.Player:NetworkVar( "Float", 0, "MEMoveLimit" )
	self.Player:NetworkVar( "Float", 1, "MESprintDelay" )
	self.Player:NetworkVar( "Float", 2, "MEAng" )
	
	self.Player:NetworkVar( "Int", 0, "Climbing" )
	self.Player:NetworkVar( "Float", 3, "ClimbingTime" )
	self.Player:NetworkVar( "Vector", 0, "ClimbingStart" )
	self.Player:NetworkVar( "Vector", 1, "ClimbingEnd" )
	
	self.Player:NetworkVar( "Int", 1, "Wallrun")
	self.Player:NetworkVar( "Float", 4, "WallrunTime")
	self.Player:NetworkVar( "Float", 5, "WallrunSoundTime")
	self.Player:NetworkVar( "Vector", 2, "WallrunDir")
	
	self.Player:NetworkVar( "Bool", 0, "Sliding" )
	self.Player:NetworkVar( "Float", 6, "SlidingTime" )
	self.Player:NetworkVar( "Float", 7, "SlidingDelay" )
	
	self.Player:NetworkVar( "Bool", 1, "StepRight" )
	self.Player:NetworkVar( "Float", 8, "StepRelease" )
	
	self.Player:NetworkVar( "Bool", 2, "Grappling" )
	self.Player:NetworkVar( "Vector", 3, "GrapplePos" )
	
	self.Player:NetworkVar( "Entity", 0, "Swingbar" )
	
	self.Player:NetworkVar( "Bool", 3, "CrouchJump" )
	self.Player:NetworkVar( "Float", 9, "CrouchJumpTime" )
	
	self.Player:NetworkVar( "Float", 9, "SafetyRollKeyTime" )
	self.Player:NetworkVar( "Float", 10, "SafetyRollTime" )
	self.Player:NetworkVar( "Angle", 0, "SafetyRollAng" )
	
	self.Player:NetworkVar( "Bool", 4, "Quickturn" )
	self.Player:NetworkVar( "Float", 10, "QuickturnTime" )
	self.Player:NetworkVar( "Angle", 1, "QuickturnAng" )
	
	self.Player:NetworkVar( "Bool", 5, "WallrunElevated" )
	

	--We have to store this info on the player as multiple people can use one swingbar
	self.Player:NetworkVar( "Float", 11, "SBOffset" )
	self.Player:NetworkVar( "Float", 12, "SBOffsetSpeed" )
	self.Player:NetworkVar( "Float", 13, "SBStartLerp" )
	self.Player:NetworkVar( "Float", 14, "SBDelay" )
	self.Player:NetworkVar( "Int", 2, "SBPeak" )
	self.Player:NetworkVar( "Bool",6, "SBDir" )
	self.Player:NetworkVar( "Entity",1, "SwingbarLast" )
	
	self.Player:NetworkVar( "Entity", 2, "Swingpipe" )
	self.Player:NetworkVar( "Entity", 3, "Rabbit" )
	self.Player:NetworkVar( "Int", 3, "RabbitSeat" )
	
	
	self.Player:NetworkVar( "Float", 15, "OverdriveCharge" )
	self.Player:NetworkVar( "Float", 16, "OverdriveMult" )

end


function PLAYER:Loadout()

	self.Player:RemoveAllAmmo()
	self.Player:Give( "runnerhands" )

	self.Player:SelectWeapon("runnerhands")
	self.Player:SetJumpPower(225)
	self.Player:SetCrouchedWalkSpeed( 0.5 )
	self.Player:SetFOV(self.Player:GetInfoNum("fov_desired", 120))
	self.Player:SetCanZoom(false)

end

hook.Add("PlayerSwitchWeapon", "ResetFOV", function(ply)
	ply:SetFOV(ply:GetInfoNum("fov_desired", 120))
end)

function PLAYER:SetModel()

	BaseClass.SetModel( self )

	local skin = self.Player:GetInfoNum( "cl_playerskin", 0 )
	self.Player:SetSkin( skin )

	local groups = self.Player:GetInfo( "cl_playerbodygroups" )
	if ( groups == nil ) then groups = "" end
	local groups = string.Explode( " ", groups )
	for k = 0, self.Player:GetNumBodyGroups() - 1 do
		self.Player:SetBodygroup( k, tonumber( groups[ k + 1 ] ) or 0 )
	end

end

--
-- Called when the player spawns
--
if SERVER then
	util.AddNetworkString("BeatrunSpawn")
end

function PLAYER:Spawn()

	BaseClass.Spawn( self )

	local ply = self.Player
	local col = ply:GetInfo( "cl_playercolor" )
	ply:SetPlayerColor( Vector( col ) )

	local col = Vector( ply:GetInfo( "cl_weaponcolor" ) )
	if ( col:Length() < 0.001 ) then
		col = Vector( 0.001, 0.001, 0.001 )
	end
	ply:SetWeaponColor( col )
	
	if Course_Name != "" and Course_StartPos != vector_origin then
		ply:SetPos(Course_StartPos)
		ply:SetEyeAngles(Angle(0,Course_StartAng,0))
		ply:SetLocalVelocity(vector_origin)
		timer.Simple(0.1, function() ply:SetLocalVelocity(vector_origin) ply:SetPos(Course_StartPos) end) --Failsafe
	end
	
	if !ply.InReplay then
		ply:SetNW2Float("CPNum", 1)
	end
	net.Start("BeatrunSpawn")
	net.WriteFloat(CurTime())
	net.WriteBool(ply.InReplay)
	net.Send(ply)
	
	ply.SpawnFreezeTime = CurTime() + 1.75
	
	ply:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	ply:SetAvoidPlayers(false)
	ply:SetCustomCollisionCheck(true)
	
	ply:SetLaggedMovementValue( 0 ) --otherwise they drift off
	timer.Simple(0.1, function() ply:SetLaggedMovementValue( 1 ) end)
	if ply.SlideLoopSound and ply.SlideLoopSound.Stop then
		ply.SlideLoopSound:Stop()
	end
	
	ply:SetOverdriveCharge(0)
	ply:SetOverdriveMult(1)

end

hook.Add("SetupMove", "SpawnFreeze", function(ply, mv, cmd)
	if ply.SpawnFreezeTime and Course_Name != "" and Course_StartPos != vector_origin then
		if Course_StartPos and ply.SpawnFreezeTime > CurTime() then
			mv:SetOrigin(Course_StartPos)
		end
	end
end)

hook.Add( "ShouldCollide", "NoPlayerCollisions", function( ent1, ent2 )

    if ( ent1:IsPlayer() and (ent2:IsPlayer() or ent2.NoPlayerCollisions) ) then
		-- if ent2.CollisionFunc then
			-- return ent2:CollisionFunc(ent1)
		-- else
			return false
		-- end
	end

end )

hook.Add( "PhysgunPickup", "AllowPlayerPickup", function( ply, ent )
	if ( ply:IsSuperAdmin() and ent:IsPlayer() ) then
		return true
	end
end )

function PLAYER:ShouldDrawLocal()

	if ( self.TauntCam:ShouldDrawLocalPlayer( self.Player, self.Player:IsPlayingTaunt() ) ) then return true end

end

function PLAYER:CreateMove( cmd )

	if ( self.TauntCam:CreateMove( cmd, self.Player, self.Player:IsPlayingTaunt() ) ) then return true end

end

function PLAYER:CalcView( view )

	if ( self.TauntCam:CalcView( view, self.Player, self.Player:IsPlayingTaunt() ) ) then return true end

end

function PLAYER:GetHandsModel()

	local cl_playermodel = self.Player:GetInfo( "cl_playermodel" )
	return player_manager.TranslatePlayerHands( cl_playermodel )

end

function PLAYER:StartMove( move )

end

function PLAYER:FinishMove( move )

end

hook.Add("FinishMove", "BeatrunRHVelocity", function(ply, mv)
	local activewep = ply:GetActiveWeapon()
	if IsValid(activewep) and activewep:GetClass()=="runnerhands" and activewep.SetOwnerVelocity then
		activewep:SetOwnerVelocity(math.Round(mv:GetVelocity():Length()))
	end
end)

local meta = FindMetaTable("Player")
function meta:ResetParkourState()
	self:SetSliding(false)
	self:SetCrouchJump(false)
	self:SetQuickturn(false)
	self:SetGrappling(false)
	self:SetSwingbar(nil)
	self:SetMantle(0)
	self:SetWallrun(0)
	self:SetMEMoveLimit(0)
	self:SetMESprintDelay(0)
	self:SetMEAng(0)
	self:SetClimbing(0)
	self:SetClimbingTime(0)
	self:SetWallrunTime(0)
	self:SetWallrunSoundTime(0)
	self:SetSlidingTime(0)
	self:SetSlidingDelay(0)
	self:SetCrouchJumpTime(0)
	self:SetSafetyRollKeyTime(0)
	self:SetSafetyRollTime(0)
	self:SetQuickturnTime(0)
end

function meta:ResetParkourTimes()
	self:SetClimbingTime(0)
	self:SetWallrunTime(0)
	self:SetWallrunSoundTime(0)
	self:SetSlidingTime(0)
	self:SetSlidingDelay(0)
	self:SetCrouchJumpTime(0)
	self:SetSafetyRollKeyTime(0)
	self:SetSafetyRollTime(0)
	self:SetQuickturnTime(0)
end

function meta:InOverdrive()
	return self:GetOverdriveMult() != 1
end

hook.Add("PlayerSpawn", "ResetStateTransition", function(ply, transition)
	timer.Simple(0, function()
		if transition and IsValid(ply) then
			ply:ResetParkourTimes()
			ply:SetJumpPower(225)
			ply:SetFOV(ply:GetInfoNum("fov_desired", 110))
			ply:SetCanZoom(false)
			ply.ClimbingTrace = nil
		end
	end)
end)

player_manager.RegisterClass( "player_beatrun", PLAYER, "player_default" )