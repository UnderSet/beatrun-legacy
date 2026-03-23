-- buildmode_props = {
-- "models/hunter/blocks/cube3x3x025.mdl",
-- "models/hunter/blocks/cube8x8x05.mdl",
-- "models/hunter/blocks/cube2x2x2.mdl",
-- "models/hunter/blocks/cube8x8x025.mdl",
-- "models/hunter/blocks/cube8x8x4.mdl",
-- "models/hunter/blocks/cube1x6x025.mdl",
-- "models/props_c17/fence01b.mdl",
-- "models/props_c17/fence01a.mdl",
-- "models/props_c17/fence03a.mdl"
-- }
buildmode_props = {}
local propmatsblacklist = {
}

local blocksdir = "models/hunter/blocks/"
local blocksdir_s = blocksdir.."*.mdl"
for k,v in ipairs(file.Find(blocksdir_s, "GAME")) do
	table.insert(buildmode_props, blocksdir..v:lower())
end

local blocksdir = "models/hunter/triangles/"
local blocksdir_s = blocksdir.."*.mdl"
for k,v in ipairs(file.Find(blocksdir_s, "GAME")) do
	table.insert(buildmode_props, blocksdir..v:lower())
end

local blocksdir = "models/props_phx/construct/glass/"
local blocksdir_s = blocksdir.."*.mdl"
for k,v in ipairs(file.Find(blocksdir_s, "GAME")) do
	local key = table.insert(buildmode_props, blocksdir..v:lower())
	propmatsblacklist[key] = true
end

local misc = {
"models/hunter/misc/lift2x2.mdl",
"models/hunter/misc/stair1x1.mdl",
"models/hunter/misc/stair1x1inside.mdl",
"models/hunter/misc/stair1x1outside.mdl",
"models/props_combine/combine_barricade_short02a.mdl",
"models/props_combine/combine_bridge_b.mdl",
"models/props_docks/channelmarker_gib02.mdl",
"models/props_docks/channelmarker_gib04.mdl",
"models/props_docks/channelmarker_gib03.mdl",
"models/props_lab/blastdoor001a.mdl",
"models/props_lab/blastdoor001c.mdl",
"models/props_wasteland/cargo_container01.mdl",
"models/props_wasteland/cargo_container01b.mdl",
"models/props_wasteland/cargo_container01c.mdl",
"models/props_wasteland/horizontalcoolingtank04.mdl",
"models/props_wasteland/laundry_washer001a.mdl",
"models/props_wasteland/laundry_washer003.mdl",
"models/props_junk/TrashDumpster01a.mdl",
"models/props_junk/TrashDumpster02.mdl",
"models/props_junk/wood_crate001a.mdl",
"models/props_junk/wood_crate002a.mdl",
"models/props_junk/wood_pallet001a.mdl",
"models/props_c17/fence01a.mdl",
"models/props_c17/fence01b.mdl",
"models/props_c17/fence02a.mdl",
"models/props_c17/fence03a.mdl",
"models/props_c17/fence04a.mdl",
"models/props_wasteland/interior_fence001g.mdl",
"models/props_wasteland/interior_fence002d.mdl",
"models/props_wasteland/interior_fence002e.mdl",
"models/props_building_details/Storefront_Template001a_Bars.mdl",
"models/props_wasteland/wood_fence01a.mdl",
"models/props_wasteland/wood_fence02a.mdl",
"models/props_c17/concrete_barrier001a.mdl",
"models/props_wasteland/medbridge_base01.mdl",
"models/props_wasteland/medbridge_post01.mdl",
"models/props_wasteland/medbridge_strut01.mdl",
"models/props_c17/column02a.mdl",
"models/props_junk/iBeam01a_cluster01.mdl",
"models/props_junk/iBeam01a.mdl",
"models/props_canal/canal_cap001.mdl",
"models/props_canal/canal_bridge04.mdl",
"models/Mechanics/gears2/pinion_80t3.mdl",
"models/props_phx/gears/rack36.mdl",
"models/props_phx/gears/rack70.mdl",
"models/cranes/crane_frame.mdl",
"models/cranes/crane_docks.mdl",
"models/props_wasteland/cranemagnet01a.mdl",
-- "models/gantry_crane/crane_rotator.mdl",

}
for k,v in ipairs(misc) do
	local key = table.insert(buildmode_props, v:lower())
	propmatsblacklist[key] = true
end
misc = nil

local buildmode_ents = {
["br_swingbar"] = true,
["tt_cp"] = true,
}

local buildmode_props_index = {}
for k,v in pairs(buildmode_props) do
	buildmode_props_index[v] = k
end

local function CustomPropMat(prop)
	if propmatsblacklist[buildmode_props_index[prop:GetModel()]] then return end
	if prop.hr then
	prop:SetMaterial("medge/redplainplastervertex")
	else
	prop:SetMaterial("medge/plainplastervertex")
	end
end

Course_StartPos = Course_StartPos or Vector()
Course_StartAng = Course_StartAng or 0

