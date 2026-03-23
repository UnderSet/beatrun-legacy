local ClimbingTimes = {
    [1] = 0.65090908765793,
    [2] = 0.46090908765793
}

local climb1 = {
    ["AnimString"] = "climb1",
    ["animmodelstring"] = "climbanim",
    ["lockang"] = false,
    ["followplayer"] = false,
    ["allowmove"] = true,
    ["ignorez"] = true,
    ["smoothend"] = true
}

local climbstrings = {"climb1", "climb2"}
local BodyAnimClimbPos
if SERVER then util.AddNetworkString("BodyAnimClimb") end
if CLIENT then
    net.Receive("BodyAnimClimb", function()
        RemoveBodyAnim()
        local ply = LocalPlayer()
        climb1.AnimString = climbstrings[ply:GetClimbing()]
        ply.ClimbingStartPosCache = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
        ply.ClimbingStartSmooth = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
        ply.ClimbingStartSmoothLerp = 0
        hook.Add("Think", "BodyAnimClimbPos", BodyAnimClimbPos)
        StartBodyAnim(climb1)
        BodyAnim:SetPos(ply.ClimbingStartSmooth)
        BodyAnimSpeed = ply:GetOverdriveMult()
    end)

    BodyAnimClimbPos = function()
        local ply = LocalPlayer()
        ply.ClimbingStartSmoothLerp = math.Clamp(ply.ClimbingStartSmoothLerp + (RealFrameTime() * 10), 0, 1)
        if IsValid(BodyAnim) then
            local poslerp = LerpVector(ply.ClimbingStartSmoothLerp, ply.ClimbingStartSmooth, ply.ClimbingStartPosCache)
            BodyAnim:SetPos(poslerp)
        end

        if ply.ClimbingStartSmoothLerp >= 1 or not IsValid(BodyAnim) then hook.Remove("Think", "BodyAnimClimbPos") end
    end
end

local function ClimbingEnd(ply, mv, cmd)
    mv:SetOrigin(ply:GetClimbingEnd())
    ply:SetClimbing(0)
    ply:SetMoveType(MOVETYPE_WALK)
    local tr = {}
    tr.filter = ply
    tr.mins, tr.maxs = ply:GetHull()
    tr.start = mv:GetOrigin()
    tr.endpos = tr.start
    local trout = util.TraceHull(tr)
    if trout.Hit then
        local gtfo = util.QuickTrace(mv:GetOrigin() + Vector(0, 0, 32), Vector(0, 0, -72), ply)
        gtfo.HitPos.z = gtfo.HitPos.z + ((gtfo.HitNormal.z ~= 1 and 12) or 5)
        mv:SetOrigin(gtfo.HitPos)
    end

    local activewep = ply:GetActiveWeapon()
    if IsValid(activewep) then activewep:SendWeaponAnim(ACT_VM_DRAW) end
end

local function ClimbingThink(ply, mv, cmd)
    local timemod = (ply:InOverdrive() and 0.075) or 0
    if CurTime() + timemod > ply:GetClimbingTime() then
        ClimbingEnd(ply, mv, cmd)
        return
    end

    mv:SetVelocity(vector_origin)
    mv:SetButtons(0)
    local lerpvalue = math.Clamp(math.abs((ply:GetClimbingTime() - CurTime()) / ClimbingTimes[ply:GetClimbing()] - 1) * ply:GetOverdriveMult(), 0, 1)
    local poslerp = LerpVector(lerpvalue, ply:GetClimbingStart(), ply:GetClimbingEnd())
    mv:SetOrigin(poslerp)
end

local function ClimbingRemoveInput(ply, cmd)
    if ply:GetClimbing() ~= 0 then
        local lerpvalue = 0
        if ply:InOverdrive() then lerpvalue = math.Clamp(math.abs((ply:GetClimbingTime() - CurTime()) / ClimbingTimes[ply:GetClimbing()] - 1) * ply:GetOverdriveMult(), 0, 1) end
        if lerpvalue < 0.85 then
            cmd:SetButtons(0)
            cmd:ClearMovement()
        end
    end
end

