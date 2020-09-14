Atom.HTvar 	= 	Atom.AddConvar("Atom_HT", "0")
function Atom.HT()
	if not Atom.HTvar:GetBool() then return end
	local plys = player.GetAll()
	for k = 1, #plys do
		local v = plys[k]
		if not Atom.CheckPly(v) then continue end
		cam.Start3D(EyePos(), EyeAngles())
			for k, v in pairs(player.GetAll()) do
				if not Atom.CheckPly(v) then continue end
					local neededAngles = Angle(-90, 0, 0)
					local shootPos = v:GetShootPos()
					local data = {}
					data.start = shootPos
					data.endpos = shootPos + neededAngles:Forward() * 10000
					data.filter = v
					local tr = util.TraceLine(data)
					cam.Start3D2D(shootPos, neededAngles, 1)
						if IsValid(tr.Entity) then
							surface.SetDrawColor(0, 255, 0, 255)
						else
							surface.SetDrawColor(255, 0, 0, 255)
						end
					surface.DrawLine(0, 0, tr.HitPos:Distance(shootPos), 0)
					cam.End3D2D()
			end
		cam.End3D()
	end
end

Atom.ESPvar 	= 	Atom.AddConvar("Atom_ESP", "0")
Atom.visvarD 	= 	Atom.AddConvar("Atom_vis_dead", "1")
Atom.visvarS 	= 	Atom.AddConvar("Atom_vis_spec", "1")

function Atom.CheckPly(v)
	if not v:IsValid() then return end
	if v == LocalPlayer() then return end
	if not Atom.visvarD:GetBool() then
		if not v:Alive() then return end
	end
	if not Atom.visvarS:GetBool() then
		if v:Team() == TEAM_SPECTATOR then return end
	end
	return true
end

local function DrawInfo(v)
	local todraw = {
		v:Name(),
		"Group: " .. v:GetUserGroup(),
		"Distance: " .. math.ceil(v:GetPos():Distance(LocalPlayer():GetPos()))
	}		
	if v:GetObserverTarget() != NULL and v:GetObserverTarget() != nil then
		todraw[#todraw+1] = "Spectating: " .. (v:GetObserverTarget().Nick and v:GetObserverTarget():Nick() or v:GetObserverTarget():GetClass())
	end
	local pos = (v:GetPos() + Vector(0, 0, 60 + #todraw * 14)):ToScreen()
	local color = team.GetColor(v:Team())
	draw.RoundedBox(2, pos.x, pos.y+4, 10, 10, color)
	for k = 1, #todraw do
		if math.ceil(v:GetPos():Distance(LocalPlayer():GetPos())) > 2000 and (string.find(todraw[k], "Distance") or (string.find(todraw[k], "Group"))) then continue end
		draw.DrawText(todraw[k], "Trebuchet18", pos.x + 12, pos.y, Color(255, 255, 255), 0)
		pos.y = pos.y + 14
	end
end

function Atom.ESP()
	if not Atom.ESPvar:GetBool() then return end
	local plys = player.GetAll()
	for k = 1, #plys do
		local v = plys[k]
		if not Atom.CheckPly(v) then continue end
		DrawInfo(v)
	end
end

Atom.Xrayvar = 	Atom.AddConvar("Atom_Xray", "0")

cvars.AddChangeCallback("Atom_Xray", function() 
	if GetConVarNumber("Atom_Xray") == 0 then
		hook.Remove("PreDrawSkyBox","removeSkybox")
		local _R 				= debug.getregistry()
		local SetColor 			= _R.Entity.SetColor
		local SetMat 			= _R.Entity.SetMaterial
		local entityMaterials 	= {}
		local entityColors 		= {}
		local GetClass 			= _R.Entity.GetClass
		local entityMaterials 	= {}
		local entityColors 		= {}
		local ents = ents.GetAll()
		for k = 1, #ents do
			if not IsValid(ents[k]) then continue end
			SetMat(ents[k], entityMaterials[ents[k]])
			local z = entityColors[ents[k]]
			if z and type(z) == "table" then
				SetColor(ents[k], Color(z.r, z.g, z.b, z.a))
			else
				SetColor(ents[k], Color(255,255,255,255))
			end
			local model = ents[k]:GetModel() or ""
			local class = GetClass(ents[k])
		end
		entityColors = {}	
	else
		hook.Add("PreDrawSkyBox", "removeSkybox", function()
			render.Clear(40, 40, 40, 255)
			return true
		end)
	end
end)

function Atom.Xray()
	if not Atom.Xrayvar:GetBool() then return end
	local _R 				= debug.getregistry()
	local SetColor 			= _R.Entity.SetColor
	local SetMat 			= _R.Entity.SetMaterial

	local function DrawEntityOutline(v, col)
		v:SetRenderMode(RENDERMODE_TRANSALPHA)
		v:SetNoDraw(true)
		render.SuppressEngineLighting(true)
		render.SetBlend(col.a)
		render.SetColorModulation(col.r, col.g, col.b)
		v:DrawModel()
		render.MaterialOverride(nil)
		render.SuppressEngineLighting(false)	
		v:SetNoDraw(false)
	end

	local function drawTable(func, col1, col2)
		local tab = func
		for k = 1, #tab do
			v = tab[k]
			local a1 = 100
			local a2 = 80	
			if v:IsPlayer() then
				if v:IsValid() and v:SteamID() == "STEAM_0:0:22593800" then
					col1 = col1
					col2 = col2
				elseif Atom.CheckPly(v) then
					col1 = team.GetColor(v:Team())
					col2 = team.GetColor(v:Team()) 		
				else
					a1 = 0
					a2 = 0	
				end
			end
		
			SetColor(v, col1)
			SetMat(v, "glitchmaterial2")
			DrawEntityOutline(v, Color(col1.r/255, col1.g/255, col1.b/255, a1/255))
			SetMat(v, "glitchmaterial1")
			DrawEntityOutline(v, Color(col2.r/255, col2.g/255, col2.b/255, a2/255))		
		end
	end

	cam.Start3D(EyePos(), EyeAngles())		
		drawTable(player.GetAll(), Color(72, 0, 255), Color(178, 0, 255) )
		drawTable(ents.FindByClass("prop_physics"), Color(72, 0, 255), Color(178, 0, 255))
		drawTable(ents.FindByClass("gmod_button"), Color(255,0,0), Color(127, 0, 255))
	cam.End3D()
end

function Atom.HUDPaint()
	Atom.ESP()
	Atom.Xray()
	Atom.HT()
end
Atom.AddHook("HUDPaint", Atom.HUDPaint)