include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    -- Position et orientation pour le texte 3D2D au-dessus de la machine
    local pos = self:GetPos() + Vector(0, 0, 50)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    local paperStock = self:GetNWInt("PaperStock", 0)
    local inkStock = self:GetNWInt("InkStock", 0)
    local productionEndTime = self:GetNWFloat("ProductionEndTime", 0)
    local timeRemaining = math.max(0, productionEndTime - CurTime())

    cam.Start3D2D(pos, ang, 0.1)
        -- Afficher le stock de papier
        draw.SimpleText("Papiers: " .. paperStock, "DermaLarge", 0, -40, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Afficher le stock d'encre en bleu clair
        draw.SimpleText("Encre: " .. inkStock, "DermaLarge", 0, -10, Color(100, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Afficher le temps restant si la production est active
        if timeRemaining > 0 then
            draw.SimpleText("Temps restant: " .. math.ceil(timeRemaining) .. "s", "DermaLarge", 0, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end
