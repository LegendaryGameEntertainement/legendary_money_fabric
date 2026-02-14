include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos() + Vector(0, 0, 85)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    local distance = LocalPlayer():GetPos():Distance(self:GetPos())
    if distance > 500 then return end
    
    cam.Start3D2D(pos, ang, 0.1)
        draw.SimpleText("💵 Vendeur d'Argent Sale", "DermaLarge", 0, -40, Color(255, 100, 100), TEXT_ALIGN_CENTER)
        draw.SimpleText("Apportez de l'argent propre", "DermaDefault", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
