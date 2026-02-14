include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos() + Vector(0, 0, 30)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    local distance = LocalPlayer():GetPos():Distance(self:GetPos())
    if distance > 300 then return end
    
    local buildingName = self:GetNWString("BuildingName", "Zone de Blanchiment")
    local currentMoney = self:GetNWInt("CurrentMoney", 0)
    local isLaundering = self:GetNWBool("IsLaundering", false)
    local endTime = self:GetNWInt("LaunderEndTime", 0)
    
    cam.Start3D2D(pos, ang, 0.08)
        draw.SimpleText(buildingName, "DermaLarge", 0, -60, Color(255, 215, 0), TEXT_ALIGN_CENTER)
        
        if isLaundering then
            local timeLeft = math.max(0, endTime - CurTime())
            local minutes = math.floor(timeLeft / 60)
            local seconds = math.floor(timeLeft % 60)
            draw.SimpleText("Blanchiment en cours...", "DermaDefault", 0, -20, Color(255, 200, 0), TEXT_ALIGN_CENTER)
            draw.SimpleText(string.format("%02d:%02d", minutes, seconds), "DermaLarge", 0, 10, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        elseif currentMoney > 0 then
            draw.SimpleText("Argent blanchi disponible!", "DermaDefault", 0, -20, Color(100, 255, 100), TEXT_ALIGN_CENTER)
            draw.SimpleText(DarkRP.formatMoney(currentMoney), "DermaLarge", 0, 10, Color(100, 255, 100), TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("Appuyez sur E", "DermaDefault", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end

-- Interface de blanchiment
net.Receive("LG_OpenLaunderingZone", function()
    local zone = net.ReadEntity()
    local buildingID = net.ReadString()
    
    if not IsValid(zone) then return end
    
    local config = LegendaryMoneyFabric.Laundering
    local building = nil
    
    for _, b in ipairs(config.buildings) do
        if b.id == buildingID then
            building = b
            break
        end
    end
    
    if not building then return end
    
    local currentMoney = zone:GetNWInt("CurrentMoney", 0)
    local isLaundering = zone:GetNWBool("IsLaundering", false)
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 400)
    frame:Center()
    frame:SetTitle(building.name)
    frame:MakePopup()
    
    local mainPanel = vgui.Create("DPanel", frame)
    mainPanel:Dock(FILL)
    mainPanel:DockMargin(10, 10, 10, 10)
    mainPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(35, 35, 35))
    end
    
    -- Informations du bâtiment
    local infoPanel = vgui.Create("DPanel", mainPanel)
    infoPanel:Dock(TOP)
    infoPanel:SetHeight(120)
    infoPanel:DockMargin(10, 10, 10, 10)
    infoPanel.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(50, 50, 50))
    end
    
    local infoLabel = vgui.Create("DLabel", infoPanel)
    infoLabel:Dock(TOP)
    infoLabel:SetFont("DermaLarge")
    infoLabel:SetText("Informations :")
    infoLabel:SetTextColor(Color(255, 215, 0))
    infoLabel:DockMargin(10, 10, 10, 5)
    
    local maxLabel = vgui.Create("DLabel", infoPanel)
    maxLabel:Dock(TOP)
    maxLabel:SetText("Argent Max par blanchissement : " .. DarkRP.formatMoney(building.maxAmount))
    maxLabel:SetTextColor(Color(255, 255, 255))
    maxLabel:DockMargin(10, 0, 10, 0)
    
    local timeLabel = vgui.Create("DLabel", infoPanel)
    timeLabel:Dock(TOP)
    timeLabel:SetText("Temps de blanchissement : " .. building.launderTime .. " minutes")
    timeLabel:SetTextColor(Color(255, 255, 255))
    timeLabel:DockMargin(10, 5, 10, 0)
    
    local lossLabel = vgui.Create("DLabel", infoPanel)
    lossLabel:Dock(TOP)
    lossLabel:SetText("Taux de perte : " .. (building.lossRate * 100) .. "%")
    lossLabel:SetTextColor(Color(255, 100, 100))
    lossLabel:DockMargin(10, 5, 10, 10)
    
    -- Section blanchir
    if not isLaundering and currentMoney == 0 then
        local launderPanel = vgui.Create("DPanel", mainPanel)
        launderPanel:Dock(FILL)
        launderPanel:DockMargin(10, 0, 10, 10)
        launderPanel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(50, 50, 50))
        end
        
        local titleLabel = vgui.Create("DLabel", launderPanel)
        titleLabel:Dock(TOP)
        titleLabel:SetFont("DermaLarge")
        titleLabel:SetText("Blanchir")
        titleLabel:SetTextColor(Color(255, 215, 0))
        titleLabel:DockMargin(10, 10, 10, 10)
        
        -- Champ de texte pour le montant
        local amountPanel = vgui.Create("DPanel", launderPanel)
        amountPanel:Dock(TOP)
        amountPanel:SetHeight(60)
        amountPanel:DockMargin(10, 5, 10, 10)
        amountPanel.Paint = nil
        
        local amountLabel = vgui.Create("DLabel", amountPanel)
        amountLabel:Dock(TOP)
        amountLabel:SetText("Montant à blanchir :")
        amountLabel:SetTextColor(Color(255, 255, 255))
        amountLabel:DockMargin(0, 0, 0, 5)
        
        local amountEntry = vgui.Create("DTextEntry", amountPanel)
        amountEntry:Dock(TOP)
        amountEntry:SetPlaceholderText("Entrez le montant (Max: " .. DarkRP.formatMoney(building.maxAmount) .. ")")
        amountEntry:SetNumeric(true)
        amountEntry:SetUpdateOnType(true)
        amountEntry.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
            self:DrawTextEntryText(Color(255, 255, 255), Color(100, 150, 255), Color(255, 255, 255))
        end
        
        -- Affichage argent sale du joueur
        local dirtyMoneyLabel = vgui.Create("DLabel", launderPanel)
        dirtyMoneyLabel:Dock(TOP)
        -- Utiliser GetDirtyMoney() de ton système client
        local currentDirtyMoney = GetDirtyMoney and GetDirtyMoney() or 0
        dirtyMoneyLabel:SetText("Votre argent sale : " .. DarkRP.formatMoney(currentDirtyMoney))
        dirtyMoneyLabel:SetTextColor(Color(255, 200, 100))
        dirtyMoneyLabel:DockMargin(10, 10, 10, 5)
        
        -- Timer pour mettre à jour l'argent sale affiché
        local timerName = "LG_UpdateDirtyMoney_" .. math.random(1, 999999)
        timer.Create(timerName, 0.5, 0, function()
            if not IsValid(frame) or not IsValid(dirtyMoneyLabel) then 
                timer.Remove(timerName)
                return 
            end
            local money = GetDirtyMoney and GetDirtyMoney() or 0
            dirtyMoneyLabel:SetText("Votre argent sale : " .. DarkRP.formatMoney(money))
        end)
        
        -- Calcul de ce qu'on va recevoir
        local resultLabel = vgui.Create("DLabel", launderPanel)
        resultLabel:Dock(TOP)
        resultLabel:SetText("Argent propre reçu : " .. DarkRP.formatMoney(0))
        resultLabel:SetTextColor(Color(100, 255, 100))
        resultLabel:DockMargin(10, 0, 10, 10)
        
        amountEntry.OnValueChange = function(self, value)
            local amount = tonumber(value) or 0
            local cleanMoney = math.floor(amount * (1 - building.lossRate))
            resultLabel:SetText("Argent propre reçu : " .. DarkRP.formatMoney(cleanMoney))
        end
        
        -- Bouton valider
        local validateBtn = vgui.Create("DButton", launderPanel)
        validateBtn:Dock(BOTTOM)
        validateBtn:SetHeight(50)
        validateBtn:SetText("Valider")
        validateBtn:SetFont("DermaLarge")
        validateBtn:DockMargin(10, 10, 10, 10)
        validateBtn.DoClick = function()
            local amount = tonumber(amountEntry:GetValue()) or 0
            
            if amount <= 0 then
                chat.AddText(Color(255, 100, 100), "[Blanchiment] ", Color(255, 255, 255), "Montant invalide!")
                return
            end
            
            if amount > building.maxAmount then
                chat.AddText(Color(255, 100, 100), "[Blanchiment] ", Color(255, 255, 255), "Montant trop élevé! Maximum: " .. DarkRP.formatMoney(building.maxAmount))
                return
            end
            
            net.Start("LG_StartLaundering")
            net.WriteEntity(zone)
            net.WriteInt(amount, 32)
            net.SendToServer()
            
            frame:Close()
        end
    end
    
    -- Section récupérer
    if not isLaundering and currentMoney > 0 then
        local collectPanel = vgui.Create("DPanel", mainPanel)
        collectPanel:Dock(FILL)
        collectPanel:DockMargin(10, 0, 10, 10)
        collectPanel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(50, 50, 50))
        end
        
        local moneyLabel = vgui.Create("DLabel", collectPanel)
        moneyLabel:Dock(TOP)
        moneyLabel:SetFont("DermaLarge")
        moneyLabel:SetText("Argent disponible : " .. DarkRP.formatMoney(currentMoney))
        moneyLabel:SetTextColor(Color(100, 255, 100))
        moneyLabel:DockMargin(10, 20, 10, 20)
        moneyLabel:SetContentAlignment(5)
        
        local collectBtn = vgui.Create("DButton", collectPanel)
        collectBtn:Dock(FILL)
        collectBtn:SetText("Récupérer l'argent blanchi")
        collectBtn:SetFont("DermaLarge")
        collectBtn:DockMargin(10, 10, 10, 10)
        collectBtn.DoClick = function()
            net.Start("LG_CollectMoney")
            net.WriteEntity(zone)
            net.SendToServer()
            
            frame:Close()
        end
    end
    
    -- En cours de blanchiment
    if isLaundering then
        local waitPanel = vgui.Create("DPanel", mainPanel)
        waitPanel:Dock(FILL)
        waitPanel:DockMargin(10, 0, 10, 10)
        waitPanel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(50, 50, 50))
            
            local endTime = zone:GetNWInt("LaunderEndTime", 0)
            local timeLeft = math.max(0, endTime - CurTime())
            local minutes = math.floor(timeLeft / 60)
            local seconds = math.floor(timeLeft % 60)
            
            draw.SimpleText("Blanchiment en cours...", "DermaLarge", w/2, 50, Color(255, 215, 0), TEXT_ALIGN_CENTER)
            draw.SimpleText(string.format("Temps restant : %02d:%02d", minutes, seconds), "DermaLarge", w/2, 100, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            draw.SimpleText("Argent à récupérer : " .. DarkRP.formatMoney(currentMoney), "DermaDefault", w/2, 150, Color(100, 255, 100), TEXT_ALIGN_CENTER)
        end
    end
end)
