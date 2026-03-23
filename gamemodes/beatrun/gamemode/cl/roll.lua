local roll = {
["AnimString"] = "rollanim",
["animmodelstring"] = "mirroranim",
["lockang"] = true,
["followplayer"] = true,
}
net.Receive("ME_RollAnim", function()
	if net.ReadBool() then
		roll.AnimString = "fallhurt"
	else
		roll.AnimString = "rollanim"
	end
	StartBodyAnim(roll)
end)