local cvarwindsound
local minimalvm
if CLIENT then
	minimalvm = CreateClientConVar("Beatrun_MinimalVM", 1, true, true, "Lowers the running viewmodel", 0, 1)
	cvarwindsound = CreateClientConVar("Beatrun_Wind", 1, true, false, "Wind noises")
	SWEP.PrintName        = "Unarmed"			
	SWEP.Slot		= 0
	SWEP.SlotPos		= 1
	SWEP.DrawAmmo		= false
	SWEP.DrawCrosshair	= false
	--Blind players reload key isn't registered serverside so heres a bandaid fix
	hook.Add("KeyPress", "RespawnRequest", function(ply, key)
		if !blinded then return end
		local use = ply:KeyDown(IN_USE)
		if key == IN_RELOAD then
		print(use)
			net.Start("RespawnRequest")
			net.WriteBool(use)
			net.SendToServer()
			if use then
				-- ToggleBlindness(false)
			end
		end
	end)
else
	util.AddNetworkString("RespawnRequest")
	net.Receive("RespawnRequest", function(len, ply)
		if ply:KeyDown(IN_RELOAD) then return end
		if game.SinglePlayer() and net.ReadBool() and blinded then
			RunConsoleCommand("toggleblindness")
		end
		
		local activewep = ply:GetActiveWeapon()
		if IsValid(activewep) and activewep:GetClass() == "runnerhands" then
			activewep:Reload(true)
		else
			ply:Spawn()
		end
	end)
end

SWEP.Author			= ""
SWEP.Contact			= ""
SWEP.Purpose			= ""
SWEP.Instructions		= ""

SWEP.BounceWeaponIcon = false
SWEP.DrawWeaponInfoBox = false

SWEP.HoldType = "fist"
 
SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false
 
SWEP.UseHands = true 
 
SWEP.ViewModel			= "models/runnerhands.mdl"
SWEP.WorldModel		= ""

SWEP.ViewModelFOV=75 --65 75

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo		= "none"
 
SWEP.Secondary.ClipSize	= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		= "none"

SWEP.wepvelocity=0


SWEP.lastpunch=1 --1 right 2 left 3 both
SWEP.lastanimenum=0
SWEP.spamcount=0
SWEP.spamlast=0
SWEP.punchanims = {ACT_DOD_PRIMARYATTACK_PRONE, ACT_DOD_SECONDARYATTACK_PRONE, ACT_DOD_PRIMARYATTACK_KNIFE}
SWEP.punchangles = {Angle(2,1,-2), Angle(2,-1,2), Angle(2.5,0,0)}
SWEP.punchdelays = {0.165, 0.175, 0.5}
SWEP.lastpunchtimer=0
SWEP.punching=false
SWEP.doublepunch=false

function SWEP:SetupDataTables()
	self:NetworkVar( "Bool", 0, "SideStep" )
	self:NetworkVar( "Bool", 1, "BlockAnims" )
	self:NetworkVar( "Bool", 2, "WasOnGround" )
	self:NetworkVar( "Float", 0, "OwnerVelocity" )
	self:NetworkVar( "Float", 1, "WeaponVelocity" )
	self:NetworkVar( "Int", 0, "Punch" )
	self:NetworkVar( "Float", 2, "PunchReset" )
end

local runseq = {
[6] = true,
[7] = true
}
local oddseq = {
[8] = true,
[9] = true,
[10] = true,
[19] = true,
}
function SWEP:GetViewModelPosition( pos, ang )
	if minimalvm:GetBool() then
		if !self.posz then self.posz = pos.z end
		local seq = self:GetSequence()
		
		if runseq[seq] then
			self.posz = Lerp(10*FrameTime(), self.posz, -2)
		else
			self.posz = Lerp(10*FrameTime(), self.posz, 0)
		end
		pos.z=pos.z + self.posz
	end
	if oddseq[self:GetSequence()] then return pos, ang end
	
	self.BobScale = 0
	ang.x=math.Clamp(ang.x,-10,89)

	return pos, ang
