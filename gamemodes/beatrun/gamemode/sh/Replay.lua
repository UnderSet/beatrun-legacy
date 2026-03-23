function ReplayCmd(ply, mv, cmd)
	if !cmd then cmd = mv end
	if cmd:TickCount() == 0 then return end
	if !ply.ReplayFirstTick and cmd:TickCount() != 0 then
		ply.ReplayFirstTick = cmd:TickCount()
	end
	
	ply.ReplayTicks[cmd:TickCount()-ply.ReplayFirstTick+1] = {cmd:GetButtons(), cmd:GetViewAngles(), cmd:GetForwardMove(), cmd:GetSideMove()}
end

function ReplayStart(ply)
	if ply.InReplay then return end
	print("Starting Replay")
	ply.ReplayTicks = {}
	ply.ReplayFirstTick = false
	ply.ReplayStartPos = ply:GetPos()
	local hookname = (game.SinglePlayer() and "StartCommand") or "SetupMove"
	hook.Add(hookname, "ReplayStart", ReplayCmd)
end

function ReplayStop(ply, debugdump)
	if ply.InReplay then return end
	-- print("Ending Replay ("..#ply.ReplayTicks.."ticks)")
	hook.Remove("SetupMove", "ReplayStart")
	ply.InReplay = false
	net.Start("ReplayRequest")
	net.WriteBool(true)
	net.SendToServer()
	
	if debugdump then
		local debugdata = {ply.ReplayStartPos, LocalPlayer().ReplayTicks}
		local replay = util.TableToJSON(debugdata)
		local dir = "beatrun/replays/"..game.GetMap().."/"

		file.CreateDir(dir)
		file.Write(dir.."replaydump.txt", replay)
	end
end

local tickcount = 0
function ReplayStartCommand(ply, cmd)
	if tickcount > 10 and game.SinglePlayer() and gui.IsGameUIVisible() then --Shit desyncs omegahard when you pause
		ReplayCancel(ply)
		print("Replay cancelled: SP menu")
		return
	end

	local cmdtc = cmd:TickCount()
	if cmdtc == 0 then return end
	if !ply.ReplayFirstTick and cmdtc != 0 then
		ply.ReplayFirstTick = cmdtc
	end
	if ply.ReplayTicks[cmdtc-ply.ReplayFirstTick+1] then
		tickcount = cmdtc-ply.ReplayFirstTick+1
		if ply.ReplayEndAtTick and tickcount >= ply.ReplayEndAtTick then
			ply.ReplayTicks = {}
			return
		end
		local tickdata = ply.ReplayTicks[tickcount]
		cmd:SetButtons(tickdata[1])
		cmd:SetViewAngles(tickdata[2])
		cmd:SetForwardMove(tickdata[3])
		cmd:SetSideMove(tickdata[4])

		cmd:RemoveKey(IN_RELOAD)
	elseif cmdtc-ply.ReplayFirstTick+1 > 0 then
		-- print("Replay cancelled: nil tick at "..cmdtc-ply.ReplayFirstTick+1)
		hook.Remove("StartCommand","ReplayPlay")
		hook.Remove("RenderScreenspaceEffects", "BeatrunReplayVision")
		hook.Remove("HUDPaint", "BeatrunReplayHUD")
		ply.InReplay = false
		ply.ReplayFirstTick = false
		net.Start("ReplayRequest")
		net.WriteBool(true)
		net.SendToServer()
		
		if TUTORIALMODE then
			net.Start("ReplayTutorialPos")
			net.WriteVector(ply.ReplayStartPos)
			net.SendToServer()
			TutorialClearEvents()
		end
	end
end

function ReplayPlay(ply, replaytbl, replaystartpos)
	RemoveBodyAnim()
	ply.ReplayTicks = replaytbl or LoadReplayData()
	if ply.ReplayTicks and (ply:GetVelocity():Length() == 0 or TUTORIALMODE) then
		tickcount = 0
		surface.PlaySound("friends/friend_join.wav")
		ply.ReplayFirstTick = false
		net.Start("ReplayRequest")
		net.WriteBool(false)
		if replaystartpos then
			ply.ReplayStartPos = replaystartpos
			net.WriteVector(replaystartpos)
		end
		net.SendToServer()
	end
end

if CLIENT then
	local tab = {
		[ "$pp_colour_addr" ] = 0/255,
		[ "$pp_colour_addg" ] = 0.5799,
		[ "$pp_colour_addb" ] = 1.12,
		[ "$pp_colour_brightness" ] = -0.57,
		[ "$pp_colour_contrast" ] = 0.9,
		[ "$pp_colour_colour" ] = 0.14,
		[ "$pp_colour_mulr" ] = 0,
		[ "$pp_colour_mulg" ] = 0,
		[ "$pp_colour_mulb" ] = 0
	}
	local function BeatrunReplayVision()
		if LocalPlayer().ReplayFirstTick then
			DrawColorModify( tab )
		end
	end
	local rcol = Color(200,200,200)
	local function BeatrunReplayHUD()
		if LocalPlayer().ReplayTicks and !LocalPlayer().ReplayTicks["reliable"] then
			surface.SetFont("BeatrunHUD")
			surface.SetTextColor(rcol)
			surface.SetTextPos(5, ScrH()*0.975)
			local text = (TUTORIALMODE and "") or "*Clientside replay: may not be accurate "
			surface.DrawText(text..tickcount.."/"..#LocalPlayer().ReplayTicks)
		end
	end
	
	
	function ReplayBegin()
		LocalPlayer().InReplay = true
		hook.Add("StartCommand","ReplayPlay", ReplayStartCommand)
		hook.Add("RenderScreenspaceEffects", "BeatrunReplayVision", BeatrunReplayVision)
		hook.Add("HUDPaint", "BeatrunReplayHUD", BeatrunReplayHUD)
	end
	
	net.Receive("ReplayRequest", ReplayBegin)
end

function ReplayCancel(ply)
	hook.Remove("StartCommand","ReplayPlay")
	hook.Remove("RenderScreenspaceEffects", "BeatrunReplayVision")
	hook.Remove("HUDPaint", "BeatrunReplayHUD")
	ply.InReplay = false
	ply.ReplayFirstTick = false
	net.Start("ReplayRequest")
	net.WriteBool(true)
	net.SendToServer()
end