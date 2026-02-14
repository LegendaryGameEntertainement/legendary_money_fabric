AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    local config = LegendaryMoneyFabric.Laundering
    self:SetModel(config.vendorModel or "models/Humans/Group01/male_07.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetUseType(SIMPLE_USE)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:DrawShadow(false)
    
    self:SetMaxHealth(999999)
    self:SetHealth(999999)
    
    self:DropToFloor()
    
    local sequence = self:LookupSequence("idle_all_01")
    if sequence > 0 then
        self:ResetSequence(sequence)
    end
    
    self:SetPlaybackRate(1)
    self.AutomaticFrameAdvance = true
end

function ENT:Think()
    self:NextThink(CurTime())
    return true
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    print("[legendary_money_fabric] " .. activator:Nick() .. " ouvre le NPC vendeur")
    
    -- FORCER le rechargement depuis le fichier
    if LegendaryMoneyFabric.LoadPlayerBuildings then
        LegendaryMoneyFabric.LoadPlayerBuildings(activator)
    else
        print("[legendary_money_fabric] ERREUR: LoadPlayerBuildings n'existe pas!")
    end
    
    -- Attendre que le chargement soit terminé
    timer.Simple(0.3, function()
        if not IsValid(activator) then return end
        
        local buildings = activator.launderingBuildings or {}
        local count = table.Count(buildings)
        
        print("[legendary_money_fabric] Envoi de " .. count .. " bâtiment(s) à " .. activator:Nick())
        
        -- DEBUG : Afficher les bâtiments
        if count > 0 then
            for buildingID, _ in pairs(buildings) do
                print("  - " .. buildingID)
            end
        else
            print("  (aucun bâtiment)")
        end
        
        net.Start("LG_OpenLaunderingShop")
        net.WriteUInt(count, 8)
        for buildingID, _ in pairs(buildings) do
            net.WriteString(buildingID)
        end
        net.Send(activator)
    end)
end

function ENT:OnTakeDamage(dmginfo)
    return false
end

util.AddNetworkString("LG_OpenLaunderingShop")
util.AddNetworkString("LG_BuyLaunderingBuilding")

-- Réception de l'achat
net.Receive("LG_BuyLaunderingBuilding", function(len, ply)
    local buildingID = net.ReadString()
    
    print("[legendary_money_fabric] " .. ply:Nick() .. " tente d'acheter " .. buildingID)
    
    local config = LegendaryMoneyFabric.Laundering
    if not config or not config.buildings then
        ErrorNoHalt("[legendary_money_fabric] Configuration manquante!\n")
        return
    end
    
    local building = nil
    
    for _, b in ipairs(config.buildings) do
        if b.id == buildingID then
            building = b
            break
        end
    end
    
    if not building then
        DarkRP.notify(ply, 1, 5, "Bâtiment invalide!")
        return
    end
    
    -- IMPORTANT : Recharger les données depuis le fichier
    if LegendaryMoneyFabric.LoadPlayerBuildings then
        LegendaryMoneyFabric.LoadPlayerBuildings(ply)
    end
    
    -- Petit délai pour s'assurer que le chargement est terminé
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        
        -- Vérifier si le joueur possède déjà ce bâtiment
        if ply.launderingBuildings and ply.launderingBuildings[buildingID] == true then
            DarkRP.notify(ply, 1, 5, "Vous possédez déjà ce bâtiment!")
            print("[legendary_money_fabric] " .. ply:Nick() .. " possède déjà " .. buildingID)
            return
        end
        
        -- Vérifier l'argent
        if not ply.getDarkRPVar then
            print("[legendary_money_fabric] DarkRP non détecté!")
            return
        end
        
        local playerMoney = ply:getDarkRPVar("money") or 0
        if playerMoney < building.price then
            DarkRP.notify(ply, 1, 5, "Vous n'avez pas assez d'argent! (" .. DarkRP.formatMoney(building.price) .. " requis)")
            return
        end
        
        -- Retirer l'argent
        ply:addMoney(-building.price)
        
        -- Ajouter le bâtiment
        ply.launderingBuildings = ply.launderingBuildings or {}
        ply.launderingBuildings[buildingID] = true
        
        -- Sauvegarder
        if LegendaryMoneyFabric.SavePlayerBuilding then
            LegendaryMoneyFabric.SavePlayerBuilding(ply, buildingID)
        end
        
        DarkRP.notify(ply, 0, 5, "Vous avez acheté un " .. building.name .. "!")
        
        print("[legendary_money_fabric] " .. ply:Nick() .. " a acheté " .. buildingID .. " avec succès")
    end)
end)
