local playermodelbones = {"ValveBiped.Bip01_R_Clavicle", "ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_L_Clavicle", "ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_L_Forearm", "ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_L_Wrist", "ValveBiped.Bip01_R_Wrist", "ValveBiped.Bip01_L_Finger4", "ValveBiped.Bip01_L_Finger41", "ValveBiped.Bip01_L_Finger42", "ValveBiped.Bip01_L_Finger3", "ValveBiped.Bip01_L_Finger31", "ValveBiped.Bip01_L_Finger32", "ValveBiped.Bip01_L_Finger2", "ValveBiped.Bip01_L_Finger21", "ValveBiped.Bip01_L_Finger22", "ValveBiped.Bip01_L_Finger1", "ValveBiped.Bip01_L_Finger11", "ValveBiped.Bip01_L_Finger12", "ValveBiped.Bip01_L_Finger0", "ValveBiped.Bip01_L_Finger01", "ValveBiped.Bip01_L_Finger02", "ValveBiped.Bip01_R_Finger4", "ValveBiped.Bip01_R_Finger41", "ValveBiped.Bip01_R_Finger42", "ValveBiped.Bip01_R_Finger3", "ValveBiped.Bip01_R_Finger31", "ValveBiped.Bip01_R_Finger32", "ValveBiped.Bip01_R_Finger2", "ValveBiped.Bip01_R_Finger21", "ValveBiped.Bip01_R_Finger22", "ValveBiped.Bip01_R_Finger1", "ValveBiped.Bip01_R_Finger11", "ValveBiped.Bip01_R_Finger12", "ValveBiped.Bip01_R_Finger0", "ValveBiped.Bip01_R_Finger01", "ValveBiped.Bip01_R_Finger02"}
BodyAnim = nil
BodyAnimMDL = nil
BodyAnimMDLarm = nil
BodyAnimWEPMDL = nil
BodyAnimCycle = 0
BodyAnimEyeAng = Angle(0, 0, 0)
local BodyAnimPos = Vector(0, 0, 0)
local BodyAnimSmoothAng = false
local BodyAnimAngLerp = Angle(0, 0, 0)
local BodyAnimAngLerpM = Angle(0, 0, 0)
local DidDraw = false
local FOVLerp = 0
local FOVLerp2 = 0
local AnimString = "nil"
BodyAnimString = "nil"
BodyAnimMDLString = "nil"
local angclosenuff = false
local savedeyeangb = Angle(0, 0, 0)
local bodylockview = false
local bodyanimdone = false
local holstertime = 0
local animmodelstring = ""
local showweapon = false
local usefullbody = false
local followplayer = true
deleteonend = true
local customlimitup = 0
local customlimitdown = 0
local customlimithor = 0
local customlimit360 = false
local customlimitdownclassic = false
local lockang = false
local ignorez = false
local customcycle = false
local deathanim = false
local allowmove = false
local allowedangchange = false
BodyAnimSpeed = 1
BodyAnimFollow = false
BodyAnimLockDirection = 0
local attach = nil
local attachId = nil
bodyanimlastattachang = Angle(0, 0, 0)
local weapontoidle = nil
local enhancedcameraconvar = "check"
local ecenabled = false
local smoothend = false
local endlerp = 0
local view = {}
local justremoved = false

local calcviewrunning = false

