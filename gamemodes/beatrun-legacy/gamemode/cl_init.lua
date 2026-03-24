-- require("beatrun")
include("shared.lua")
for k, v in ipairs(file.Find("beatrun-legacy/gamemode/cl/*.lua", "LUA")) do
    print(v)
    include("cl/" .. v)
end