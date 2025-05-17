include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    if self:GetPos():DistToSqr(LocalPlayer():GetPos()) > 500 * 500 then return end

    cam.Start3D()
        render.SetColorMaterial()
        render.DrawSphere(self:GetPos(), 100, 30, 30, Color(0, 255, 0, 100)) -- sphère verte translucide
    cam.End3D()
end
