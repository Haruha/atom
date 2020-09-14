require("stringtable") 

local escapejs = { 
	["\\"] = "\\\\",
	["\0"] = "\\0" , 
	["\b"] = "\\b" , 
	["\t"] = "\\t" , 
	["\n"] = "\\n" , 
	["\v"] = "\\v" , 
	["\f"] = "\\f" , 
	["\r"] = "\\r" , 
	["\""] = "\\\"", 
	["\'"] = "\\\'" 
}

function string.JavascriptSafe(str)
	str = str:gsub(".", escapejs) 
	str = str:gsub("\226\128\168", "\\\226\128\168") 
	str = str:gsub("\226\128\169", "\\\226\128\169") 
	
	return str 
end 

local function GetLuaFiles(client_lua_files) 
	local count = client_lua_files:Count() 
	local ret = {} 

	for i = 1, count - 2 do 
	ret[i] = { Path = client_lua_files:GetString(i), CRC = client_lua_files:GetUserDataInt(i) }
	end 

	return ret 
end 

local function GetLuaFileContents(crc) 
	local fs = file.Open("cache/lua/" .. crc .. ".lua", "rb", "MOD") 

	fs:Seek(4) 

	local contents = util.Decompress(fs:Read(fs:Size() - 4)) 

	return contents:sub(1, -2) 
end 

local function dumbFile(path, contents) 
	if not    path:match("%.txt$") then
	path = path..".txt"
	end 
	
	local curdir = "" 
	
	for t in path:gmatch("[^/\\*]+") do 
	curdir = curdir..t 
	
	if curdir:match("%.txt$") then 
		print("writing: ", curdir) file.Write(curdir, contents)
	else 
		curdir = curdir.."/" 
		print("Creating: ", curdir) 
		file.CreateDir(curdir) 
	end 
	end 
end 

local dumbFolderCache = "" 
local function dumbFolder(node) 
	for _, subnode in ipairs(node.ChildNodes:GetChildren()) do
	if subnode:HasChildren() then 
		dumbFolder(subnode) 
	else 
		dumbFile(dumbFolderCache..subnode.pathh, GetLuaFileContents(subnode.CRC))
	end 
	end 
end

local VIEWER = {}

surface.CreateFont("HeaderFont", {
	font = "Segoe UI Semilight",
	size = 22, 
	weight = 300
})
surface.CreateFont("PopupFont", {
	font = "Segoe UI Light",
	size = 21, 
	weight = 300
})

