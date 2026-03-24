local function Hardland()
    local ply = LocalPlayer()
    VManip:PlayAnim("hardland")
    ply.hardlandtime = CurTime() + 0.75
    util.ScreenShake(Vector(0, 0, 0), 2, 2, 0.25, 0)
end

if game.SinglePlayer() and SERVER then util.AddNetworkString("Beatrun_HardLand") end
if game.SinglePlayer() and CLIENT then net.Receive("Beatrun_HardLand", function() Hardland() end) end
hook.Add("PlayerStepSoundTime", "MEStepTime", function(ply, step, walking)
    local activewep = ply:GetActiveWeapon()
    local stepmod = (ply:GetStepRight() and 1) or -1
    local stepvel = (ply:GetMEMoveLimit() < 350 and 1) or 0
    local stepvel2 = (stepvel == 1 and 1) or 0.75
    local stepmod2 = 1
    local stepmod3 = 1
    if IsValid(activewep) and activewep:GetClass() ~= "runnerhands" then
        stepmod2 = 0.25
        if not ply:IsSprinting() then stepmod3 = 0.25 end
    end

    if not ply:Crouching() then
        if game.SinglePlayer() then
            ply:ViewPunch(Angle(0.55 * stepmod2 * stepvel2, 0, 0.5 * stepmod * stepvel * stepmod3))
        elseif CLIENT and IsFirstTimePredicted() then
            ply:CLViewPunch(Angle(0.55 * stepmod2 * stepvel2, 0, 0.5 * stepmod * stepvel * stepmod3))
        end
    end

    local steptime = math.Clamp((800 / (ply:GetVelocity() * Vector(1, 1, 0)):Length()) * 100, 200, 400)
    if ply:Crouching() then steptime = steptime * 2 end
    ply:SetStepRelease(CurTime() + (steptime * 0.25) * 0.001)
    return steptime
end)

hook.Add("PlayerFootstep", "MEStepSound", function(ply, pos, foot, sound, volume, filter)
    ply:SetStepRight(foot == 1)
    if ply:GetSliding() then return true end
    local mat = sound:sub(0, -6)
    local newsound = FOOTSTEPS_LUT[mat]
    if mat == "player/footsteps/ladder" then return end
    if not newsound then newsound = "Concrete" end
    ply.FootstepReleaseLand = true
    if CLIENT or game.SinglePlayer() then
        ply:EmitSound("Footsteps." .. newsound)
        ply:EmitSound("Cloth.MovementRun")
        if math.random() > 0.9 then ParkourEvent("step") end
    end

    ply.LastFootstepSound = mat
    if ply:WaterLevel() > 0 then ply:EmitSound("Footsteps.Water") end
    if ply.FootstepLand then
        local landsound = FOOTSTEPS_LAND_LUT[mat] or "Concrete"
        ply:EmitSound("Land." .. landsound)
        ply.FootstepLand = false
    end
    return true
end)

hook.Add("OnPlayerHitGround", "MELandSound", function(ply, water, floater, speed)
    local vel = ply:GetVelocity()
    vel.z = 0
    ply.FootstepLand = true
    ply:ViewPunch(Angle(3, 0, 1.5) * (speed * 0.0025))
    if SERVER and vel:Length() < 100 then ply:PlayStepSound(1) end
    ParkourEvent("land", ply)
    if speed > 450 and speed < 750 and (ply:GetSafetyRollKeyTime() <= CurTime() or ply:GetCrouchJump()) then
        ply:ViewPunch(Angle(10, -2, 5))
        ply:SetMESprintDelay(CurTime() + 0.5)
        ply:SetMEMoveLimit(50)
        if CLIENT then
            Hardland()
        elseif SERVER and game.SinglePlayer() then
            net.Start("Beatrun_HardLand")
            net.Send(ply)
        end
    end
end)

