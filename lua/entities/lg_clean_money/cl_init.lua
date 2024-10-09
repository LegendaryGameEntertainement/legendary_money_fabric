include("shared.lua")

-- Remplace cette fonction avec celle-ci
function ENT:Draw()
    self:DrawModel()

    -- Vérifie la position de l'entité et prépare le dessin 3D
    local pos = self:GetPos() + Vector(0, 0, 60) -- On ajuste la hauteur de l'icône au-dessus de l'entité
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
        -- On dessine l'icône ici, par exemple un carré blanc ou une image
        surface.SetDrawColor(255, 255, 255, 255) -- Blanc
        surface.SetMaterial(Material("icon16/money.png")) -- Remplace par le chemin de l'icône que tu veux utiliser
        surface.DrawTexturedRect(-16, -16, 64, 64) -- Taille de l'icône
    cam.End3D2D()
end