function RemoveBodyAnim(noang)
    local ply = LocalPlayer()
    local ang = ply:EyeAngles()
    local newang = ply:EyeAngles()
    local whydoineedtodothis = 0.001
    local noang = noang or false
    if allowedangchange then
        newang = view.angles
    else
        newang = BodyAnimEyeAng
    end

    newang.z = 0
    if IsValid(BodyAnim) then
        BodyAnim:SetNoDraw(true)
        if IsValid(BodyAnimMDL) then
            BodyAnimMDL:SetRenderMode(RENDERMODE_NONE)
            if BodyAnimMDL.callback ~= nil then BodyAnimMDL:RemoveCallback("BuildBonePositions", BodyAnimMDL.callback) end
            BodyAnimMDL:Remove()
        end

        if IsValid(BodyAnimMDLarm) then BodyAnimMDLarm:Remove() end
        if IsValid(BodyAnimWEPMDL) then BodyAnimWEPMDL:Remove() end
        if not noang then ply:SetEyeAngles(newang) end
        if not smoothend then endlerp = 1 end
        BodyAnim:Remove()
        justremoved = true
        ply:DrawViewModel(true)
        DidDraw = false
    end

    local currentwep = ply:GetActiveWeapon()
    local vm = ply:GetViewModel()
    if IsValid(currentwep) and currentwep:GetClass() ~= "runnerhands" then
        weapontoidle = currentwep
        currentwep:SendWeaponAnim(ACT_VM_DRAW)
        timer.Simple(vm:SequenceDuration(vm:SelectWeightedSequence(ACT_VM_DRAW)), function()
            if ply:GetActiveWeapon() == weapontoidle and weapontoidle:GetSequenceActivityName(weapontoidle:GetSequence()) == "ACT_VM_DRAW" then
                weapontoidle:GetSequenceActivityName(weapontoidle:GetSequence())
                weapontoidle:SendWeaponAnim(ACT_VM_IDLE)
            end
        end)
    end
end

