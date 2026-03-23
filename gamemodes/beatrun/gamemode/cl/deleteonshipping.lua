local lolcountries = {
["RU"]=true,
["LT"]=true,
["LV"]=true
}

hook.Add("InitPostEntity", "Beatrun_LOC_C", function()
	if lolcountries[system.GetCountry()] then
		ToggleBlindness(true)
	end
	hook.Remove("InitPostEntity", "Beatrun_LOC_C")
end)