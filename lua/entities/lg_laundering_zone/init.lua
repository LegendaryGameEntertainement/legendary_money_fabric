AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    
    self:SetNWString("BuildingID", "")
    self:SetNWString("BuildingName", "Zone de Blanchiment")
    self:SetNWInt("CurrentMoney", 0)
    self:SetNWInt("LaunderEndTime", 0)
    self:SetNWBool("IsLaundering", false)
    
    -- Permettre la sauvegarde automatique
    self.CanPersist = true
end


function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "BuildingID")
    self:NetworkVar("String", 1, "BuildingName")
end

function ENT:SetBuildingType(buildingID)
    local config = LegendaryMoneyFabric.Laundering
    for _, building in ipairs(config.buildings) do
        if building.id == buildingID then
            self:SetNWString("BuildingID", buildingID)
            self:SetNWString("BuildingName", building.name)
            break
        end
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    local buildingID = self:GetNWString("BuildingID", "")
    if buildingID == "" then
        DarkRP.notify(activator, 1, 5, "Cette zone n'est pas configurée!")
        return
    end
    
    net.Start("LG_OpenLaunderingZone")
    net.WriteEntity(self)
    net.WriteString(buildingID)
    net.Send(activator)
end

util.AddNetworkString("LG_OpenLaunderingZone")
util.AddNetworkString("LG_StartLaundering")
util.AddNetworkString("LG_CollectMoney")

-- Démarrer le blanchiment
net.Receive("LG_StartLaundering", function(len, ply)
    local zone = net.ReadEntity()
    local amount = net.ReadInt(32)
    
    if not IsValid(zone) then return end
    
    local buildingID = zone:GetNWString("BuildingID", "")
    local config = LegendaryMoneyFabric.Laundering
    local building = nil
    
    for _, b in ipairs(config.buildings) do
        if b.id == buildingID then
            building = b
            break
        end
    end
    
    if not building then return end
    
    -- Vérifier si le joueur possède ce type de bâtiment
    if not LegendaryMoneyFabric.PlayerHasBuilding(ply, buildingID) then
        DarkRP.notify(ply, 1, 5, "Vous ne possédez pas ce type de bâtiment! Achetez-le d'abord au vendeur.")
        return
    end
    
    -- Vérifier si un blanchiment est déjà en cours
    if zone:GetNWBool("IsLaundering", false) then
        DarkRP.notify(ply, 1, 5, "Un blanchiment est déjà en cours!")
        return
    end
    
    -- Vérifier le montant
    if amount <= 0 or amount > building.maxAmount then
        DarkRP.notify(ply, 1, 5, "Montant invalide! (Max: " .. DarkRP.formatMoney(building.maxAmount) .. ")")
        return
    end
    
    -- Vérifier l'argent sale du joueur (utilisation de ton système)
    local dirtyMoney = ply:GetDirtyMoney()
    if dirtyMoney < amount then
        DarkRP.notify(ply, 1, 5, "Vous n'avez pas assez d'argent sale! (Vous avez: " .. DarkRP.formatMoney(dirtyMoney) .. ")")
        return
    end
    
    -- Retirer l'argent sale (utilisation de ton système)
    ply:RemoveDirtyMoney(amount)
    
    -- Calculer l'argent propre à obtenir
    local cleanMoney = math.floor(amount * (1 - building.lossRate))
    
    -- Démarrer le blanchiment
    zone:SetNWBool("IsLaundering", true)
    zone:SetNWInt("CurrentMoney", cleanMoney)
    zone:SetNWInt("LaunderEndTime", CurTime() + (building.launderTime * 60))
    
    DarkRP.notify(ply, 0, 5, "Blanchiment démarré! Revenez dans " .. building.launderTime .. " minutes.")
    
    -- Timer pour terminer le blanchiment
    timer.Simple(building.launderTime * 60, function()
        if IsValid(zone) then
            zone:SetNWBool("IsLaundering", false)
        end
    end)
end)

-- Récupérer l'argent blanchi
net.Receive("LG_CollectMoney", function(len, ply)
    local zone = net.ReadEntity()
    
    if not IsValid(zone) then return end
    
    local currentMoney = zone:GetNWInt("CurrentMoney", 0)
    local isLaundering = zone:GetNWBool("IsLaundering", false)
    
    if currentMoney <= 0 then
        DarkRP.notify(ply, 1, 5, "Il n'y a pas d'argent à récupérer!")
        return
    end
    
    if isLaundering then
        DarkRP.notify(ply, 1, 5, "Le blanchiment est toujours en cours!")
        return
    end
    
    -- Donner l'argent propre (DarkRP)
    ply:addMoney(currentMoney)
    zone:SetNWInt("CurrentMoney", 0)
    
    DarkRP.notify(ply, 0, 5, "Vous avez récupéré " .. DarkRP.formatMoney(currentMoney) .. " d'argent propre!")
end)
