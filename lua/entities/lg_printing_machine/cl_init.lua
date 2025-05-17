include("shared.lua")


function ENT:Draw()
    self:DrawModel()

    -- Dessiner le compteur de papier au-dessus de la machine
    local pos = self:GetPos() + Vector(0, 0, 50) -- Position au-dessus de l'entité
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    local paperStock = self:GetNWInt("PaperStock", 0) -- Récupère le stock de papier
    local productionEndTime = self:GetNWFloat("ProductionEndTime", 0) -- Récupère le temps de production restant
    local timeRemaining = math.max(0, productionEndTime - CurTime())

    cam.Start3D2D(pos, ang, 0.1)
        -- Afficher le nombre de papiers
        draw.SimpleText("Papiers: " .. paperStock, "DermaLarge", 0, -30, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Si la production est en cours, afficher le temps restant
        if timeRemaining > 0 then
            draw.SimpleText("Temps restant: " .. math.ceil(timeRemaining) .. "s", "DermaLarge", 0, 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end
