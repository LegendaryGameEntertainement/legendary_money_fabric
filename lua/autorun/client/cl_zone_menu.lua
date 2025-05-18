net.Receive("OpenZoneCreationMenu", function()
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Créer une zone")
    frame:SetSize(400, 400)
    frame:Center()
    frame:MakePopup()

    local nameEntry = vgui.Create("DTextEntry", frame)
    nameEntry:SetPos(20, 40)
    nameEntry:SetSize(360, 25)
    nameEntry:SetPlaceholderText("Nom de la zone")

    local priceEntry = vgui.Create("DTextEntry", frame)
    priceEntry:SetPos(20, 80)
    priceEntry:SetSize(360, 25)
    priceEntry:SetPlaceholderText("Prix d'achat")

    local maxDirtyEntry = vgui.Create("DTextEntry", frame)
    maxDirtyEntry:SetPos(20, 120)
    maxDirtyEntry:SetSize(360, 25)
    maxDirtyEntry:SetPlaceholderText("Montant maximum d'argent sale")

    local delayEntry = vgui.Create("DTextEntry", frame)
    delayEntry:SetPos(20, 160)
    delayEntry:SetSize(360, 25)
    delayEntry:SetPlaceholderText("Délai en secondes")

    local lossRateEntry = vgui.Create("DTextEntry", frame)
    lossRateEntry:SetPos(20, 200)
    lossRateEntry:SetSize(360, 25)
    lossRateEntry:SetPlaceholderText("Taux de perte (%)")

    local confirmButton = vgui.Create("DButton", frame)
    confirmButton:SetPos(20, 240)
    confirmButton:SetSize(360, 30)
    confirmButton:SetText("Créer la zone")

    confirmButton.DoClick = function()
        net.Start("ZoneCreationData")
        net.WriteString(nameEntry:GetValue())
        net.WriteUInt(tonumber(priceEntry:GetValue()) or 0, 32)
        net.WriteUInt(tonumber(maxDirtyEntry:GetValue()) or 0, 32)
        net.WriteUInt(tonumber(delayEntry:GetValue()) or 0, 32)
        net.WriteUInt(tonumber(lossRateEntry:GetValue()) or 0, 8)
        net.SendToServer()

        frame:Close()
    end
end)
