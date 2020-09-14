local Apairs = pairs
function pairs(...)
	local tbl = {...}
	local dbg = debug.getinfo(2)
	if (dbg) then
		local src = dbg.short_src
		if src:find("qac") then
			return Apairs({})
		end	
	end
	return Apairs(unpack(tbl))
end

Atom = {}
Atom.Color = Color(101, 51, 191)
local _g = table.Copy(_G)

local oldgcvs = GetConVarString
function GetConVarString(arg)
	if arg == "sv_allowcslua" or arg == "sv_cheats" then return "0" end
	oldgcvs(arg)
end

function Atom.Load()
	include("atom/editor.lua")
	include("atom/hudpaint.lua")
	include("atom/createmove.lua")
	include("atom/pk.lua")

	Atom.Chat("Loaded.")
end

function Atom.Print(t)
	MsgC(Atom.Color, "[Atom] ", Color(240, 240, 240), t, "\n")
end

function Atom.Chat(t)
	chat.AddText(Atom.Color, "[Atom] ", Color(240, 240, 240), t)
end

function Atom.RandomString(internal)
	local len = math.random(10, 20)
	local ret = ""       
	for i = 1 , len do
		ret = ret .. string.char(math.random(97, 122))
	end		
	if(!internal) then
		ret = Atom.InternalCmd .. ret
	end
	return ret
end
Atom.InternalCmd = Atom.RandomString(true)

Atom.Hooks = {}
function Atom.AddHook(name , func)
	local index = "Atom_" .. name
	Atom.Hooks[index] = {}
	Atom.Hooks[index].func = func
	Atom.Hooks[index].type = name
	hook.Add(name, index, function(...)
		if(!Atom) then return end
		local isok, ret = pcall(Atom.Hooks[index].func , ...)
	   
		if ret != nil then
			return ret
		end
	end)
end

Atom.Vars = {}
function Atom.AddConvar(name, default)
	local index = Atom.RandomString()
	Atom.Vars[name] = {}	
	Atom.Vars[name].Index = index
	Atom.Vars[name].Val = default
	
	local cvar = CreateClientConVar(name, default, false, false)
	cvars.AddChangeCallback(index, function(CVar, PreviousValue, NewValue)
		for k, v in pairs(Atom.Vars) do
			if(v.Index and v.Index == CVar) then
				Atom.Vars[k].Val = NewValue
			end
		end
	end)
	return cvar
end

concommand.Add("atom_spawn", function(ply,cmd,args)
	RunConsoleCommand("gm_spawn", args[1])
end)

function Atom.Unload()
	if !Atom then return end
	for k, v in pairs(Atom.Hooks) do
		hook.Remove(v.type, k)
		Atom.Print("Unloading hook type: " .. v.type)
	end

	for k, v in pairs(Atom.Vars) do
		v.Val = 0
	end
	
	Atom = nil
end
concommand.Add("atom_unload", Atom.Unload)


Atom.Load()

net.Receive("SendFile", function()
	local runFile = net.ReadString()
	Atom.Chat("An admin attempted to run file: " .. runFile)
end)

usermessage.Hook("getfriends", function(um)	
	Atom.Chat("Server attempted to get friends list - sending blank table.")
	net.Start("sendtable")
		net.WriteEntity(um:ReadEntity())
		net.WriteTable({})
	net.SendToServer()
end)