function StartBodyAnim(animtable)
    if IsValid(BodyAnim) and not justremoved then return end
    justremoved = false
    local ply = LocalPlayer()
    AnimString = animtable.AnimString
    BodyAnimString = AnimString
    BodyAnimSmoothAng = animtable.BodyAnimSmoothAng or false
    animmodelstring = animtable.animmodelstring
    BodyAnimMDLString = animmodelstring
    usefullbody = animtable.usefullbody or 2
    showweapon = animtable.showweapon or false
    BodyAnimSpeed = animtable.BodyAnimSpeed or 1
    customang = animtable.customang or "nil"
    customlerp = animtable.customlerp or 10
    FOVLerp = animtable.FOVLerp or 0
    customlimitdown = animtable.customlimitdown or 0
    customlimitup = animtable.customlimitup or 0
    customlimit360 = animtable.customlimit360 or false
    customlimithor = animtable.customlimithor or 0
    customlimitdownclassic = animtable.customlimitdownclassic or false
    deleteonend = animtable.deleteonend
    followplayer = animtable.followplayer or false
    lockang = animtable.lockang or false
    allowmove = animtable.allowmove or false
    ignorez = animtable.ignorez or false
    deathanim = animtable.deathanim or false
    customcycle = animtable.customcycle or false
    smoothend = animtable.smoothend or false
    ply.OrigEyeAng = ply:EyeAngles()
    ply.OrigEyeAng.x = 0
    if VMLegs:IsActive() then VMLegs:Remove() end
    if deleteonend == nil then deleteonend = true end
    if followplayer == nil then followplayer = true end
    hook.Add("CalcView", "BodyAnimCalcView2", BodyAnimCalcView2)
    BodyAnimAngLerp = ply:EyeAngles()
    if AnimString == nil or (not ply:Alive() and not deathanim) then return end
    BodyAnimAngLerpM = ply:EyeAngles()
    savedeyeangb = Angle(0, 0, 0)
    BodyAnim = ClientsideModel("models/" .. tostring(animmodelstring) .. ".mdl", RENDERGROUP_BOTH)
    if customang == "nil" then
        BodyAnim:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    else
        BodyAnim:SetAngles(Angle(0, customang, 0))
    end

    BodyAnim:SetPos(ply:GetPos())
    BodyAnim:SetNoDraw(false)
    local plymodel = ply
    local playermodel = string.Replace(ply:GetModel(), "models/models/", "models/")
    local handsmodel = string.Replace(ply:GetHands():GetModel(), "models/models/", "models/")
    if not util.IsValidModel(playermodel) then
        local modelpath = ply:GetPData(playermodel, 0)
        if modelpath ~= 0 then
            playermodel = modelpath
        else
            chat.PlaySound()
            chat.AddText(Color(255, 0, 0), "Your playermodel has a misconfigured path, use another, or follow this guide\nhttps://pastebin.com/hgNqSEcG")
        end
    end

    if not util.IsValidModel(handsmodel) then
        local modelpath = ply:GetPData(handsmodel, 0)
        if modelpath ~= 0 then
            handsmodel = modelpath
        else
            chat.PlaySound()
            chat.AddText(Color(255, 0, 0), "Your playermodel has a misconfigured path (hands), use another, or follow this guide\nhttps://pastebin.com/hgNqSEcG")
        end
    end

    if usefullbody == 2 then
        BodyAnimMDL = ClientsideModel(playermodel, RENDERGROUP_BOTH)
        BodyAnimMDL.GetPlayerColor = ply:GetHands().GetPlayerColor
        BodyAnimMDL:SnatchModelInstance(ply)
        BodyAnimMDLarm = ClientsideModel(handsmodel, RENDERGROUP_BOTH)
        BodyAnimMDLarm.GetPlayerColor = ply:GetHands().GetPlayerColor
        BodyAnimMDLarm:SetLocalPos(Vector(0, 0, 0))
        BodyAnimMDLarm:SetLocalAngles(Angle(0, 0, 0))
        BodyAnimMDLarm:SetParent(BodyAnim)
        BodyAnimMDLarm:AddEffects(EF_BONEMERGE)
        for num, _ in pairs(ply:GetHands():GetBodyGroups()) do
            BodyAnimMDLarm:SetBodygroup(num - 1, ply:GetHands():GetBodygroup(num - 1))
            BodyAnimMDLarm:SetSkin(ply:GetHands():GetSkin())
        end

        BodyAnimMDL.callback = BodyAnimMDL:AddCallback("BuildBonePositions", function(ent, numbones)
            if IsValid(BodyAnimMDL) then
                for k, v in ipairs(playermodelbones) do
                    local plybone = BodyAnimMDL:LookupBone(v)
                    if plybone ~= nil then
                        local mat = BodyAnimMDL:GetBoneMatrix(plybone)
                        if mat ~= nil then
                            mat:Scale(Vector(0, 0, 0))
                            BodyAnimMDL:SetBoneMatrix(plybone, mat)
                        end
                    end
                end
            end
        end)
    elseif usefullbody == 1 then
        BodyAnimMDL = ClientsideModel(playermodel, RENDERGROUP_BOTH)
    else
        BodyAnimMDL = ClientsideModel(string.Replace(handsmodel, "models/models/", "models/"), RENDERGROUP_BOTH)
        BodyAnimMDL.GetPlayerColor = ply:GetHands().GetPlayerColor
        plymodel = ply:GetHands()
    end

    for num, _ in pairs(plymodel:GetBodyGroups()) do
        BodyAnimMDL:SetBodygroup(num - 1, plymodel:GetBodygroup(num - 1))
        BodyAnimMDL:SetSkin(plymodel:GetSkin())
    end

    BodyAnimMDL:SetLocalPos(Vector(0, 0, 0))
    BodyAnimMDL:SetLocalAngles(Angle(0, 0, 0))
    BodyAnimMDL:SetParent(BodyAnim)
    BodyAnimMDL:AddEffects(EF_BONEMERGE)
    BodyAnim:SetSequence(AnimString)
    if tobool(showweapon) and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetModel() ~= "" then
        BodyAnimWEPMDL = ClientsideModel(ply:GetActiveWeapon():GetModel(), RENDERGROUP_BOTH)
        BodyAnimWEPMDL:SetPos(ply:GetPos())
        BodyAnimWEPMDL:SetAngles(Angle(0, EyeAngles().y, 0))
        BodyAnimWEPMDL:SetParent(BodyAnim)
        BodyAnimWEPMDL:AddEffects(EF_BONEMERGE)
    end

    if BodyAnimMDL:LookupBone("ValveBiped.Bip01_Head1") ~= nil and not ply:ShouldDrawLocalPlayer() then BodyAnimMDL:ManipulateBoneScale(BodyAnimMDL:LookupBone("ValveBiped.Bip01_Head1"), Vector(0, 0, 0)) end
    ply:DrawViewModel(false)
    BodyAnimCycle = 0
    DidDraw = false
    FOVLerp2 = 0
    angclosenuff = false
    bodyanimdone = false
end

