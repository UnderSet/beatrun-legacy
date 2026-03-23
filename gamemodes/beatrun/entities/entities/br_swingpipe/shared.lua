ENT.Type 				= "anim"
ENT.Base 				= "base_entity"
ENT.PrintName 			= "Swingbar"
ENT.Author 				= ""
ENT.Information 		= ""

ENT.Spawnable 			= true

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.Category			= "Beatrun"

AddCSLuaFile()

ENT.Model = "models/parkoursource/pipe_standard.mdl"

function ENT:SetupDataTables()
end

local spawntr = {}
local spawntrout = {}
function ENT:Initialize()
	self:DrawShadow(false)
    self:SetModel(self.Model)
    self:SetMoveType(MOVETYPE_NONE)
	if SERVER then self:PhysicsInit(SOLID_VPHYSICS) end
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	
	-- local mins, maxs = self:GetCollisionBounds()*4
	-- spawntr.start = self:GetPos()
	-- spawntr.endpos = spawntr.start
	-- spawntr.filter = self
	-- spawntr.output = spawntrout
	-- spawntr.mins, spawntr.maxs = mins, maxs
	-- util.TraceHull(spawntr)
	
	-- if spawntrout.Hit then
		-- local ang = spawntrout.HitNormal:Angle()
		-- ang.x = 0
		-- self:SetAngles(ang)
	-- end
	
end


function ENT:OnRemove()

end


function ENT:Think()
end

local matrix
local vecscale
function ENT:Draw()
	self:DrawModel()
end