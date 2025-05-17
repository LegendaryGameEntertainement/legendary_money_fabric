AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/PlasticCrate01a.mdl") -- modèle temporaire visible
    self:SetMaterial("models/debug/debugwhite") -- matériau neutre

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
        phys:EnableMotion(false)
    end

    if not self.ZoneName then self.ZoneName = "unknown" end
end

function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    net.Start("Zone_OpenMenu")
        net.WriteString(self.ZoneName or "unknown")
    net.Send(ply)
end

function ENT:SetZoneName(name)
    self.ZoneName = name
    self:SetNWString("ZoneName", name)
end
