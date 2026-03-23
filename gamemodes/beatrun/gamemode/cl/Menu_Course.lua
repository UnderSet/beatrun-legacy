local coursepanel = {}
coursepanel.w = 1200
coursepanel.h = 650
coursepanel.x = 1920*0.5 - coursepanel.w*0.5
coursepanel.y = 1080*0.5 - coursepanel.h*0.5

coursepanel.bgcolor = Color(32,32,32)
coursepanel.outlinecolor = Color(54,55,56)
coursepanel.alpha = 0.9
coursepanel.elements = {}

local function closebutton(self)
	AEUI:Clear()
end

AEUI:AddText(coursepanel, "Time Trials - "..game.GetMap(), "AEUIVeryLarge", 20, 30)
AEUI:AddButton(coursepanel, "  X  ", closebutton, "AEUILarge", coursepanel.w-47, 0)
local courselist = {}
courselist.w = 800
courselist.h = 450
courselist.x = 1920*0.51 - coursepanel.w*0.5
courselist.y = 1080*0.6 - coursepanel.h*0.5

courselist.bgcolor = Color(32,32,32)
courselist.outlinecolor = Color(54,55,56)
courselist.alpha = 0.9
courselist.elements = {}


function OpenCourseMenu(ply)
	AEUI:AddPanel(coursepanel)
	AEUI:AddPanel(courselist)
	local dir = "beatrun/courses/"..game.GetMap().."/"
	local dirsearch = dir.."*.txt"
	local files = file.Find(dirsearch,"DATA","datedesc")
	PrintTable(files)
	table.Empty(courselist.elements)
	for k,v in pairs(files) do
		local data = file.Read(dir..v, "DATA")
		data = util.Decompress(data)
		if data then
			data = util.JSONToTable(data)
			local courseentry = AEUI:AddText(courselist, (data[5] or "ERROR"), "AEUILarge", 10, 40 * #courselist.elements)
			courseentry.courseid = v:Split(".txt")[1]
			courseentry.onclick = function(self) LocalPlayer():EmitSound("A_TT_CP_Positive.wav") LoadCourse(self.courseid) end
		end
	end
end

hook.Add("InitPostEntity", "CourseMenuCommand", function()
	concommand.Add("Beatrun_CourseMenu", OpenCourseMenu)
	hook.Remove("InitPostEntity", "CourseMenuCommand")
end)
concommand.Add("Beatrun_CourseMenu", OpenCourseMenu)
-- timer.Simple(0, function() OpenCourseMenu() end)