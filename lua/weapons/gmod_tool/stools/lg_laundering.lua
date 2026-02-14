TOOL.Category = "Money Fabric"
TOOL.Name = "Outil Zone de Blanchiment"

if CLIENT then
    language.Add("tool.lg_laundering.name", "Outil Zone de Blanchiment")
    language.Add("tool.lg_laundering.desc", "Place des zones de blanchiment sur la map")
    language.Add("tool.lg_laundering.0", "Clic gauche : Placer une zone | Clic droit : Supprimer une zone")
    
    TOOL.Information = {
        {name = "left"},
        {name = "right"}
    }
end

TOOL.ClientConVar = {
    building_type = "laundromat"
}

function TOOL:LeftClick(trace)
    if CLIENT then return true end
    if not IsValid(self:GetOwner()) or not self:GetOwner():IsAdmin() then return false end
    
    local ply = self:GetOwner()
    local buildingType = self:GetClientInfo("building_type")
    
    local zone = ents.Create("lg_laundering_zone")
    if not IsValid(zone) then return false end
    
    zone:SetPos(trace.HitPos + trace.HitNormal * 15)
    zone:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    zone:Spawn()
    
    -- Important : définir le type AVANT que le hook de sauvegarde ne se déclenche
    timer.Simple(0, function()
        if IsValid(zone) then
            zone:SetBuildingType(buildingType)
        end
    end)
    
    undo.Create("LG_LaunderingZone")
    undo.AddEntity(zone)
    undo.SetPlayer(ply)
    undo.Finish()
    
    DarkRP.notify(ply, 0, 5, "Zone de blanchiment créée et sauvegardée!")
    return true
end

function TOOL:RightClick(trace)
    if CLIENT then return true end
    if not IsValid(self:GetOwner()) or not self:GetOwner():IsAdmin() then return false end
    
    local ent = trace.Entity
    if IsValid(ent) and ent:GetClass() == "lg_laundering_zone" then
        ent:Remove()
        DarkRP.notify(self:GetOwner(), 0, 5, "Zone de blanchiment supprimée!")
        return true
    end
    
    return false
end

if CLIENT then
    function TOOL.BuildCPanel(panel)
        panel:AddControl("Header", {Description = "Place des zones de blanchiment sur la map"})
        
        local config = LegendaryMoneyFabric and LegendaryMoneyFabric.Laundering
        
        if not config or not config.buildings then
            panel:AddControl("Label", {Text = "⚠ Configuration non chargée!"})
            return
        end
        
        panel:AddControl("Label", {Text = "Type de bâtiment:"})
        
        -- Créer des boutons pour chaque type
        for _, building in ipairs(config.buildings) do
            local btn = vgui.Create("DButton")
            btn:SetText(building.name)
            btn:SetTall(30)
            btn.DoClick = function()
                RunConsoleCommand("lg_laundering_building_type", building.id)
            end
            btn.Paint = function(self, w, h)
                local selected = GetConVar("lg_laundering_building_type"):GetString()
                local col = Color(50, 50, 50)
                if selected == building.id then
                    col = Color(80, 150, 80)
                elseif self:IsHovered() then
                    col = Color(70, 70, 70)
                end
                draw.RoundedBox(4, 0, 0, w, h, col)
            end
            
            panel:AddItem(btn)
        end
        
        -- Afficher le type sélectionné
        panel:AddControl("Label", {Text = "\n━━━━━━━━━━━━━━━━━━━━━"})
        
        local infoLabel = vgui.Create("DLabel")
        infoLabel:SetAutoStretchVertical(true)
        infoLabel:SetWrap(true)
        infoLabel:SetTextColor(Color(200, 200, 200))
        
        local function UpdateInfo()
            if not IsValid(infoLabel) then return end
            
            local selected = GetConVar("lg_laundering_building_type"):GetString()
            local selectedBuilding = nil
            
            for _, building in ipairs(config.buildings) do
                if building.id == selected then
                    selectedBuilding = building
                    break
                end
            end
            
            if selectedBuilding then
                local text = string.format(
                    "Type sélectionné: %s\n\nPrix: %s\nMax: %s\nTemps: %d min\nPerte: %.0f%%",
                    selectedBuilding.name,
                    DarkRP.formatMoney(selectedBuilding.price),
                    DarkRP.formatMoney(selectedBuilding.maxAmount),
                    selectedBuilding.launderTime,
                    selectedBuilding.lossRate * 100
                )
                infoLabel:SetText(text)
            else
                infoLabel:SetText("Aucun type sélectionné")
            end
        end
        
        UpdateInfo()
        
        local timerName = "LG_UpdateBuildingInfo_" .. math.random(1, 999999)
        timer.Create(timerName, 0.2, 0, function()
            if not IsValid(panel) or not IsValid(infoLabel) then 
                timer.Remove(timerName)
                return 
            end
            UpdateInfo()
        end)
        
        panel:AddItem(infoLabel)
        
        -- Section gestion des entités
        panel:AddControl("Label", {Text = "\n━━━━━━━━━━━━━━━━━━━━━"})
        panel:AddControl("Header", {Description = "Gestion des entités sauvegardées"})
        
        panel:AddControl("Button", {
            Label = "Recharger les entités",
            Command = "lg_reload_entities",
            Text = ""
        })
        
        panel:AddControl("Button", {
            Label = "Lister les entités",
            Command = "lg_list_entities",
            Text = ""
        })
        
        panel:AddControl("Button", {
            Label = "⚠ Tout supprimer",
            Command = "lg_clear_entities",
            Text = ""
        })
    end
end