hook.Add("SetupMove", "MESetupMove", function(ply, mv, cmd)
    local activewep = ply:GetActiveWeapon()
    local usingrh = IsValid(activewep) and activewep:GetClass() == "runnerhands"
    local ismoving = (mv:KeyDown(IN_FORWARD) or not ply:OnGround() or ply:Crouching()) and not mv:KeyDown(IN_BACK) and ply:Alive() and (mv:GetVelocity():Length() > 50 or ply:GetMantle() ~= 0 or ply:Crouching())
    if (CLIENT or game.SinglePlayer()) and CurTime() > (ply:GetStepRelease() or 0) and ply.FootstepReleaseLand then
        local newsound = FOOTSTEPS_RELEASE_LUT[ply.LastFootstepSound] or "Concrete"
        if ply:WaterLevel() > 0 then ply:EmitSound("Release.Water") end
        ply:EmitSound("Release." .. newsound)
        ply.FootstepReleaseLand = false
    end

    if not ply:OnGround() then ply.FootstepLand = true end
    if ply:GetRunSpeed() ~= 405 * ply:GetOverdriveMult() then ply:SetRunSpeed(405 * ply:GetOverdriveMult()) end
    if not ply:GetMEMoveLimit() then
        ply:SetMEMoveLimit(225)
        ply:SetMESprintDelay(0)
        ply:SetMEAng(0)
    end

    local MEAng = math.Truncate(mv:GetAngles():Forward().x, 2)
    if ismoving and (cmd:KeyDown(IN_SPEED) or (not ply:OnGround() and mv:GetVelocity().z > -450)) and CurTime() > ply:GetMESprintDelay() and math.abs((MEAng - ply:GetMEAng()) * 100) < 10 then
        ply:SetMEMoveLimit(math.Clamp(ply:GetMEMoveLimit() + (1 * ply:GetOverdriveMult() * 2), 0, 600))
    elseif not ismoving and (not ply:Crouching() or ply:GetCrouchJump()) then
        ply:SetMEMoveLimit(math.Clamp(ply:GetMEMoveLimit() - 20, 250 / 1.5, 600))
        ply:SetMESprintDelay(CurTime() + 1)
    elseif not ply:Crouching() or ply:GetCrouchJump() then
        ply:SetMEMoveLimit(225)
    end

    mv:SetMaxClientSpeed(ply:GetMEMoveLimit())
    ply:SetMEAng(MEAng)
    if usingrh and activewep.GetSideStep and not activewep:GetSideStep() and CurTime() > ply:GetSlidingDelay() - 0.2 and ply:OnGround() and not ply:Crouching() and not cmd:KeyDown(IN_FORWARD) and not cmd:KeyDown(IN_JUMP) and cmd:KeyDown(IN_ATTACK2) then
        if mv:KeyDown(IN_MOVELEFT) then
            activewep:SendWeaponAnim(ACT_TURNLEFT45)
            activewep:SetSideStep(true)
            mv:SetVelocity(cmd:GetViewAngles():Right() * -600)
            ply:ViewPunch(Angle(-3, 0, -4.5))
            ParkourEvent("sidestep", ply)
            if game.SinglePlayer() then ply:PlayStepSound(1) end
        elseif mv:KeyDown(IN_MOVERIGHT) then
            activewep:SendWeaponAnim(ACT_TURNRIGHT45)
            activewep:SetSideStep(true)
            mv:SetVelocity(cmd:GetViewAngles():Right() * 600)
            ply:ViewPunch(Angle(-3, 0, 4.5))
            ParkourEvent("sidestep", ply)
            if game.SinglePlayer() then ply:PlayStepSound(1) end
        end
    end
end)

if CLIENT then
    local jumpseq = {ACT_VM_HAULBACK, ACT_VM_SWINGHARD}
    hook.Add("CreateMove", "MECreateMove", function(cmd)
        local ply = LocalPlayer()
        local activewep = ply:GetActiveWeapon()
        local usingrh = IsValid(activewep) and activewep:GetClass() == "runnerhands"
        local hardland = (ply.hardlandtime or 0) > CurTime()
        if hardland then
            cmd:RemoveKey(IN_ATTACK2)
            cmd:SetForwardMove(cmd:GetForwardMove() * 0.01)
            cmd:SetSideMove(cmd:GetSideMove() * 0.01)
        end

        if usingrh and ply:GetMoveType() == MOVETYPE_WALK and not hardland and (ply:OnGround() or ply:GetMantle() ~= 0) and not cmd:KeyDown(IN_SPEED) then cmd:SetButtons(cmd:GetButtons() + IN_SPEED) end
    end)

    hook.Add("GetMotionBlurValues", "MEBlur", function(h, v, f, r)
        local ply = LocalPlayer()
        local vel = LocalPlayer():GetVelocity()
        if not ply.blurspeed then ply.blurspeed = 0 end
        if inmantle then vel = vector_origin end
        vel.z = 0
        if vel:Length() > 385 then
            ply.blurspeed = Lerp(0.001, ply.blurspeed, 0.25)
        else
            ply.blurspeed = math.Approach(ply.blurspeed, 0, 0.005)
        end
        return h, v, ply.blurspeed, r
    end)
end

MMRot = 0
MMX, MMY = 0, 0
hook.Add("InputMouseApply", "MouseMovement", function(cmd, x, y)
    MMX, MMY = x, y
    local ply = LocalPlayer()
    local activewep = ply:GetActiveWeapon()
    local usingrh = IsValid(activewep) and activewep:GetClass() == "runnerhands"
    if not LocalPlayer():OnGround() or (usingrh and activewep.GetSideStep and activewep:GetSideStep()) then MMX = 0 end
end)

hook.Add("CalcView", "lol", function(ply, pos, ang) MMRot = Lerp(7.5 * RealFrameTime(), MMRot, MMX * 0.2) end)