end

function SWEP:Deploy()
	self:SetHoldType( "normal" )
	self:SendWeaponAnim(ACT_VM_DRAW)
	self.RespawnDelay = 0
	self:SetWasOnGround(false)
	self:SetBlockAnims(false)
	
	self:SetPunch(1)
	-- RunConsoleCommand("fov_desired", 100)
end

function SWEP:Initialize()
	self.RunWind1 = CreateSound(self, "clotheswind.wav")
	self.RunWind2 = CreateSound(self, "runwind.wav")
	self.RunWindVolume = 0
	self:SendWeaponAnim(ACT_VM_DRAW)
	self.RespawnDelay = 0
	self:SetWasOnGround(false)
	self:SetBlockAnims(false)
end

function SWEP:Holster()
	return true
end
 
local jumpseq = {
ACT_VM_HAULBACK,
ACT_VM_SWINGHARD
}
local jumptr, jumptrout = {}, {}
local jumpvec = Vector(0,0,-50)
local fallang = Angle()
local infall
local fallct = 0
function SWEP:Think()

local ply=self.Owner
local activewep=self
local viewmodel=ply:GetViewModel()

if !IsValid(viewmodel) then return end

if self:GetHoldType() == "fist" and CurTime() > self:GetPunchReset() then
	self:SetHoldType("normal")
end

if self:GetBlockAnims() then ply:GetViewModel():SetPlaybackRate(1) return end
local curseq=activewep:GetSequence()
local onground=ply:OnGround()
local vel = ply:GetVelocity()
vel.z = 0
local ismoving = vel:Length()>100 and !ply:KeyDown(IN_BACK) and ply:IsSprinting() and !ply:Crouching() and !ply:KeyDown(IN_DUCK)
local injump = curseq==13 or curseq == 14 or curseq == 17 or curseq == -1 or curseq == 1
infall = curseq==19
self:SetSideStep(curseq==15 or curseq==16)
local insidestep = self:GetSideStep()
local spvel = ply:GetVelocity()
local ang = ply:EyeAngles()
if spvel.z < -800 and ply:GetMoveType() != MOVETYPE_NOCLIP then
	if !infall then
		self:SendWeaponAnim(ACT_RUN_ON_FIRE)
	end
	if CLIENT and fallct != CurTime() then
		local vel = math.min(math.abs(spvel.z)/2500, 1)
		local mult = 20
		fallang:SetUnpacked(2*vel*FrameTime()*mult, 1.25*vel*FrameTime()*mult, 1.5*vel*FrameTime()*mult)
		fallang:Add(ang)
		fallct = CurTime()
	end
	return
elseif infall then
	activewep:SendWeaponAnim(ACT_VM_DRAW)
	ang.z = 0
	ply:SetEyeAngles(ang)
end
spvel.z = 0
local velocity = self:GetOwnerVelocity()
self.punching = curseq==8 or curseq==9 or curseq==10 or curseq==11
if ismoving and ply:KeyPressed(IN_JUMP) and self:GetWasOnGround() then
	ply:ViewPunch(Angle(-2,0,0))
	local eyeang = ply:EyeAngles()
	eyeang.x = 0
	
	
	if SERVER and insidestep and viewmodel:GetCycle() <= 0.1 then
		ply:EmitSound("quakejump.mp3", 100, 100, 0.2)
	end
	
	if !util.QuickTrace(ply:GetPos()+eyeang:Forward()*200, Vector(0,0,-100), ply).Hit then
		activewep:SendWeaponAnim(jumpseq[1])
	else
		activewep:SendWeaponAnim(jumpseq[2])
	end
	ParkourEvent("jump",ply)
	return
	
end

if ply:GetSliding() or ply:GetSlidingDelay()-0.15 > CurTime() then
	activewep:SendWeaponAnim(ACT_VM_DRAW)
	return
end

if (self.punching) and viewmodel:GetCycle()>=1 then
	activewep:SendWeaponAnim(ACT_VM_DRAW)
