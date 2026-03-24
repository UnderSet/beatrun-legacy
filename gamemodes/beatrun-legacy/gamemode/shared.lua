STAR = "★"
VERSIONGLOBAL = "v1.01"
DeriveGamemode( "sandbox" )
GM.Name 	= "Beatrun"
GM.Author 	= "datae"
GM.Email 	= "datae@dontemailme.com"
GM.Website 	= "www.garrysmod.com"
include( 'player_class/player_beatrun.lua' )

for k,v in ipairs(file.Find("beatrun-legacy/gamemode/sh/*.lua", "LUA")) do
	AddCSLuaFile("sh/"..v)
	include("sh/"..v)
end