if SERVER then
util.AddNetworkString("BuildMode")
util.AddNetworkString("BuildMode_Place")
util.AddNetworkString("BuildMode_Remove")
util.AddNetworkString("BuildMode_Drag")
util.AddNetworkString("BuildMode_Duplicate")
util.AddNetworkString("BuildMode_Delete")
util.AddNetworkString("BuildMode_Highlight")
util.AddNetworkString("BuildMode_ReadSave")
util.AddNetworkString("BuildMode_Checkpoint")
util.AddNetworkString("BuildMode_Entity")
util.AddNetworkString("BuildMode_SetSpawn")

util.AddNetworkString("BuildMode_SaveCourse")
util.AddNetworkString("BuildMode_ReadCourse")
util.AddNetworkString("BuildMode_Sync")
buildmodelogs = {}
local buildmodelogs = buildmodelogs

function Course_Sync()
	net.Start("BuildMode_Sync")
	net.WriteFloat(Course_StartPos.x)
	net.WriteFloat(Course_StartPos.y)
	net.WriteFloat(Course_StartPos.z)
	net.WriteFloat(Course_StartAng)
	net.WriteString(Course_Name)
	net.WriteString(Course_ID)
	net.Broadcast()
end

function Course_Stop()
	Course_Name = ""
	Course_ID = ""
	game.CleanUpMap()
	Course_Sync()
end

buildmode_placed = buildmode_placed or {}
function BuildMode_Toggle(ply)
	if !ply.BuildMode and !ply:IsSuperAdmin() and !ply.BuildModePerm then return end
	ply.BuildMode = !ply.BuildMode
	if ply.BuildMode then
		ply:SetMoveType(MOVETYPE_NOCLIP)
	else
		ply:SetMoveType(MOVETYPE_WALK)
		CheckpointNumber = 1
	end
	net.Start("BuildMode")
	net.WriteBool(ply.BuildMode)
	net.Send(ply)
end

concommand.Add("buildmode", function( ply, cmd, args )
	BuildMode_Toggle(ply)
end)

net.Receive("BuildMode_Place", function(len, ply)
	if !ply.BuildMode then return end
	local prop = net.ReadUInt(16)
	local x = net.ReadFloat()
	local y = net.ReadFloat()
	local z = net.ReadFloat()
	
	local ang = net.ReadAngle()
	local vec = Vector(x,y,z)
	
	local a = ents.Create("prop_physics")
	a:SetModel(buildmode_props[prop])
	CustomPropMat(a)
	a:SetPos(vec)
	a:SetAngles(ang)
	a:Spawn()
	
	local phys = a:GetPhysicsObject()
	phys:EnableMotion(false)
	phys:Sleep()
	a:PhysicsDestroy()
	a:SetHealth(1/0)
	table.insert(buildmode_placed, a)

	local bmlog = tostring(ply).." placed "..tostring(a)
	table.insert(buildmodelogs, bmlog)
end)

net.Receive("BuildMode_Duplicate", function(len, ply)
	if !ply.BuildMode then return end
	local selected = net.ReadTable()
	local selectedents = net.ReadTable()
	for k,v in pairs(selected) do
		local a = ents.Create("prop_physics")
		a:SetModel(v:GetModel())
		CustomPropMat(a)
		a:SetPos(v:GetPos())
		a:SetAngles(v:GetAngles())
		a:Spawn()
		
		a.hr = v.hr
		CustomPropMat(a)
		
		local phys = a:GetPhysicsObject()
		phys:EnableMotion(false)
		phys:Sleep()
		a:PhysicsDestroy()
		a:SetHealth(1/0)
	end
	
	for k,v in pairs(selectedents) do
		local a = ents.Create(v:GetClass())
		a:SetPos(v:GetPos())
		a:SetAngles(v:GetAngles())
		a:Spawn()
	end
	
	local bmlog = tostring(ply).." duped "..tostring(table.Count(selected)).." props"
	table.insert(buildmodelogs, bmlog)
end)

net.Receive("BuildMode_Delete", function(len, ply)
	if !ply.BuildMode then return end
	local selected = net.ReadTable()
	for k,v in pairs(selected) do
		if IsValid(v) then
			v:Remove()
		end
	end
	local bmlog = tostring(ply).." deleted "..tostring(table.Count(selected)).." entities"
	table.insert(buildmodelogs, bmlog)
end)

net.Receive("BuildMode_Highlight", function(len, ply)
	if !ply.BuildMode then return end
	local selected = net.ReadTable()
	for k,v in pairs(selected) do
		v.hr = !v.hr
		CustomPropMat(v)
	end
end)

net.Receive("BuildMode_Remove", function(len, ply)
	if !ply.BuildMode then return end
	local ent = net.ReadEntity()
	SafeRemoveEntity(ent)
end)

net.Receive("BuildMode_ReadSave", function(len, ply)
	if !ply.BuildMode then return end
	local a = util.Decompress(net.ReadData(len))
	local props = util.JSONToTable(a)
	for k,v in pairs(props) do
		local a = ents.Create("prop_physics")
		print(buildmode_props[v.model], v.model)
		a:SetModel(buildmode_props[v.model])
		CustomPropMat(a)
		a:SetPos(v.pos+ply:EyePos())
		a:SetAngles(v.ang)
		a:Spawn()
		
		local phys = a:GetPhysicsObject()
		phys:EnableMotion(false)
		phys:Sleep()
		a:PhysicsDestroy()
		a:SetHealth(1/0)
	end
end)

