Checkpoints = Checkpoints or {}
CheckpointNumber = CheckpointNumber or 1
local Checkpoints = Checkpoints

Course_StartTime = 0
Course_GoTime = 0
Course_EndTime = 0
Course_ID = Course_ID or ""
Course_Name = Course_Name or ""
local cptimes = {}
local lastcptime = 0
local pbtimes = nil
local pbtotal = 0

local color_positive, color_negative, color_neutral = Color(0, 255, 0, 255), Color(255,0,0,255), Color(200,200,200,255)
local timetext = ""
local timealpha = 1000
local timecolor = color_neutral

if SERVER then
	util.AddNetworkString("Checkpoint_Hit")
	util.AddNetworkString("Checkpoint_Finish")
else
	surface.CreateFont( "BeatrunHUD", {
		font = "Roboto",
		extended = false,
		size = 32,
		weight = 2000,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = true,
		additive = false,
		outline = false,
	} )
end

function LoadCheckpoints()
	table.Empty(Checkpoints)
	if SERVER then
		for k,v in pairs(player.GetAll()) do
			v:SetNW2Int("CPNum", 1)
		end
	end
	if CLIENT then
	timer.Simple(1, function()
		for k,v in pairs(ents.FindByClass("tt_cp")) do
			if IsValid(v) and v.GetCPNum then
				Checkpoints[v:GetCPNum()] = v
			end
		end
	end)
	else
		for k,v in pairs(ents.FindByClass("tt_cp")) do
			Checkpoints[v:GetCPNum()] = v
		end
	end
end

if CLIENT then
	net.Receive("Checkpoint_Hit", function()
		local timetaken = CurTime()-lastcptime
		local vspb
		if pbtimes then
			vspb = timetaken - (pbtimes[CheckpointNumber] or 0)
		end
		table.insert(cptimes, timetaken)
		lastcptime = CurTime()
		CheckpointNumber = net.ReadUInt(8)
		
		if blinded then
			LocalPlayer():EmitSound("good.wav", 75, 75)
		end
		
		if !pbtimes or vspb == 0 then
			LocalPlayer():EmitSound("A_TT_CP_Neutral.wav")
			timecolor = color_neutral
			timetext = string.FormattedTime( math.abs(timetaken), "%02i:%02i:%02i" )
		elseif vspb < 0 then
			LocalPlayer():EmitSound("A_TT_CP_Positive.wav")
			timecolor = color_positive
			timetext = "-"..string.FormattedTime( math.abs(vspb), "%02i:%02i:%02i" )
		else
			LocalPlayer():EmitSound("A_TT_CP_Negative.wav")
			timecolor = color_negative
			timetext = "+"..string.FormattedTime( math.abs(vspb), "%02i:%02i:%02i" )
		end
		LocalPlayer():AddXP(5)
		timealpha = 1000
		print(timetaken, vspb)
	end)
	
	net.Receive("Checkpoint_Finish", function()
		table.insert(cptimes, CurTime()-lastcptime)
		local totaltime = CurTime() - Course_StartTime
		local timestr = totaltime - pbtotal
		LocalPlayer():AddXP( math.min(10 * CheckpointNumber, 100) )
		CheckpointNumber = -1
		Course_EndTime = totaltime
		
		if blinded then
			LocalPlayer():EmitSound("reset.wav", 75, 75)
		end
		
		if pbtotal == 0 or totaltime < pbtotal then
			timetext = "-"..string.FormattedTime( math.abs(timestr), "%02i:%02i:%02i" )
			timecolor = color_positive
			LocalPlayer():EmitSound("A_TT_Finish_Positive.wav")
			SaveCheckpointTime()
			SaveReplayData()
		else
			timetext = "+"..string.FormattedTime( math.abs(timestr), "%02i:%02i:%02i" )
			timecolor = color_negative
			LocalPlayer():EmitSound("A_TT_Finish_Negative.wav")
		end
		ReplayStop(LocalPlayer())
		
		net.Start("Checkpoint_Finish")
		net.WriteFloat(totaltime)
		net.SendToServer()
		timealpha = 1000
	end)
end

if SERVER then
	net.Receive("Checkpoint_Finish", function(len, ply)
		local pb = net.ReadFloat() or 0
		if ply:GetNW2Float("PBTime") == 0 or pb < ply:GetNW2Float("PBTime") then
			ply:SetNW2Float("PBTime", pb)
		end
	end)
end

local finishcolor = Color(45,45,175,100)
function FinishCourse(ply)
	ply:ScreenFade(SCREENFADE.IN, finishcolor, 0, 4)
	ply:SetLaggedMovementValue(0.1)
	ply:DrawViewModel(false)
	net.Start("Checkpoint_Finish")
	net.Send(ply)
	ply:SetNW2Int("CPNum", -1)
	timer.Simple(4, function() --Fade to white and show UI
		ply:SetLaggedMovementValue(1) 
		ply:DrawViewModel(true)
	end)
end

local countdown = 0
local countdownalpha = 255
local countdowntext = {
"Ready", "Set", "Go!!"
}
local function StartCountdown()
	local CT = CurTime()
	if CT >= Course_GoTime then
		Course_GoTime = CT+1
		countdown = countdown + 1
		if countdown >= 3 then
			LocalPlayer():EmitSound("A_TT_CD_02.wav")
			hook.Remove("Think", "StartCountdown")
			hook.Remove("StartCommand", "StartFreeze")
		else
			LocalPlayer():EmitSound("A_TT_CD_01.wav")
		end
	end