end

if injump and (viewmodel:GetCycle()>=1 or (ply:GetMantle() != 0 and ply:KeyDown(IN_JUMP)) or ply:GetWallrun() > 1) then
	activewep:SendWeaponAnim(ACT_VM_DRAW)
end

self:SetWeaponVelocity(Lerp(5*FrameTime(),self:GetWeaponVelocity(),velocity))
if !ismoving then
	self:SetWeaponVelocity(velocity)
end
if !self.punching and !insidestep then
	if onground and ismoving and curseq!=6 and velocity<=350 then
		activewep:SendWeaponAnim(ACT_RUN)
	elseif onground and ismoving and curseq!=7 and velocity>350 then
		local cycle = activewep:GetCycle()
		activewep:SendWeaponAnim(ACT_RUN_PROTECTED)
		activewep:SetCycle(cycle)
	elseif (curseq==6 or curseq==7) and (velocity<50 or !ismoving or !onground) and curseq!=13 then
		activewep:SendWeaponAnim(ACT_VM_DRAW)
	end
end

curseq = activewep:GetSequence()
if (curseq==6 or curseq==7) and ismoving then
	local rate = (curseq==7 and 1.2) or 0.75
	if rate != ply:GetViewModel():GetPlaybackRate() then
		ply:GetViewModel():SetPlaybackRate(rate)
	end
else
	ply:GetViewModel():SetPlaybackRate(1)
end

--game decided to just ignore changevolume so goodbye (for now)
-- if CLIENT then
	-- if !IsValid(self.RunWind1) then
		-- self.RunWind1 = CreateSound(self, "clotheswind.wav")
		-- self.RunWind2 = CreateSound(self, "runwind.wav")
	-- end
	
	-- if velocity>350 and cvarwindsound:GetBool() then
		-- activewep.RunWind1:Play()
		-- activewep.RunWind2:Play()
		
		-- self.RunWindVolume = math.Clamp(self.RunWindVolume + (0.5*FrameTime()), 0, 1)
		-- activewep.RunWind1:ChangeVolume(activewep.RunWindVolume)
		-- activewep.RunWind2:ChangeVolume(activewep.RunWindVolume)
	-- else
		-- self.RunWindVolume = math.Clamp(self.RunWindVolume - (2.5*FrameTime()), 0, 1)
		-- activewep.RunWind1:ChangeVolume(activewep.RunWindVolume)
		-- activewep.RunWind2:ChangeVolume(activewep.RunWindVolume)
	-- end
-- end

-- if blinded then
	-- activewep.RunWind1:ChangeVolume(0)
	-- activewep.RunWind2:ChangeVolume(0)
-- end

if insidestep and viewmodel:GetCycle()>=1 then
	local mult = (ply:InOverdrive() and 1.25) or 1
	activewep:SendWeaponAnim(ACT_VM_DRAW)
	ply:SetMEMoveLimit(350*mult)
	ply:SetMESprintDelay(CurTime())
elseif insidestep then
	local mult = (ply:InOverdrive() and 1.25) or 1
	ply:SetMEMoveLimit(350*mult)
	ply:SetMESprintDelay(CurTime())
end
self:SetWasOnGround(ply:OnGround())

end

local function FallView()

end

if CLIENT then
local didfallang = false
local mouseang = Angle()
hook.Add("InputMouseApply", "FallView", function(cmd, x, y, ang)
	local ply = LocalPlayer()
	if infall and ply:Alive() and ply:GetMoveType()!=MOVETYPE_NOCLIP then
		mouseang.x, mouseang.y = y*0.01, x*-0.01
		fallang:Add(mouseang)
		cmd:SetViewAngles(fallang)
		didfallang = true
		util.ScreenShake( vector_origin, 5*(math.abs(ply:GetVelocity().z)/1000), 5, 0.05, 5000 )
		return true
	elseif didfallang then
		fallang.z = 0
		fallang.x = math.Clamp(fallang.x, -89, 89)
		if ply:Alive() then cmd:SetViewAngles(fallang) end
		didfallang = false
	end
end)
end