hook.Add("StartCommand", "ClimbingRemoveInput", ClimbingRemoveInput)
local function ClimbingCheck(ply, mv, cmd)
    local mins, maxs = ply:GetCollisionBounds()
    mins.z = maxs.z * 0.75
    if not ply.ClimbingTrace then
        ply.ClimbingTrace = {}
        ply.ClimbingTraceOut = {}
        ply.ClimbingTraceEnd = {}
        ply.ClimbingTraceEndOut = {}
        ply.ClimbingTraceSafety = {}
        ply.ClimbingTraceSafetyOut = {}
        ply.ClimbingTrace.mask = MASK_PLAYERSOLID
        ply.ClimbingTraceEnd.mask = MASK_PLAYERSOLID
        ply.ClimbingTraceSafety.mask = MASK_PLAYERSOLID
        ply.ClimbingTrace.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
        ply.ClimbingTraceEnd.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
        ply.ClimbingTraceSafety.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
    end

    local eyeang = ply:EyeAngles()
    eyeang.x = 0
    local tr = ply.ClimbingTrace
    local trout = ply.ClimbingTraceOut
    tr.start = mv:GetOrigin()
    tr.endpos = tr.start + eyeang:Forward() * 25
    tr.mins, tr.maxs = mins, maxs
    tr.filter = ply
    tr.output = trout
    util.TraceHull(tr)
    if not trout.Hit then return end
    if IsValid(trout.Entity) and trout.Entity:GetClass() == "br_swingbar" then return end
    local tr = ply.ClimbingTraceEnd
    local trout = ply.ClimbingTraceEndOut
    tr.start = mv:GetOrigin() + eyeang:Forward() * 25 + Vector(0, 0, 100)
    tr.endpos = tr.start - Vector(0, 0, 80)
    tr.filter = ply
    tr.output = trout
    util.TraceLine(tr)
    if (trout.Entity and trout.Entity.IsNPC) and (trout.Entity:IsNPC() or trout.Entity:IsPlayer()) then return false end
    if trout.Fraction < 0.3 or trout.Fraction == 1 then return end
    local endpos = trout.HitPos
    local height = trout.Fraction
    local startpos = ply.ClimbingTraceOut.HitPos
    startpos.z = trout.HitPos.z - 60
    startpos:Add(eyeang:Forward() * -5)
    local tr = ply.ClimbingTraceSafety
    local trout = ply.ClimbingTraceSafetyOut
    local mins, maxs = ply:GetCollisionBounds()
    mins.z = maxs.z * 0.25
    tr.start = endpos
    tr.endpos = tr.start
    tr.mins, tr.maxs = mins, maxs
    tr.filter = ply
    tr.output = trout
    util.TraceHull(tr)
    if trout.Hit then return end
    tr.start = mv:GetOrigin()
    tr.endpos = tr.start + Vector(0, 0, 75)
    util.TraceLine(tr)
    if trout.Hit then return end
    local origin = mv:GetOrigin()
    ply.ClimbingStartPosCache = startpos
    ply.ClimbingStartSmooth = origin
    mv:SetOrigin(startpos)
    local wr = ply:GetWallrun()
    local wrtime = ply:GetWallrunTime() - CurTime()
    local vel = mv:GetVelocity()
    if wr ~= 0 then
        ply:SetWallrun(0)
        ply:EmitSound("WallrunFast.Concrete")
    end

    local climbvalue = 1
    if vel.z > -350 and (wr ~= 0 or vel:Length() > 200) and (wr ~= 1 or wrtime > 1.425) then
        climbvalue = 2
        ply:ViewPunch(Angle(-3, 0, -4))
    end

    ply:SetClimbing(climbvalue)
    ply:SetClimbingStart(startpos)
    ply:SetClimbingEnd(endpos)
    ply:SetClimbingTime(CurTime() + ClimbingTimes[climbvalue])
    climb1.AnimString = climbstrings[climbvalue]
    ply:SetQuickturn(false)
    ply:SetWallrun(0)
    local activewep = ply:GetActiveWeapon()
    if IsValid(activewep) then usingrh = activewep:GetClass() == "runnerhands" end
    if usingrh and activewep.SendWeaponAnim then
        activewep:SendWeaponAnim(ACT_VM_HITCENTER)
        activewep:SetBlockAnims(false)
    end

    mv:SetVelocity(vector_origin)
    ply:SetMoveType(MOVETYPE_NOCLIP)
    ply:ViewPunch(Angle(5, 0, 0.5))
    ParkourEvent("climb", ply)
    if IsFirstTimePredicted() then
        if CLIENT or game.SinglePlayer() then timer.Simple(0.05, function() ply:EmitSound("Bump.Concrete") end) end
        ply:EmitSound("Handsteps.ConcreteHard")
        ply:EmitSound("Cloth.RollLand")
        ply:FaithVO("Faith.StrainSoft")
    end

    if CLIENT and IsFirstTimePredicted() then
        ply.ClimbingStartSmoothLerp = 0
        RemoveBodyAnim()
        hook.Add("Think", "BodyAnimClimbPos", BodyAnimClimbPos)
        StartBodyAnim(climb1)
        BodyAnimSpeed = ply:GetOverdriveMult()
    elseif game.SinglePlayer() then
        net.Start("BodyAnimClimb")
        net.WriteFloat(startpos.x)
        net.WriteFloat(startpos.y)
        net.WriteFloat(startpos.z)
        net.WriteFloat(origin.x)
        net.WriteFloat(origin.y)
        net.WriteFloat(origin.z)
        net.Send(ply)
    end

    if CLIENT or game.SinglePlayer() then ply:ConCommand("-jump") end
end

hook.Add("SetupMove", "Climbing", function(ply, mv, cmd)
    if ply:GetClimbing() == nil or not ply:Alive() then ply:SetClimbing(0) end
    if IsValid(ply:GetSwingbar()) then return end
    if ply:GetClimbing() == 0 and (mv:KeyDown(IN_FORWARD) or ply:GetWallrun() ~= 0 or ply:GetGrappling()) and not ply:OnGround() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then ClimbingCheck(ply, mv, cmd) end
    if ply:GetClimbing() ~= 0 then ClimbingThink(ply, mv, cmd) end
end)