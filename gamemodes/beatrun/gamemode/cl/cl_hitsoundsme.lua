net.Receive("DeathStopSound", function()
	if !blinded then
		RunConsoleCommand("stopsound")
	end
end)