concommand.Add("StartBodyAnim", function(ply, cmd, args)
    local animtable = {}
    animtable.AnimString = tostring(args[1])
    animtable.BodyAnimSmoothAng = args[2] or false
    animtable.animmodelstring = args[3] or "bagbodyanim"
    animtable.usefullbody = args[4] or 0
    animtable.showweapon = args[5] or false
    animtable.BodyAnimSpeed = args[6] or 1
    animtable.customang = args[7] or "nil"
    animtable.customlerp = args[8] or 0.1
    animtable.FOVLerp = tonumber(args[9]) or 0
    StartBodyAnim(animtable)
end)

concommand.Add("BodyAnim_RegisterPlayermodel", function(ply, cmd, args)
    local playermodel = ply:GetModel()
    local modelpath = args[1] or playermodel
    local isvalidply = util.IsValidModel(playermodel)
    local isvalidcustom = util.IsValidModel(modelpath)
    if modelpath ~= playermodel and isvalidcustom and not isvalidply then
        ply:SetPData(playermodel, modelpath)
        print("BodyAnim will now use " .. modelpath .. " instead of " .. playermodel)
    elseif isvalidply then
        print("ERROR: " .. playermodel .. " is already correct. Aborting")
    elseif not isvalidcustom then
        print("ERROR: " .. modelpath .. " is not a valid model")
    end
end)

concommand.Add("BodyAnim_RegisterPlayerhands", function(ply, cmd, args)
    local handsmodel = ply:GetHands():GetModel()
    local modelpath = args[1] or handsmodel
    local isvalidhands = util.IsValidModel(handsmodel)
    local isvalidcustom = util.IsValidModel(modelpath)
    if modelpath ~= handsmodel and isvalidcustom and not isvalidhands then
        ply:SetPData(handsmodel, modelpath)
        print("BodyAnim will now use " .. modelpath .. " instead of " .. handsmodel .. " (hands)")
    elseif isvalidhands then
        print("ERROR: " .. handsmodel .. " is already correct. Aborting")
    elseif not isvalidcustom then
        print("ERROR: " .. modelpath .. " is not a valid model")
    end
end)

hook.Add("Think", "BodyAnimThink", function()
    local ply = LocalPlayer()
    if enhancedcameraconvar == "check" then enhancedcameraconvar = GetConVar("cl_ec_enabled") end
    if (not ply:Alive() and not deathanim) and IsValid(BodyAnim) then
        RemoveBodyAnim()
        return
    end

    if not IsValid(BodyAnimMDL) or not IsValid(BodyAnim) then
        if enhancedcameraconvar ~= "check" and enhancedcameraconvar then
            if ecenabled and not enhancedcameraconvar:GetBool() then
                enhancedcameraconvar:SetBool(true)
                ecenabled = false
            end
        end
        return
    end

    if enhancedcameraconvar ~= "check" and enhancedcameraconvar then
        if enhancedcameraconvar:GetBool() then
            enhancedcameraconvar:SetBool(false)
            ecenabled = true
        end
    end

    if not bodyanimdone then BodyAnimCycle = BodyAnimCycle + FrameTime() / BodyAnim:SequenceDuration() * BodyAnimSpeed end
    if not customcycle then BodyAnim:SetCycle(BodyAnimCycle) end
    FOVLerp2 = Lerp(0.01, FOVLerp2, FOVLerp)
    if deleteonend and not customcycle and BodyAnimCycle >= 1 then RemoveBodyAnim() end
end)

