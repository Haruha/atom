local function Atom.Boost()
	local a = LocalPlayer():EyeAngles() 
	LocalPlayer():SetEyeAngles(Angle(a.p-a.p-a.p, a.y-180, a.r))
	RunConsoleCommand("+jump")
timer.Simple(0.1, function() RunConsoleCommand("-jump") end)
end
concommand.Add("atom_180up", Atom.Boost)

local Headtracers = {}
Headtracers.toggle = true
Headtracers.Vars = {}
Headtracers.Vars["MaxDistance"] 	= CreateClientConVar("atom_headtrace_maxdistance", 2000, true, false) -- 2000 is standard for rp_downtown_v4c_v2
Headtracers.Vars["HeadtracersIdle"] = {}
Headtracers.Vars["HeadtracersIdle"].color = Color(255,0,0,255)
Headtracers.Vars["HeadtracersActive"] = {}
Headtracers.Vars["HeadtracersActive"].color = Color(0,255,0,255)

local function Atom.HeadTrace()

	if Headtracers.toggle == false then
		Headtracers.toggle = true
		hook.Remove("HUDPaint","HeadLines2")

	elseif Headtracers.toggle == true then
		Headtracers.toggle = false


		function HeadLines2()
		cam.Start3D(EyePos(), EyeAngles())
			for k,ply in pairs(player.GetAll()) do
				if ply != LocalPlayer() && ply:Alive() and ply:Team() != TEAM_SPECTATOR  and (ply:GetPos():Distance(LocalPlayer():GetPos()) < Headtracers.Vars["MaxDistance"]:GetInt()) then
					local neededAngles = Angle(-90, 0, 0)
					local shootPos = ply:GetShootPos()
					local data = {}
					data.start = shootPos
					data.endpos = shootPos + neededAngles:Forward() * 10000
					data.filter = ply
					local tr = util.TraceLine(data)
					local color
					cam.Start3D2D(shootPos, neededAngles, 1)
						if IsValid(tr.Entity) then
							color = Headtracers.Vars["HeadtracersActive"].color
							surface.SetDrawColor(color.r , color.g , color.b , color.a)
						else
							color = Headtracers.Vars["HeadtracersIdle"].color
							surface.SetDrawColor(color.r , color.g , color.b , color.a)
						end
					surface.DrawLine(0, 0, tr.HitPos:Distance(shootPos), 0)
					cam.End3D2D()
				end
			end
		cam.End3D()
		end
		hook.Add("HUDPaint", "HeadLines2", HeadLines2)
 	end
 end
concommand.Add("atom_headtrace", Atom.HeadTrace)