function VIEWER:Init()
	self:SetTitle("arie - troubleshooter")
	self:SetSize(ScrW()-200, ScrH()-200)
	self:Center()
	self:ShowCloseButton(false) 
	self.Paint = function(s,w,h)
		surface.SetDrawColor(Color(31, 31, 31))
		surface.DrawRect(0, 0, w, h) 
		surface.SetDrawColor(Color(51, 51, 51)) 
		surface.DrawRect(1, 1, w-2, h-2)
		surface.SetDrawColor(Color(41, 41, 41)) 
		surface.DrawRect(2, 2, w-4, h-4) 
		surface.SetDrawColor(Color(51, 51, 51)) 
		surface.DrawRect(7.5, 27.5, w-14, h-34) 
		surface.SetTextColor(240, 240, 240) 
		surface.SetFont("HeaderFont")
		surface.SetTextPos((self:GetWide()/2) - (tostring(string.len(self.lblTitle:GetText())) / 2*7.5), 2) 
		self.lblTitle:SetColor(Color(240, 240, 240, 0)) 
		surface.DrawText(self.lblTitle:GetText()) 
	end 
	
	self.close = vgui.Create("DButton", self) 
	self.close:SetSize(43,20) 
	self.close:SetPos(self:GetWide()-7.5-self.close:GetWide(), -1) 
	self.close:SetText("") 
	self.close.Paint = function(s,w,h) 
		surface.SetDrawColor(Color(51, 51, 51)) 
		surface.DrawRect(0,0, w,h) 
		surface.SetTextColor(255,255,255) 
		surface.SetFont("HeaderFont") 
		surface.SetTextPos(18,-2) 
		surface.DrawText("x") 
	end 
	self.close.DoClick = function(s,w,h) 
		self:Close()
	end 

	self.tree = vgui.Create("DTree", self) 
	self.tree:SetPos(8.5,28.5) 
	self.tree:SetSize(self:GetWide()/2-200, self:GetTall()-36) 
	self.tree.Directories = {} 

	local ScrollBar = self.tree:GetVBar()
	ScrollBar.Paint = function()
		draw.RoundedBox(0, 0, 0, ScrollBar:GetWide(), ScrollBar:GetTall(), Color(75, 75, 75))
	end
	ScrollBar.btnUp.Paint = function()
		draw.RoundedBox(0, 0, 0, ScrollBar:GetWide(), ScrollBar.btnUp:GetTall(), Color(30, 30, 30))
	end
	ScrollBar.btnDown.Paint = function()
		draw.RoundedBox(0, 0, 0, ScrollBar:GetWide(), ScrollBar.btnDown:GetTall(), Color(30, 30, 30))
	end
	ScrollBar.btnGrip.Paint = function()
		draw.RoundedBox(0, 0, 0, ScrollBar.btnGrip:GetWide(), ScrollBar.btnGrip:GetTall(),Color(30, 30, 30))
	end

	self.html = vgui.Create("DHTML", self) 
	self.html:SetPos(self:GetWide()/2-200+8.5, 28.5) 
	self.html:SetSize(self:GetWide()/2+200-16, self:GetTall()-36) 
	self.html:OpenURL("https://metastruct.github.io/lua_editor/") 
	client_lua_files = stringtable.Get "client_lua_files" 
	local tree_data= {} 
	for i, v in ipairs(GetLuaFiles(client_lua_files)) do
		if i == 1 then continue 
	end 
	local file_name = string.match(v.Path, ".*/([^/]+%.lua)") 
	local dir_path = string.sub(v.Path, 1, -1 - file_name:len()) 
	local file_crc = v.CRC 
	local cur_dir = tree_data 
	for dir in string.gmatch(dir_path, "([^/]+)/") do
		if not cur_dir[dir] then 
			cur_dir[dir] = {} 
		end 
	 	cur_dir = cur_dir[dir] 
	end 
		cur_dir[file_name] = {fileN = file_name, CRC = file_crc} 
	end 

	local file_queue = {} 
	local function iterate(data, node, path) 
		path = path or "" 
		for k, v in SortedPairs(data) do 
			if type(v) == "table" and not v.CRC then 
				local new_node = node:AddNode(k, "snaggle/folder62.png") 
				new_node.DoRightClick = function()
					local dmenu = DermaMenu(new_node) 
					dmenu:SetPos(gui.MouseX(), gui.MouseY()) 
					dmenu:AddOption("Save Folder", function() 
						dumbFolderCache = "cluaview/"..GetHostName()..dumbFolder(new_node)
						DrawFancyPopup("The folder ".. dumbFolder(new_node) .." has been saved as data/cluaview/".. GetHostName() .."/folders/".. dumbFolder(new_node) .."!")
					end)
					dmenu:Open()
				end 
				iterate(v, new_node, path .. k .. "/") 
			else 
				table.insert(file_queue, {node = node, fileN = v.fileN, path = path .. v.fileN, CRC = v.CRC}) 
			end 
		end 
	end 
	iterate(tree_data, self.tree) 

	for k, v in ipairs(file_queue) do 
		local node = v.node:AddNode(v.fileN, "snaggle/file.png") 

		node.DoClick = function() 
			self.html:QueueJavascript("SetContent('"..string.JavascriptSafe(GetLuaFileContents(v.CRC)).."')") 
		end 

		local hostname = GetHostName()
		hostname = hostname:gsub("|", "-") 
		hostname = hostname:gsub("~", "-") 
		hostname = hostname:gsub(" ", "") 

		node.DoRightClick = function(self,node) 
			local nodemenu = DermaMenu(node)
			nodemenu:AddOption("Save File", function() 
				dumbFile("cluaview/".. string.lower(hostname) .."/"..v.fileN, GetLuaFileContents(v.CRC)) 
				DrawFancyPopup("The file ".. v.fileN .." has been saved as data/cluaview/".. string.lower(hostname) .."/".. v.fileN .."!") 
			end) 
			nodemenu:AddOption("Run file", function() 
				RunString(GetLuaFileContents(v.CRC))
			end)
			nodemenu:Open() 
		end 

		node.CRC = v.CRC 
		node.pathh = v.path
	end
end 

derma.DefineControl("dcluaviewer", "Clientside Lua Viewer", VIEWER, "DFrame")

function DrawFancyPopup(message)
	fancyPopup = vgui.Create("DFrame")
	fancyPopup:SetSize(ScrW(), ScrH()) 
	fancyPopup:SetPos(0, 0) 
	fancyPopup:SetVisible(true) 
	fancyPopup:SetTitle("") 
	fancyPopup:MakePopup() 
	fancyPopup:ShowCloseButton(true) 
	fancyPopup.Paint = function(s, w, h) 
		surface.SetDrawColor(Color(0, 0, 0, 200)) 
		surface.DrawRect(0,0, w, h) 
		surface.SetDrawColor(Color(13, 136, 69)) 
		surface.DrawRect(0, w/2-fancyPopup:GetTall()/1.520, ScrW(), ScrH()/6.5) 
		surface.SetTextColor(255, 255, 255) 
		surface.SetFont("PopupFont") 
		surface.SetTextPos(w/4.10, h/2.30) 
		surface.DrawText(message)
	end 
	
	fancyPopupButton = vgui.Create("DButton", fancyPopup) 
	fancyPopupButton:SetSize(110, 32.5) 
	fancyPopupButton:SetPos(fancyPopup:GetWide()/2+fancyPopup:GetWide()/10, fancyPopup:GetTall()/2.050) 
	fancyPopupButton:SetText("") 
	fancyPopupButton.Paint = function(s,w,h) 
		surface.SetDrawColor(Color(255, 255, 255)) 
		surface.DrawRect(0,0, w, h) 
		surface.SetDrawColor(Color(13, 136, 69)) 
		surface.DrawRect(0+3, 0+3, w-6, h-6) 
		surface.SetTextColor(255, 255, 255) 
		surface.SetFont("PopupFont") 
		surface.SetTextPos(30.5, 5.5) 
		surface.DrawText("Alright!") 
	end 
	fancyPopupButton.DoClick = function(s, w, h) 
		fancyPopup:Close() 
	end
end

concommand.Add("atom_cslua", function() 
	vgui.Create("dcluaviewer"):MakePopup() 
end)