end
local function StartCountdownHUD()
	local text = countdowntext[countdown] or ""
	surface.SetFont("DermaLarge")
	surface.SetTextColor(255,255,255,countdownalpha)
	local w, h = surface.GetTextSize(text)
	surface.SetTextPos(ScrW() * 0.5 - (w * 0.5), ScrH() * 0.3)
	surface.DrawText(text)
	if countdown >= 3 then
		countdownalpha = (countdownalpha - (FrameTime() * 250))
		if countdownalpha <= 0 then
			hook.Remove("HUDPaint","StartCountdownHUD")
		end
	end
end

function CourseHUD()
	local ply = LocalPlayer()
	local vp = ply:GetViewPunchAngles()
	local vpx, vpz = vp.x, vp.z
	local incourse = Course_Name != ""
	surface.SetFont("DermaLarge")
	surface.SetTextColor(255,255,255,255)
	local totaltime = (CheckpointNumber != -1 and math.max(0, CurTime() - Course_StartTime)) or Course_EndTime
	
	if incourse then
		local text = string.FormattedTime( totaltime, "%02i:%02i:%02i" )
		local w, h = surface.GetTextSize(text)
		surface.SetTextPos(ScrW() * 0.85 - (w * 0.5) + vpx, ScrH() * 0.075 + vpz)
		surface.DrawText(text)
	end
	
	if !BuildMode and hook.Run("BeatrunDrawHUD") != false and !ply.InReplay then
		local speed = math.Round(ply:GetVelocity():Length()*0.06858125)
		if speed < 10 then
			speed = "0"..speed
		end
		text = speed.." km/h"
		w, h = surface.GetTextSize(text)
		surface.SetTextPos(ScrW() * 0.85 - (w * 0.5) + vpx, ScrH() * 0.85 + vpz)
		surface.DrawText(text)
	end
	
	if incourse and pbtimes then
		local text = string.FormattedTime( pbtotal, "%02i:%02i:%02i" )
		local w, h = surface.GetTextSize(text)
		surface.SetTextPos(ScrW() * 0.85 - (w * 0.5) + vpx, ScrH() * 0.075 + h + vpz)
		surface.SetTextColor(255,255,255,125)
		surface.DrawText(text)
	end
	if timealpha > 0 then
		local w, h = surface.GetTextSize(timetext)
		timealpha = math.max(0, timealpha - (FrameTime()*250))
		timecolor.a = math.min(255, timealpha)
		surface.SetTextPos(ScrW() * 0.5 - (w * 0.5) + vpx, ScrH() * 0.3 + vpz)
		surface.SetTextColor(timecolor)
		surface.DrawText(timetext)
	end
end
hook.Add("HUDPaint","CourseHUD",CourseHUD)

local function StartFreeze(ply, cmd)
	cmd:ClearButtons()
	cmd:ClearMovement()
	cmd:SetMouseX(0)
	cmd:SetMouseY(0)
end

function SaveCheckpointTime()
	local times = util.TableToJSON(cptimes)
	local dir = "beatrun/times/"..game.GetMap().."/"
	
	file.CreateDir(dir)
	file.Write(dir..Course_ID..".txt", times)
end
function LoadCheckpointTime()
	local dir = "beatrun/times/"..game.GetMap().."/"
	local times = file.Read(dir..Course_ID..".txt")
	if times then
		times = util.JSONToTable(times)
	end
	
	return times or nil
end

function SaveReplayData()
	local replay = util.TableToJSON(LocalPlayer().ReplayTicks)
	local dir = "beatrun/replays/"..game.GetMap().."/"
	
	file.CreateDir(dir)
	file.Write(dir..Course_ID..".txt", util.Compress(replay))
end
function LoadReplayData()
	local dir = "beatrun/replays/"..game.GetMap().."/"
	local replay = file.Read(dir..Course_ID..".txt")
	if replay then
		replay = util.JSONToTable(util.Decompress(replay))
	end
	
	return replay or nil
end

function StartCourse(spawntime)
	table.Empty(cptimes)
	pbtimes = LoadCheckpointTime()
	pbtotal = 0
	if pbtimes then
		for k,v in pairs(pbtimes) do
			pbtotal = pbtotal+v
		end
	end
	CheckpointNumber = 1
	countdown = 0
	countdownalpha = 255
	Course_GoTime = spawntime
	Course_StartTime = spawntime + 2
	lastcptime = Course_StartTime
	if Course_Name != "" then
		hook.Add("Think", "StartCountdown", StartCountdown)
		hook.Add("HUDPaint","StartCountdownHUD",StartCountdownHUD)
		hook.Add("StartCommand", "StartFreeze", StartFreeze)
		if !LocalPlayer().InReplay then
			ReplayStop(LocalPlayer())
			ReplayStart(LocalPlayer())
		end
	else
		hook.Remove("Think", "StartCountdown")
		hook.Remove("HUDPaint", "StartCountdownHUD")
		hook.Remove("StartCommand", "StartFreeze")
	end
end

net.Receive("BeatrunSpawn", function()
	local spawntime = net.ReadFloat()
	local replay = net.ReadBool()
	hook.Run("BeatrunSpawn")
	LocalPlayer().InReplay = replay
	StartCourse(spawntime)
end)