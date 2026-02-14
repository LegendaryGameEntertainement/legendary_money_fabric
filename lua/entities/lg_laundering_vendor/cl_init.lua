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
        draw.SimpleText("💼 Vendeur de Bâtiments", "DermaLarge", 0, -40, Color(255, 215, 0), TEXT_ALIGN_CENTER)
        draw.SimpleText("Appuyez sur E pour acheter", "DermaDefault", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

function ENT:Think()
    self:SetPlaybackRate(1)
    self:FrameAdvance(0)
end

-- Table locale pour stocker les bâtiments possédés
local ownedBuildings = {}

-- Recevoir les bâtiments possédés
net.Receive("LG_SendPlayerBuildings", function()
    ownedBuildings = {}
    
    local count = net.ReadUInt(8)
    for i = 1, count do
        local buildingID = net.ReadString()
        ownedBuildings[buildingID] = true
    end
end)

-- Interface d'achat
net.Receive("LG_OpenLaunderingShop", function()
    -- Demander la liste des bâtiments possédés
    net.Start("LG_OpenLaunderingShop")
    net.SendToServer()
    
    -- Attendre un peu que les données arrivent
    timer.Simple(0.1, function()
        local config = LegendaryMoneyFabric.Laundering
        
        if not config or not config.buildings then
            chat.AddText(Color(255, 100, 100), "[Erreur] Configuration manquante!")
            return
        end
        
        local frame = vgui.Create("DFrame")
        frame:SetSize(900, 600)
        frame:Center()
        frame:SetTitle("Achat de Bâtiments de Blanchiment")
        frame:MakePopup()
        
        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:Dock(FILL)
        scroll:DockMargin(10, 10, 10, 10)
        
        for _, building in ipairs(config.buildings) do
            local isOwned = ownedBuildings[building.id] == true
            
            local panel = vgui.Create("DPanel", scroll)
            panel:Dock(TOP)
            panel:DockMargin(0, 0, 0, 10)
            panel:SetHeight(120)
            
            panel.Paint = function(self, w, h)
                local bgColor = Color(50, 50, 50, 200)
                local borderColor = Color(35, 35, 35, 250)
                
                if isOwned then
                    bgColor = Color(50, 80, 50, 200)
                    borderColor = Color(35, 60, 35, 250)
                end
                
                draw.RoundedBox(8, 0, 0, w, h, bgColor)
                draw.RoundedBox(8, 2, 2, w-4, h-4, borderColor)
            end
            
            -- Image du bâtiment (à gauche)
            local imgPanel = vgui.Create("DPanel", panel)
            imgPanel:Dock(LEFT)
            imgPanel:SetWide(180)
            imgPanel:DockMargin(10, 10, 0, 10)
            imgPanel.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60))
                draw.SimpleText("📷", "DermaLarge", w/2, h/2, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            -- Informations (centre)
            local infoPanel = vgui.Create("DPanel", panel)
            infoPanel:Dock(FILL)
            infoPanel:DockMargin(10, 10, 10, 10)
            infoPanel.Paint = nil
            
            local nameLabel = vgui.Create("DLabel", infoPanel)
            nameLabel:SetText(building.name .. (isOwned and " ✓" or ""))
            nameLabel:SetFont("DermaLarge")
            nameLabel:SetTextColor(isOwned and Color(100, 255, 100) or Color(255, 215, 0))
            nameLabel:Dock(TOP)
            
            local priceLabel = vgui.Create("DLabel", infoPanel)
            priceLabel:SetText("Prix : " .. DarkRP.formatMoney(building.price))
            priceLabel:SetFont("DermaDefault")
            priceLabel:SetTextColor(Color(100, 255, 100))
            priceLabel:Dock(TOP)
            priceLabel:DockMargin(0, 5, 0, 0)
            
            local maxLabel = vgui.Create("DLabel", infoPanel)
            maxLabel:SetText("Argent Max : " .. DarkRP.formatMoney(building.maxAmount))
            maxLabel:SetFont("DermaDefault")
            maxLabel:SetTextColor(Color(255, 255, 255))
            maxLabel:Dock(TOP)
            
            local timeLabel = vgui.Create("DLabel", infoPanel)
            timeLabel:SetText("Temps de blanchiment : " .. building.launderTime .. " minutes")
            timeLabel:SetFont("DermaDefault")
            timeLabel:SetTextColor(Color(255, 255, 255))
            timeLabel:Dock(TOP)
            
            local lossLabel = vgui.Create("DLabel", infoPanel)
            lossLabel:SetText("Taux de perte : " .. (building.lossRate * 100) .. "%")
            lossLabel:SetFont("DermaDefault")
            lossLabel:SetTextColor(Color(255, 100, 100))
            lossLabel:Dock(TOP)
            
            -- Bouton d'achat (à droite)
            local buyBtn = vgui.Create("DButton", panel)
            buyBtn:Dock(RIGHT)
            buyBtn:SetWide(100)
            buyBtn:DockMargin(0, 10, 10, 10)
            buyBtn:SetFont("DermaLarge")
            
            if isOwned then
                buyBtn:SetText("Possédé")
                buyBtn:SetEnabled(false)
                buyBtn.Paint = function(self, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, Color(50, 80, 50))
                end
            else
                buyBtn:SetText("Acheter")
                buyBtn.DoClick = function()
                    net.Start("LG_BuyLaunderingBuilding")
                    net.WriteString(building.id)
                    net.SendToServer()
                    frame:Close()
                end
            end
        end
    end)
end)