net.Receive("BuildMode_Checkpoint", function(len, ply)
	if !ply.BuildMode then return end
	local x = net.ReadFloat()
	local y = net.ReadFloat()
	local z = net.ReadFloat()
	
	LoadCheckpoints()
	PrintTable(Checkpoints)
	local a = ents.Create("tt_cp")

	a:SetPos(Vector(x, y, z))
	a:SetCPNum(table.Count(Checkpoints)+1)
	a:Spawn()
	
	LoadCheckpoints()
end)

net.Receive("BuildMode_Entity", function(len, ply)
	if !ply.BuildMode then return end
	local ent = net.ReadString()
	local x = net.ReadFloat()
	local y = net.ReadFloat()
	local z = net.ReadFloat()
	
	local a = ents.Create(ent)

	a:SetPos(Vector(x, y, z))
	a:Spawn()
end)

net.Receive("BuildMode_SetSpawn", function(len, ply)
	if !ply.BuildMode then return end
	local x = net.ReadFloat()
	local y = net.ReadFloat()
	local z = net.ReadFloat()
	local ang = net.ReadFloat()
	
	Course_StartPos:SetUnpacked(x,y,z)
	Course_StartAng = ang
end)

function Beatrun_ReadCourseNet(len, ply)
	if !ply:IsSuperAdmin() then return end
	Beatrun_ReadCourse(net.ReadData(len))
end
	
function Beatrun_ReadCourseLocal(id)
	local dir = "beatrun/courses/"..game.GetMap().."/"
	local save = file.Read(dir..id..".txt","DATA")
	if !save then print("NON-EXISTENT SAVE",id) return end
	
	Course_ID = id
	Beatrun_ReadCourse(save)
end


function Beatrun_ReadCourse(data)
	game.CleanUpMap()
	local a = util.Decompress(data)
	local crc = util.CRC(a)
	local data = util.JSONToTable(a)
	PrintTable(data)
	local props = data[1]
	local cp = data[2]
	local pos = data[3]
	local ang = data[4]
	local name = data[5]
	local entities = data[6]
	
	for k,v in pairs(props) do
		local a = ents.Create("prop_physics")
		a.hr = v.hr
		a:SetModel(buildmode_props[v.model])
		CustomPropMat(a)
		a:SetPos(v.pos)
		a:SetAngles(v.ang)
		a:Spawn()
		
		local phys = a:GetPhysicsObject()
		phys:EnableMotion(false)
		phys:Sleep()
		a:PhysicsDestroy()
		a:SetHealth(1/0)
	end
	
	for k,v in ipairs(cp) do
		LoadCheckpoints()
		local a = ents.Create("tt_cp")
	
		a:SetPos(v)
		a:SetCPNum(table.Count(Checkpoints)+1)
		a:Spawn()
		
		LoadCheckpoints()
		print(k,v,a)
	end
	
	if entities then
		for k,v in ipairs(entities) do
			local a = ents.Create(v.ent)
			a:SetPos(v.pos)
			a:SetAngles(v.ang)
			a:Spawn()
		end
	end
	
	Course_StartPos:Set(pos)
	Course_StartAng = ang
	Course_Name = name
	Course_ID = crc
	Course_Sync()
	
	for k,v in pairs(player.GetAll()) do
		v:SetNW2Float("PBTime",0)
		v:SetNW2Int("CPNum",1)
		v:SetMoveType(MOVETYPE_WALK)
		v:Spawn()
	end
end

net.Receive("BuildMode_ReadCourse", Beatrun_ReadCourseNet)

net.Receive("BuildMode_Drag", function(len, ply)
	if !ply.BuildMode then return end
	local selected = net.ReadTable()
	for k,v in pairs(selected) do
		k:SetPos(v.pos or k:GetPos())
		k:SetAngles(v.ang or k:GetAngles())
	end
end)


else


BuildMode = false
GhostModel = nil
BuildModeIndex = 0
local GhostColor = Color(255,255,255,200)
BuildModeAngle = Angle()
BuildModePos = Vector()
local BuildModeDist = 500
local usedown = false
local mousedown = false
local axislock = 0 --none, x, y, z
local axislist = {"x", "y", "z"}
local axiscolors = {
Color(255,0,0),
Color(0,255,0),
Color(0,0,255)
}
local axisdisplay1 = Vector()
local axisdisplay2 = Vector()

local mousex, mousey = 0, 0
local mousemoved = false
local camcontrol = false
local scrw, scrh = ScrW(), ScrH()
local nscrw, nscrh = ScrW(), ScrH()

local aimvector = Vector()

local dragstartx, dragstarty = 0, 0
local dragstartvec = Vector()
local dragging = false
local dragoffset = Vector()
local hulltr, hulltrout = {}, {}
buildmode_placed = buildmode_placed or {}
buildmode_selected={}

local keytime = 0

playerstart = (IsValid(playerstart) and playerstart) or ClientsideModel("models/editor/playerstart.mdl")
playerstart:SetNoDraw(true)
local playerstartang = Angle()

