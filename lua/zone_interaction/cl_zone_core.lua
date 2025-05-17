include("zone_interaction/sh_zone_config.lua")

net.Receive("Zone_OpenMenu", function()
    local frame = vgui.Create("DFrame")
    frame:SetSize(300, 150)
    frame:Center()
    frame:SetTitle("Zone d'interaction")
    frame:MakePopup()

    local label = vgui.Create("DLabel", frame)
    label:SetText("Vous êtes dans une zone spéciale !")
    label:Dock(TOP)
    label:SetContentAlignment(5)

    local button = vgui.Create("DButton", frame)
    button:SetText("Fermer")
    button:Dock(BOTTOM)
    button.DoClick = function() frame:Close() end
end)

hook.Add("PostDrawTranslucentRenderables", "Zone_DrawVisual", function()
    for _, zone in pairs(ZONE.Data) do
        render.SetColorMaterial()
        render.DrawSphere(zone.pos, zone.radius, 30, 30, Color(0, 255, 0, 100))
    end
end)