local lastattachpos = Vector(0, 0, 0)
function BodyAnimCalcView2(ply, pos, angles, fov, ...)
    if calcviewrunning then return end
    if (IsValid(BodyAnim) or attach ~= nil) then
        if IsValid(BodyAnim) then
            if followplayer then BodyAnim:SetPos(LocalPlayer():GetPos()) end
            attachId = BodyAnim:LookupAttachment("eyes")
            attach = BodyAnim:GetAttachment(attachId) or attach
        end

        if attach ~= nil then
            view.origin = attach.Pos
            if savedeyeangb == Angle(0, 0, 0) then savedeyeangb = Angle(0, attach.Ang.y, 0) end
            if BodyAnimSmoothAng and not angclosenuff then
                ply:SetEyeAngles(Angle(0, 0, 0))
                if (BodyAnimAngLerp.x - attach.Ang.x) >= -0.6 and (BodyAnimAngLerp.x - attach.Ang.x) <= 0.9 then angclosenuff = true end
                BodyAnimAngLerp = LerpAngle(customlerp * FrameTime(), BodyAnimAngLerp, Angle(attach.Ang.x * 1.5, attach.Ang.y, attach.Ang.z))
                view.angles = Angle(math.Clamp(BodyAnimAngLerp.x, -90, 30), BodyAnimAngLerp.y, BodyAnimAngLerp.z)
            else
                view.angles = ply:EyeAngles()
                allowedangchange = true
            end

            if lockang then
                view.angles = attach.Ang
                allowedangchange = false
            end

            local vm = ply:GetViewModel()
            BodyAnimEyeAng = attach.Ang
            BodyAnimPos = attach.Pos
            lastattachpos = attach.Pos
            bodyanimlastattachang = ply:EyeAngles()
            view.pos = attach.Pos
            if not IsValid(BodyAnim) and endlerp < 1 then
                endlerp = math.Approach(endlerp, 1, RealFrameTime() * 6)
                attach.Pos = LerpVector(endlerp, attach.Pos, ply:EyePos())
                attach.Ang = LerpAngle(endlerp * 2, attach.Ang, ply:EyeAngles() + ply:GetViewPunchAngles())
                if IsValid(vm) then vm:SetNoDraw(false) end
            elseif not IsValid(BodyAnim) and endlerp == 1 then
                attach = nil
                endlerp = 0
                hook.Remove("CalcView", "BodyAnimCalcView2")
                if IsValid(vm) then vm:SetNoDraw(false) end
                return
            end

            if IsValid(BodyAnim) and IsValid(vm) then vm:SetNoDraw(true) end
            if not ply:ShouldDrawLocalPlayer() then
                ply:SetNoDraw(false)
                view.angles = view.angles + ply:GetViewPunchAngles()

                pos:Set(view.pos)
                angles:Set(view.angles)

				calcviewrunning = true

				local view = hook.Run("CalcView", ply, pos, angles, fov, ...)
				calcviewrunning = false
				if view and view.fov then 
					view.fov = math.Remap(view.fov, 0, GetConVar("fov_desired"):GetInt(), 0, GetConVar("beatrun_fov"):GetInt())
					
					return view
				else
					fov = math.Remap(fov, 0, GetConVar("fov_desired"):GetInt(), 0, GetConVar("beatrun_fov"):GetInt())
					return
				end

                -- return view
            else
                ply:SetNoDraw(true)
            end
        end

        if (attach == nil) or CurTime() < mantletimer then
            view.origin = lastattachpos
            return lastattachpos
        end
    end
end

hook.Add("CreateMove", "BodyLimitMove", function(cmd)
    local ply = LocalPlayer()
    if IsValid(BodyAnimMDL) then
        if not allowmove then
            cmd:ClearButtons()
            cmd:ClearMovement()
        end
    end
end)

hook.Add("PostDrawOpaqueRenderables", "IgnoreZBodyAnim", function(depth, sky)
    if IsValid(BodyAnimMDL) then
        if ignorez then
            cam.IgnoreZ(true)
            BodyAnimMDL:DrawModel()
            if IsValid(BodyAnimMDLarm) then BodyAnimMDLarm:DrawModel() end
            cam.IgnoreZ(false)
        end
    end
end)

local lasteyeang = Angle()
hook.Add("InputMouseApply", "BodyAnim_Mouse", function(cmd, x, y)
    local ply = LocalPlayer()
    if not lockang and IsValid(BodyAnim) then
        local nang = cmd:GetViewAngles()
        local oang = ply.OrigEyeAng
        local limitx = 30
        local limity = 50
        if math.AngleDifference(nang.x, oang.x) > limitx then
            local ang = ply:EyeAngles()
            ang.x = lasteyeang.x
            cmd:SetViewAngles(ang)
            return true
        end

        if math.abs(math.AngleDifference(nang.y, oang.y)) > limity then
            local ang = ply:EyeAngles()
            ang.y = lasteyeang.y
            if math.abs(math.AngleDifference(ang.y, oang.y)) > limity then ang = oang end
            cmd:SetViewAngles(ang)
            return true
        end

        lasteyeang = nang
    end
end)