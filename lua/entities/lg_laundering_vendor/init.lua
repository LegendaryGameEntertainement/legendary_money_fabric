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
    
    net.Start("LG_OpenLaunderingShop")
    net.Send(activator)
end

function ENT:OnTakeDamage(dmginfo)
    return false
end

util.AddNetworkString("LG_OpenLaunderingShop")
util.AddNetworkString("LG_BuyLaunderingBuilding")
util.AddNetworkString("LG_SendPlayerBuildings")

-- Envoyer les bâtiments possédés au client
net.Receive("LG_OpenLaunderingShop", function(len, ply)
    -- Envoyer la liste des bâtiments possédés
    net.Start("LG_SendPlayerBuildings")
    
    local buildings = ply.launderingBuildings or {}
    local count = table.Count(buildings)
    
    net.WriteUInt(count, 8)
    for buildingID, _ in pairs(buildings) do
        net.WriteString(buildingID)
    end
    
    net.Send(ply)
end)

-- Réception de l'achat
net.Receive("LG_BuyLaunderingBuilding", function(len, ply)
    local buildingID = net.ReadString()
    
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
    
    -- Vérifier si le joueur possède déjà ce bâtiment
    if LegendaryMoneyFabric.PlayerHasBuilding(ply, buildingID) then
        DarkRP.notify(ply, 1, 5, "Vous possédez déjà ce bâtiment!")
        return
    end
    
    -- Vérifier si le joueur a assez d'argent propre
    if not ply.getDarkRPVar then
        print("[legendary_money_fabric] DarkRP non détecté!")
        return
    end
    
    local playerMoney = ply:getDarkRPVar("money") or 0
    if playerMoney < building.price then
        DarkRP.notify(ply, 1, 5, "Vous n'avez pas assez d'argent propre! (" .. DarkRP.formatMoney(building.price) .. " requis)")
        return
    end
    
    -- Retirer l'argent
    ply:addMoney(-building.price)
    
    -- Ajouter le bâtiment
    ply.launderingBuildings = ply.launderingBuildings or {}
    ply.launderingBuildings[buildingID] = true
    
    -- Sauvegarder dans la base de données
    LegendaryMoneyFabric.SavePlayerBuilding(ply, buildingID)
    
    DarkRP.notify(ply, 0, 5, "Vous avez acheté un " .. building.name .. "!")
end)
