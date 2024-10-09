include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    -- Dessiner les informations au-dessus de la machine à laver
    local pos = self:GetPos() + Vector(0, 0, 50) -- Position au-dessus de la machine à laver
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    local itemStock = self:GetNWInt("ItemStock", 0) -- Récupère le stock d'entités
    local washingEndTime = self:GetNWFloat("WashingEndTime", 0) -- Récupère le temps de lavage restant
    local timeRemaining = math.max(0, washingEndTime - CurTime())

    cam.Start3D2D(pos, ang, 0.1)
        -- Afficher le nombre d'entités en stock
        draw.SimpleText("Stock: " .. itemStock, "DermaLarge", 0, -30, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Si le lavage est en cours, afficher le temps restant
        if timeRemaining > 0 then
            draw.SimpleText("Temps restant: " .. math.ceil(timeRemaining) .. "s", "DermaLarge", 0, 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end
