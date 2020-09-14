Atom.Bhopvar = 	Atom.AddConvar("Atom_Bhop", "1")
function Atom.Bhop(c)
	if not Atom.Bhopvar:GetBool() then return end
	if c:KeyDown(IN_JUMP) and LocalPlayer():GetMoveType() != MOVETYPE_NOCLIP then
		local setter = c:GetButtons()
		if !LocalPlayer():IsOnGround() then
			setter = bit.band(setter, bit.bnot(IN_JUMP))
		end
		c:SetButtons(setter)
	end
end

function Atom.CreateMove(c)
	Atom.Bhop(c)
end
Atom.AddHook("CreateMove", Atom.CreateMove)