function SWEP:Holster()
	if self.RunWind1 then
		self.RunWind1:Stop()
		self.RunWind2:Stop()
	end
	return true
end

function SWEP:OnRemove()
	if self.RunWind1 then
		self.RunWind1:Stop()
		self.RunWind2:Stop()
	end
end

function SWEP:Reload(noblindcheck)
	if !TUTORIALMODE and CurTime() > self.RespawnDelay and !IsValid(self.Owner:GetSwingbar()) and !self.Owner.BuildMode then
		self.Owner:Spawn()
		if self.Owner:KeyDown(IN_USE) then
			if !noblindcheck and game.SinglePlayer() then
				RunConsoleCommand("toggleblindness")
			elseif CLIENT then
				ToggleBlindness(!blinded)
			end
		end
		self.RespawnDelay = CurTime() + 0.5
	end
end

local tr = {}
local tr_result = {}
function SWEP:PrimaryAttack()
	local ply = self.Owner
	
	if ply:KeyDown(IN_USE) and game.SinglePlayer() then
		local mult = (ply:InOverdrive() and 1) or 1.25
		local fovmult = (mult == 1 and 1) or 1.1
		ply:SetMEMoveLimit(ply:GetMEMoveLimit()*0.75)
		ply:SetOverdriveMult(mult)
		ply:SetFOV(ply:GetInfoNum("fov_desired", 120)*fovmult, 0.125)
		return
	end
	
	if ply:GetSliding() or ply:GetGrappling() or ply:GetWallrun() != 0 then
		return
	end
	
	
	local curseq = self:GetSequence()
	local infall = curseq==19
	if infall then return end
	
	if CurTime() > self:GetPunchReset() then
		self:SetPunch(1)
	end
	local punch = self:GetPunch()
	self:SendWeaponAnim(self.punchanims[punch])
	ply:ViewPunch(self.punchangles[punch])
	self:SetNextPrimaryFire(CurTime()+self.punchdelays[punch])
	self:SetPunchReset(CurTime()+0.5)
	
	tr.start = ply:GetShootPos()
	tr.endpos = ply:GetShootPos() + ply:GetAimVector() * 50
	tr.filter = ply
	tr.mins =  Vector( -8 , -8 , -8 )
	tr.maxs =  Vector( 8 , 8 , 8 )
	tr.output = tr_result
	
	if ply:IsPlayer() then
		ply:LagCompensation( true )
		self:SetHoldType( "fist" )
		ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST, true)
	end
	
	util.TraceHull( tr )
	self:EmitSound("mirrorsedge/Melee/armswoosh"..math.random(1, 6)..".wav")
	
	if ply:IsPlayer() then
		ply:LagCompensation( false )
	end
	
	if tr_result.Hit then
		self:EmitSound("mirrorsedge/Melee/fist"..math.random(1, 5)..".wav")
		local ent = tr_result.Entity
		if SERVER and IsValid(ent) then
			if !ply:IsPlayer() or (Course_Name == "" and !GetGlobalBool(GM_INFECTION)) then
				local d = DamageInfo()
				d:SetDamage( (punch != 3 and 10) or 20 )
				d:SetAttacker( ply )
				d:SetInflictor( self )
				d:SetDamageType( DMG_CLUB )
				d:SetDamagePosition(tr.start)
				d:SetDamageForce(ply:EyeAngles():Forward()*7000)
			
				ent:TakeDamageInfo( d )
				if ent:IsNPC() then
					ent:SetActivity(ACT_FLINCH_HEAD)
				end
			end
		end
		if game.SinglePlayer() or (CLIENT and IsFirstTimePredicted()) then
			util.ScreenShake( Vector(0, 0, 0), 2.5, 10, 0.25, 0 )
		end
	end

	self:SetPunch(punch+1)
	if punch+1 > 3 then
		self:SetPunch(1)
	end
end
 

function SWEP:SecondaryAttack()

end