surface.CreateFont( "BuildMode", {
	font = "D-DIN", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = ScreenScale( 10 ),
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

local blur = Material("pp/blurscreen")
local function DrawBlurRect(x, y, w, h)
	local X, Y = 0,0

	surface.SetDrawColor(255,255,255)
	surface.SetMaterial(blur)

	for i = 1, 5 do
		blur:SetFloat("$blur", (i / 3) * (5))
		blur:Recompute()

		render.UpdateScreenEffectTexture()

		render.SetScissorRect(x, y, x+w, y+h, true)
			surface.DrawTexturedRect(X * -1, Y * -1, scrw, scrh)
		render.SetScissorRect(0, 0, 0, 0, false)
	end
   
end

function BuildModeCreateGhost()
	if !IsValid(GhostModel) then
		GhostModel = ClientsideModel(buildmode_props[BuildModeIndex], RENDERGROUP_TRANSLUCENT)
	else
		if propmatsblacklist[BuildModeIndex] then
			GhostModel:SetMaterial("")
		end
		return
	end
	GhostModel:SetColor(GhostColor)
	GhostModel:SetRenderMode( RENDERMODE_TRANSCOLOR )
	GhostModel:SetNoDraw(true)
	CustomPropMat(GhostModel)
end

local trace = {}
local tracer = {}
local flatn = Angle(0,0,1)
function BuildModeGhost()
	if BuildModeIndex == 0 then return end
	if AEUI.HoveredPanel then return end
	BuildModeCreateGhost()
	local ply = LocalPlayer()
	local eyepos = ply:EyePos()
	local eyeang = ply:EyeAngles()
	local mins, maxs = GhostModel:GetRenderBounds()
	
	aimvector = util.AimVector(eyeang, 120+13, mousex, mousey, ScrW(), ScrH())
	
	trace.start = eyepos
	trace.endpos = eyepos + aimvector*100000
	trace.filter = ply
	trace.output = tracer
	util.TraceLine(trace)
	
	local ghostpos = tracer.HitPos
	ghostpos.z = ghostpos.z - (mins.z)
	if axislock > 0 then
		BuildModePos[axislist[axislock]] = ghostpos[axislist[axislock]]
	else
		BuildModePos:Set(ghostpos)
	end
	GhostModel:SetPos(BuildModePos)
	GhostModel:SetAngles(BuildModeAngle)
	GhostModel:DrawModel()
	
	render.DrawWireframeBox(BuildModePos, BuildModeAngle, mins, maxs, color_white, true)
	
	if axislock > 0 then
		axisdisplay1:Set(BuildModePos)
		local num = axisdisplay1[axislist[axislock]]
		axisdisplay1[axislist[axislock]] = num + 200
		
		axisdisplay2:Set(BuildModePos)
		axisdisplay2[axislist[axislock]] = num - 200
		render.DrawLine(axisdisplay2, axisdisplay1, axiscolors[axislock])
	end
	ghostpos.z = ghostpos.z + (mins.z)
	render.DrawLine(tracer.StartPos+eyeang:Forward()*5, ghostpos, axiscolors[3])
end

function BuildModePlayerStart()
	playerstartang.y = Course_StartAng
	playerstart:SetPos(Course_StartPos)
	playerstart:SetAngles(playerstartang)
	
	playerstart:DrawModel()
end

function SaveCourse(name)
	local save = {}
	save[1] = {}
	save[2] = {}
	save[3] = Course_StartPos
	save[4] = Course_StartAng
	save[5] = name or "Unnamed"
	save[6] = {}
	for k,v in pairs(buildmode_placed) do
		if !IsValid(v) then continue end
		if v:GetNW2Bool("BRProtected") then print("ignoring protected ent") continue end
		local class = v:GetClass()
		if class=="prop_physics" and !buildmode_props_index[v:GetModel():lower()] then print("ignoring",v:GetModel():lower()) continue end
		if class=="prop_physics" then
			local hr = (v:GetMaterial() == "medge/redplainplastervertex" and true) or nil
			table.insert(save[1], {["model"]=buildmode_props_index[v:GetModel():lower()], ["pos"]=v:GetPos(), ["ang"]=v:GetAngles(), ["hr"]=hr})
		elseif buildmode_ents[class] then
			table.insert(save[6], {["ent"]=class, ["pos"]=v:GetPos(), ["ang"]=v:GetAngles()})
		end
	end
	for k,v in ipairs(Checkpoints) do
		table.insert(save[2], v:GetPos())
	end
	local jsonsave = util.TableToJSON(save)
	local crc = util.CRC(jsonsave)
	local dir = "beatrun/courses/"..game.GetMap().."/"
	file.CreateDir(dir)
	file.Write(dir..crc..".txt", util.Compress(jsonsave))
	
	print("Save created:",crc)
end
concommand.Add("Beatrun_SaveCourse", function(ply, cmd, args, argstr)
	local name = args[1] or "Unnamed"
	SaveCourse(name)
end)

function LoadCourse(id)
	local dir = "beatrun/courses/"..game.GetMap().."/"
	local save = file.Read(dir..id..".txt","DATA")
	if !save then print("NON-EXISTENT SAVE",id) return end
	net.Start("BuildMode_ReadCourse")
	net.WriteData(save)
	net.SendToServer()
	LoadCheckpoints()
	Course_ID = id
end
concommand.Add("Beatrun_LoadCourse", function(ply, cmd, args, argstr)
	local id = args[1] or "Unnamed"
	LoadCourse(id)
end)

concommand.Add("Beatrun_PrintCourse", function(ply, cmd, args, argstr)
	local dir = "beatrun/courses/"..game.GetMap().."/*.txt"
	local files = file.Find(dir,"DATA","datedesc")
	PrintTable(files)
end)

net.Receive("BuildMode_Sync", function()
	local x = net.ReadFloat()
	local y = net.ReadFloat()
	local z = net.ReadFloat()
	local ang = net.ReadFloat()
	local name = net.ReadString()
	local id = net.ReadString()
	
	Course_StartPos:SetUnpacked(x,y,z)
	Course_StartAng = ang
	Course_Name = name
	Course_ID = (id or Course_ID)
end)

buildmodeinputs = {
[KEY_R] = function()
	if !dragging then
		BuildModeAngle:Set(angle_zero)
		return
	end
	axislock = axislock + 1
	if axislock > 3 then
		axislock = 0
	end
end,
---------------#
[KEY_X] = function()
	local mult = (input.IsKeyDown(KEY_LCONTROL) and 1/15) or 1
	BuildModeAngle:RotateAroundAxis(Vector(1,0,0), 15*mult)
	LocalPlayer():EmitSound("buttonrollover.wav")
end,
---------------#
[KEY_C] = function()
	local mult = (input.IsKeyDown(KEY_LCONTROL) and 1/15) or 1
	BuildModeAngle:RotateAroundAxis(Vector(1,0,0), -15*mult)
	LocalPlayer():EmitSound("buttonrollover.wav")
end,
---------------#
[KEY_V] = function()
	local mult = (input.IsKeyDown(KEY_LCONTROL) and 1/15) or 1
	BuildModeAngle:RotateAroundAxis(Vector(0,1,0), 15*mult)
	LocalPlayer():EmitSound("buttonrollover.wav")
end,
---------------#
[KEY_B] = function()
	local mult = (input.IsKeyDown(KEY_LCONTROL) and 1/15) or 1
	BuildModeAngle:RotateAroundAxis(Vector(0,1,0), -15*mult)
	LocalPlayer():EmitSound("buttonrollover.wav")
end,
---------------#
[KEY_F] = function()
	local svec = util.AimVector(LocalPlayer():EyeAngles(), 120+13, mousex, mousey, ScrW(), ScrH())
	local start = LocalPlayer():EyePos()
	svec:Mul(100000)
	local tr = util.QuickTrace(start, svec, LocalPlayer())
	local pos = tr.HitPos
	net.Start("BuildMode_Checkpoint")
	net.WriteFloat(pos.x)
	net.WriteFloat(pos.y)
	net.WriteFloat(pos.z)
	net.SendToServer()
	timer.Simple(0.1, function() LoadCheckpoints() end)
end,
---------------#
[KEY_H] = function()
	local svec = util.AimVector(LocalPlayer():EyeAngles(), 120+13, mousex, mousey, ScrW(), ScrH())
	local start = LocalPlayer():EyePos()
	svec:Mul(100000)
	local tr = util.QuickTrace(start, svec, LocalPlayer())
	local pos = tr.HitPos
	net.Start("BuildMode_Entity")
	net.WriteString("br_swingbar")
	net.WriteFloat(pos.x)
	net.WriteFloat(pos.y)
	net.WriteFloat(pos.z)
	net.SendToServer()
end,
---------------#
[KEY_S] = function()
	if camcontrol then return end
	local svec = util.AimVector(LocalPlayer():EyeAngles(), 120+13, mousex, mousey, ScrW(), ScrH())
	local start = LocalPlayer():EyePos()
	svec:Mul(100000)
	local tr = util.QuickTrace(start, svec, LocalPlayer())
	local pos = tr.HitPos
	local ang = LocalPlayer():EyeAngles().y
	Course_StartPos:Set(pos)
	net.Start("BuildMode_SetSpawn")
	net.WriteFloat(pos.x)
	net.WriteFloat(pos.y)
	net.WriteFloat(pos.z)
	net.WriteFloat(ang)
	net.SendToServer()
	Course_StartPos:Set(pos)
	Course_StartAng = ang
end,
---------------#
[KEY_D] = function(ignorecombo)
	if (input.IsKeyDown(KEY_LSHIFT) or ignorecombo) and !camcontrol then
		local props = {}
		local ents = {}
		for k,v in pairs(buildmode_selected) do
			if buildmode_ents[k:GetClass()] then
				table.insert(ents, k)
			else
				table.insert(props, k)
			end
		end
		net.Start("BuildMode_Duplicate")
		net.WriteTable(props)
		net.WriteTable(ents)
		net.SendToServer()
		dragging = false
		buildmodeinputs[KEY_G]()
	end
end,
---------------#
[KEY_DELETE] = function()
	if !dragging then
		local props = {}
		for k,v in pairs(buildmode_selected) do
			table.insert(props, k)
			buildmode_selected[k] = nil
		end
		net.Start("BuildMode_Delete")
		net.WriteTable(props)
		net.SendToServer()
	end
end,
---------------#
[KEY_BACKSPACE] = function()
	if !dragging then
		local props = {}
		for k,v in pairs(buildmode_selected) do
			table.insert(props, k)
			buildmode_selected[k] = nil
		end
		net.Start("BuildMode_Delete")
		net.WriteTable(props)
		net.SendToServer()
	end
end,
---------------#
[KEY_T] = function()
	if !dragging then
		local props = {}
		for k,v in pairs(buildmode_selected) do
			if !propmatsblacklist[buildmode_props_index[k:GetModel()]] then
				table.insert(props, k)
			end
		end
		if #props > 0 then
			net.Start("BuildMode_Highlight")
			net.WriteTable(props)
			net.SendToServer()
		end
	end
end,
---------------#
[KEY_G] = function()
	if BuildModeIndex != 0 then return end
	BuildModeAngle:Set(angle_zero)
	dragging = !dragging
	if !dragging then
		dragging = true
		dragoffset:Set(vector_origin)
		buildmodeinputsmouse[MOUSE_RIGHT]()
	else
		local f
		for k,v in pairs(buildmode_selected) do
			f = k
			break
		end
		if IsValid(f) then
			local w2s = f:GetPos():ToScreen()
			input.SetCursorPos(w2s.x, w2s.y)
		end
	end
end,
---------------#
[KEY_ENTER] = function()
	if table.Count(buildmode_selected) == 0 then return end
	local save = {}
	local startpos
	for k,v in pairs(buildmode_selected) do
		if !startpos then startpos = k:GetPos() end
		if !buildmode_props_index[k:GetModel()] then print("ignoring",k:GetModel()) continue end
		table.insert(save, {["model"]=buildmode_props_index[k:GetModel()], ["pos"]=k:GetPos()-startpos, ["ang"]=k:GetAngles()})
	end
	local jsonsave = util.TableToJSON(save)
	file.CreateDir("beatrun/savedbuilds")
	file.Write("beatrun/savedbuilds/save.txt", util.Compress(jsonsave))
end,
---------------#
[KEY_PAD_PLUS] = function()
	local save = file.Read("beatrun/savedbuilds/save.txt","DATA")
	net.Start("BuildMode_ReadSave")
	net.WriteData(save)
	net.SendToServer()
end,
---------------#
[KEY_PAD_0] = function()
	-- SaveCourse()
end,
---------------#
[KEY_PAD_1] = function()
	-- local dir = "beatrun/courses/"..game.GetMap().."/"
	-- local save = file.Read(dir.."1.txt","DATA")
	-- net.Start("BuildMode_ReadCourse")
	-- net.WriteData(save)
	-- net.SendToServer()
	-- timer.Simple(0.1, function() LoadCheckpoints() end)
end,
---------------#
-- ["+attack"] = function()
	-- net.Start("BuildMode_Place")
	-- net.WriteUInt(BuildModeIndex, 4)
	-- net.WriteFloat(BuildModePos.x)
	-- net.WriteFloat(BuildModePos.y)
	-- net.WriteFloat(BuildModePos.z)
	-- net.WriteAngle(BuildModeAngle)
	-- net.SendToServer()
-- end,
---------------#
-- ["+attack2"] = function(pressed)
-- end,
---------------#
-- ["+duck"] = function()

-- end

}
buildmodeinputsmouse = {
[MOUSE_LEFT] = function()
	if BuildModeIndex > 0 then
		net.Start("BuildMode_Place")
		net.WriteUInt(BuildModeIndex, 16)
		net.WriteFloat(BuildModePos.x)
		net.WriteFloat(BuildModePos.y)
		net.WriteFloat(BuildModePos.z)
		net.WriteAngle(BuildModeAngle)
		net.SendToServer()
		LocalPlayer():EmitSound("buttonclick.wav")
	end
	if dragging then
		local selected = {}
		dragging = false
		if table.Count(buildmode_selected) > 0 then
			for k,v in pairs(buildmode_selected) do
				if IsValid(k) then
					selected[k] = {["pos"]=k:GetRenderOrigin(),["ang"]=k:GetRenderAngles()}
				end
				-- buildmode_selected[k] = nil
				k.dragorigpos = k:GetPos()
				k.dragorigang = k:GetAngles()
			end
			net.Start("BuildMode_Drag")
			net.WriteTable(selected)
			net.SendToServer()
		end
		axislock = 0
		LocalPlayer():EmitSound("buttonclick.wav")
		-- BuildModeAngle:Set(angle_zero)
		return
	end
	
	if BuildModeIndex == 0 then
		local svec = util.AimVector(LocalPlayer():EyeAngles(), 120+13, mousex, mousey, ScrW(), ScrH())
		local start = LocalPlayer():EyePos()
		svec:Mul(100000)
		local tr = util.QuickTrace(start, svec, LocalPlayer())
		if !input.IsKeyDown(KEY_LSHIFT) then
			table.Empty(buildmode_selected)
		end
		if IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_physics" then
			buildmode_selected[tr.Entity] = !buildmode_selected[tr.Entity]
			if buildmode_selected[tr.Entity] == false then
				buildmode_selected[tr.Entity] = nil
			end
			tr.Entity.dragorigpos = tr.Entity:GetPos()
			tr.Entity.dragorigang = tr.Entity:GetAngles()
		end
	end
end,
[MOUSE_RIGHT] = function()
	if dragging and table.Count(buildmode_selected) > 0 then
		for k,v in pairs(buildmode_selected) do
			if IsValid(k) then
				k:SetRenderOrigin(k.dragorigpos)
				k:SetRenderAngles(k.dragorigang)
			end
			buildmode_selected[k] = nil
		end
		dragging = false
		axislock = 0
		-- BuildModeAngle:Set(angle_zero)
	end
end,

[MOUSE_WHEEL_DOWN] = function()
	if !usedown then
		-- BuildModeDist = math.Clamp(BuildModeDist-20, 20, 1000)
		BuildModeAngle:RotateAroundAxis(Vector(0,0,1), -15)
		LocalPlayer():EmitSound("buttonrollover.wav")
	else
		BuildModeIndex = BuildModeIndex-1
		if BuildModeIndex < 0 then
			BuildModeIndex = #buildmode_props
		end
		if BuildModeIndex == 0 then SafeRemoveEntity(GhostModel) return end
		BuildModeCreateGhost()
		GhostModel:SetModel(buildmode_props[BuildModeIndex])
	end
end,
[MOUSE_WHEEL_UP] = function()
	if !usedown then
		-- BuildModeDist = math.Clamp(BuildModeDist+20, 20, 1000)
		BuildModeAngle:RotateAroundAxis(Vector(0,0,1), 15)
		LocalPlayer():EmitSound("buttonrollover.wav")
	else
		BuildModeIndex = BuildModeIndex+1
		if BuildModeIndex > #buildmode_props then
			BuildModeIndex = 0
		end
		if BuildModeIndex == 0 then SafeRemoveEntity(GhostModel) return end
		BuildModeCreateGhost()
		GhostModel:SetModel(buildmode_props[BuildModeIndex])
	end
end,
}

function BuildModeInput(ply, bind, pressed, code)
	if bind!="buildmode" and !camcontrol then
		return true
	end
end

hook.Add("OnEntityCreated","BuildModeProps",function(ent)
	if !ent:GetNW2Bool("BRProtected") and ent:GetClass() == "prop_physics" or buildmode_ents[ent:GetClass()] then
		table.insert(buildmode_placed, ent)
	end
end)

local dragorigin = nil
function BuildModeDrag()
	if !mousedown then
		dragstartx, dragstarty = mousex, mousey
	elseif math.abs(dragstartx-mousex) > 5 and !dragging then
		local w, h = mousex-dragstartx, mousey-dragstarty
		local x, y = dragstartx, dragstarty
		local flipx, flipy = false, false
		if w < 0 then
			w = -w
			x = x-w
			flipx = true
		end
		if h < 0 then
			h = -h
			y = y-h
			flipy = true
		end
		surface.SetDrawColor(50,125,255, 80)
		surface.DrawRect(x, y, w, h)
		surface.SetDrawColor(125,125,125, 125)
		surface.DrawOutlinedRect(x, y, w, h)
		surface.SetDrawColor(0,200,0, 255)
		for k,v in ipairs(buildmode_placed) do
			if IsValid(v) and !v:GetNW2Bool("BRProtected") then
				local pos = (v:GetRenderOrigin() or v:GetPos())
				local w2s = pos:ToScreen()
				local xcheck = (flipx and (w2s.x > x and w2s.x < w+x)) or (!flipx and (w2s.x > x and w2s.x < mousex))
				local ycheck = (flipy and (w2s.y > y and w2s.y < h+y)) or (!flipy and (w2s.y > y and w2s.y < mousey))
				if xcheck and ycheck then
					buildmode_selected[v] = true
				elseif !input.IsKeyDown(KEY_LSHIFT) then
					buildmode_selected[v] = nil
				end
			end
		end
		
		if !dragging then
			dragorigin = nil
			for k,v in pairs(buildmode_selected) do
				if IsValid(k) then
					k.dragorigpos = k:GetPos()
					k.dragorigang = k:GetAngles()
				end
			end
		end
	end
	

end

function BuildModeSelect()
	if dragging then
		local svec = util.AimVector(LocalPlayer():EyeAngles(), 120+13, mousex, mousey, ScrW(), ScrH())
		dragoffset:Set(svec)
		if !dragorigin then
			dragorigin = dragoffset
		end
	end
	local f
	for k,v in pairs(buildmode_selected) do
		if !f then f = k end
		if !IsValid(k) then
			buildmode_selected[k] = nil
			continue
		end
		if v then
			if dragging then
				local newpos = LocalPlayer():EyePos() + (dragoffset*f.dragorigpos:Distance(LocalPlayer():EyePos()))-dragorigin
				local offset = k.dragorigpos + (newpos - f.dragorigpos)-dragorigin
				if axislock > 0 then local a = offset[axislist[axislock]] offset:Set(k.dragorigpos) offset[axislist[axislock]] = a end
				k:SetRenderOrigin( offset )
				k:SetRenderAngles( k.dragorigang+BuildModeAngle )
			end
			local mins, maxs = k:GetCollisionBounds()
			render.DrawWireframeBox((k:GetRenderOrigin() or k:GetPos()), k:GetAngles(), mins, maxs, color_white, true)
		end
	end
	
	if IsValid(f) and axislock > 0 then
		axisdisplay1:Set(f:GetPos())
		local num = axisdisplay1[axislist[axislock]]
		axisdisplay1[axislist[axislock]] = num + 200
		
		axisdisplay2:Set(f:GetPos())
		axisdisplay2[axislist[axislock]] = num - 200
		render.DrawLine(axisdisplay2, axisdisplay1, axiscolors[axislock])
	end
end

function BuildModeHUDPaint()
	BuildModeDrag()
	if dragging then
		surface.SetDrawColor(0,255,0)
		surface.DrawRect(0,0, 50, 50)
	end
	
	-- DrawBlurRect( 0, 0, scrw, scrh*0.07 )
	-- surface.SetDrawColor(25,25,25,150)
	-- surface.DrawRect( 0, 0, scrw, scrh*0.07 )
	-- surface.SetTextColor(255,255,255)
	-- surface.SetFont("BuildMode")
	-- local w, h = surface.GetTextSize("BUILD MODE")
	-- surface.SetTextPos(scrw*0.5-(w*0.5), h*0.75)
	-- surface.DrawText("BUILD MODE")
	
	-- surface.SetDrawColor(55,155,55,200)
	-- surface.DrawOutlinedRect( 0, 0, scrw, scrh*0.07 )
	surface.SetFont("DebugFixed")
	surface.SetTextColor(255,255,255)
	for k,v in pairs(Checkpoints) do
		if !IsValid(v) then
			LoadCheckpoints()
			break
		end
		local w2s = v:GetPos():ToScreen()
		local num = v:GetCPNum()
		surface.SetTextPos(w2s.x, w2s.y)
		surface.DrawText(num)
	end
	
	local startw2s = Course_StartPos:ToScreen()
	surface.SetTextPos(startw2s.x, startw2s.y)
	surface.DrawText("Spawn")
end

function BuildModeCommand(ply, ucmd)
	LocalPlayer():SetFOV(120)
	if gui.IsGameUIVisible() then return end
	camcontrol = input.IsMouseDown(MOUSE_RIGHT)
	local newx, newy = input.GetCursorPos()
	mousemoved = (mousex != newx) or (mousey != newy)
	mousex, mousey = newx, newy
	gui.EnableScreenClicker(!camcontrol)
	
	usedown = input.IsKeyDown(KEY_E)
	mousedown = input.IsMouseDown(MOUSE_LEFT)
	
	if AEUI.HoveredPanel then return end
	
	if keytime == CurTime() then return end
	for k,v in pairs(buildmodeinputs) do
		if input.WasKeyPressed(k) then
			v()
		end
	end
	for k,v in pairs(buildmodeinputsmouse) do
		if input.WasMousePressed(k) then
			v()
		end
	end
	
	keytime = CurTime()
end

function BuildModePreRender()
	-- nscrw, nscrh = scrw*0.95, scrh*0.95
	-- surface.DrawRect(0, 0, scrw, scrh)
	-- render.SetViewPort(scrw*0.025, scrh*0.025, nscrw, nscrh)
end


net.Receive("BuildMode", function()
	BuildMode = net.ReadBool()
	if BuildMode then
		hook.Add("PostDrawTranslucentRenderables", "BuildModeGhost", BuildModeGhost)
		hook.Add("PostDrawTranslucentRenderables", "BuildModeSelect", BuildModeSelect)
		hook.Add("PostDrawTranslucentRenderables", "BuildModePlayerStart", BuildModePlayerStart)
		
		hook.Add("PlayerBindPress", "BuildModeInput", BuildModeInput)
		hook.Add("StartCommand", "BuildModeCommand", BuildModeCommand)
		hook.Add("NeedsDepthPass", "BuildModePreRender", BuildModePreRender)
		hook.Add("HUDPaint", "BuildModeHUDPaint", BuildModeHUDPaint)
		LocalPlayer():DrawViewModel(false)
		LocalPlayer():SetFOV(120)
		hook.Run("BuildModeState",true)
	else
		hook.Remove("PostDrawTranslucentRenderables", "BuildModeGhost")
		hook.Remove("PostDrawTranslucentRenderables", "BuildModeSelect")
		hook.Remove("PostDrawTranslucentRenderables", "BuildModePlayerStart")
		hook.Remove("PlayerBindPress", "BuildModeInput")
		hook.Remove("StartCommand", "BuildModeCommand")
		hook.Remove("NeedsDepthPass", "BuildModePreRender")
		hook.Remove("HUDPaint", "BuildModeHUDPaint")
		SafeRemoveEntity(GhostModel)
		LocalPlayer():DrawViewModel(true)
		gui.EnableScreenClicker(false)
		LocalPlayer():SetFOV(0)
		CheckpointNumber = 1
		hook.Run("BuildModeState",false)
	end
end)


















end