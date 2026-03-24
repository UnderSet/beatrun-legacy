local meta = FindMetaTable("Player")

local PUNCH_DAMPING = 9
local PUNCH_SPRING_CONSTANT = 120

local viewbob_intensity = CreateClientConVar("Beatrun_ViewbobIntensity", "20", true, false, "Viewbob Intensity", -100, 100)

local function lensqr(ang)
    return (ang[1] ^ 2) + (ang[2] ^ 2) + (ang[3] ^ 2)
end

local function CLViewPunchThink()
	local self = LocalPlayer()
	if !self.ViewPunchVelocity then
		self.ViewPunchVelocity = Angle()
		self.ViewPunchAngle = Angle()
	end
	local vpa = self.ViewPunchAngle
    local vpv = self.ViewPunchVelocity

    if !self.ViewPunchDone and lensqr(vpa) + lensqr(vpv) > 0.000001 then
        local FT = FrameTime()

        vpa = vpa + (vpv * FT)
        local damping = 1 - (PUNCH_DAMPING * FT)
        if damping < 0 then
			damping = 0
		end
        vpv = vpv * damping

        local springforcemagnitude = PUNCH_SPRING_CONSTANT * FT
        springforcemagnitude = math.Clamp(springforcemagnitude, 0, 2)
        vpv = vpv - (vpa * springforcemagnitude)

        vpa[1] = math.Clamp(vpa[1], -89.9, 89.9)
        vpa[2] = math.Clamp(vpa[2], -179.9, 179.9)
        vpa[3] = math.Clamp(vpa[3], -89.9, 89.9)

        self.ViewPunchAngle = vpa
        self.ViewPunchVelocity = vpv
    else
		self.ViewPunchDone = true
	end
end
hook.Add("Think", "CLViewPunch", CLViewPunchThink)

local function CLViewPunchCalc(ply, pos, ang)
	if ply.ViewPunchAngle then
		ang:Add(ply.ViewPunchAngle * viewbob_intensity:GetFloat())
	end
end
hook.Add("CalcView","CLViewPunch",CLViewPunchCalc)

function meta:CLViewPunch(angle)
    self.ViewPunchVelocity:Add(angle)

    local ang = self.ViewPunchVelocity

    ang[1] = math.Clamp(ang[1], -180, 180)
    ang[2] = math.Clamp(ang[2], -180, 180)
    ang[3] = math.Clamp(ang[3], -180, 180)
	
	self.ViewPunchDone = false
end