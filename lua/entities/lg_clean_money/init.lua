AddCSLuaFile("shared.lua");
include("shared.lua");

function ENT:Initialize()
    self:SetModel("models/props/cs_assault/moneypallet.mdl");
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)	
	self:SetUseType(SIMPLE_USE)
	local phys = self:GetPhysicsObject()
	phys:Wake()
end;