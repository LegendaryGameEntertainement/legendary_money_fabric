-- Système de sauvegarde des positions des entités
if not SERVER then return end

LegendaryMoneyFabric = LegendaryMoneyFabric or {}
LegendaryMoneyFabric.Persistence = LegendaryMoneyFabric.Persistence or {}

-- Entités à sauvegarder automatiquement
local PERSISTENT_ENTITIES = {
    ["lg_laundering_vendor"] = true,
    ["lg_laundering_zone"] = true,
    ["lg_npc_seller"] = true
}

-- Créer la table SQL
sql.Query([[
    CREATE TABLE IF NOT EXISTS lg_entity_positions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_class TEXT NOT NULL,
        pos_x REAL NOT NULL,
        pos_y REAL NOT NULL,
        pos_z REAL NOT NULL,
        ang_p REAL NOT NULL,
        ang_y REAL NOT NULL,
        ang_r REAL NOT NULL,
        data TEXT
    )
]])

print("[legendary_money_fabric] Système de persistence des entités chargé!")

-- Sauvegarder une entité
local function SaveEntity(ent)
    if not IsValid(ent) then return false end
    
    local class = ent:GetClass()
    if not PERSISTENT_ENTITIES[class] then return false end
    
    local pos = ent:GetPos()
    local ang = ent:GetAngles()
    
    -- Données spécifiques selon le type d'entité
    local data = {}
    
    if class == "lg_laundering_zone" then
        data.buildingID = ent:GetNWString("BuildingID", "")
    end
    
    local dataJSON = util.TableToJSON(data)
    
    sql.Query(string.format([[
        INSERT INTO lg_entity_positions (entity_class, pos_x, pos_y, pos_z, ang_p, ang_y, ang_r, data)
        VALUES ('%s', %f, %f, %f, %f, %f, %f, '%s')
    ]], 
        sql.SQLStr(class, true),
        pos.x, pos.y, pos.z,
        ang.p, ang.y, ang.r,
        sql.SQLStr(dataJSON, true)
    ))
    
    return true
end

-- Charger toutes les entités sauvegardées
local function LoadAllEntities()
    local result = sql.Query("SELECT * FROM lg_entity_positions")
    
    if not result then
        print("[legendary_money_fabric] Aucune entité à charger")
        return
    end
    
    local count = 0
    
    for _, row in ipairs(result) do
        local ent = ents.Create(row.entity_class)
        
        if IsValid(ent) then
            local pos = Vector(tonumber(row.pos_x), tonumber(row.pos_y), tonumber(row.pos_z))
            local ang = Angle(tonumber(row.ang_p), tonumber(row.ang_y), tonumber(row.ang_r))
            
            ent:SetPos(pos)
            ent:SetAngles(ang)
            ent:Spawn()
            
            -- Restaurer les données spécifiques
            if row.data and row.data ~= "" then
                local data = util.JSONToTable(row.data)
                
                if data and row.entity_class == "lg_laundering_zone" and data.buildingID then
                    timer.Simple(0.1, function()
                        if IsValid(ent) then
                            ent:SetBuildingType(data.buildingID)
                        end
                    end)
                end
            end
            
            -- Marquer l'entité comme persistante
            ent.IsPersistent = true
            ent.PersistenceID = tonumber(row.id)
            
            count = count + 1
        end
    end
    
    print("[legendary_money_fabric] " .. count .. " entité(s) chargée(s)")
end

-- Supprimer une entité de la base de données
local function RemoveEntityFromDB(ent)
    if not IsValid(ent) or not ent.PersistenceID then return end
    
    sql.Query("DELETE FROM lg_entity_positions WHERE id = " .. ent.PersistenceID)
end

-- Nettoyer toutes les entités sauvegardées
local function ClearAllEntities()
    sql.Query("DELETE FROM lg_entity_positions")
    print("[legendary_money_fabric] Toutes les entités sauvegardées ont été supprimées de la base de données")
end

-- Hook pour sauvegarder quand une entité est créée
hook.Add("OnEntityCreated", "LG_SavePersistentEntity", function(ent)
    timer.Simple(0.1, function()
        if IsValid(ent) and PERSISTENT_ENTITIES[ent:GetClass()] then
            -- Ne pas sauvegarder si c'est une entité qui vient d'être chargée
            if ent.IsPersistent then return end
            
            SaveEntity(ent)
            
            -- Marquer comme persistante
            ent.IsPersistent = true
            
            print("[legendary_money_fabric] Entité " .. ent:GetClass() .. " sauvegardée")
        end
    end)
end)

-- Hook pour supprimer de la DB quand l'entité est supprimée
hook.Add("EntityRemoved", "LG_RemovePersistentEntity", function(ent)
    if IsValid(ent) and ent.IsPersistent and ent.PersistenceID then
        RemoveEntityFromDB(ent)
        print("[legendary_money_fabric] Entité " .. ent:GetClass() .. " supprimée de la base de données")
    end
end)

-- Charger les entités au démarrage du serveur
hook.Add("InitPostEntity", "LG_LoadPersistentEntities", function()
    timer.Simple(2, function()
        LoadAllEntities()
    end)
end)

-- Exposer les fonctions
LegendaryMoneyFabric.Persistence.SaveEntity = SaveEntity
LegendaryMoneyFabric.Persistence.LoadAllEntities = LoadAllEntities
LegendaryMoneyFabric.Persistence.ClearAllEntities = ClearAllEntities
LegendaryMoneyFabric.Persistence.RemoveEntityFromDB = RemoveEntityFromDB

-- Commandes admin
concommand.Add("lg_reload_entities", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Vous devez être admin!")
        return
    end
    
    -- Supprimer toutes les entités persistantes actuelles
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.IsPersistent then
            ent:Remove()
        end
    end
    
    -- Recharger
    timer.Simple(0.5, function()
        LoadAllEntities()
        
        if IsValid(ply) then
            ply:ChatPrint("[legendary_money_fabric] Entités rechargées!")
        else
            print("[legendary_money_fabric] Entités rechargées!")
        end
    end)
end)

concommand.Add("lg_clear_entities", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Vous devez être admin!")
        return
    end
    
    -- Supprimer toutes les entités persistantes
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.IsPersistent then
            ent:Remove()
        end
    end
    
    ClearAllEntities()
    
    if IsValid(ply) then
        ply:ChatPrint("[legendary_money_fabric] Toutes les entités ont été supprimées!")
    else
        print("[legendary_money_fabric] Toutes les entités ont été supprimées!")
    end
end)

-- Commande pour lister les entités sauvegardées
concommand.Add("lg_list_entities", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Vous devez être admin!")
        return
    end
    
    local result = sql.Query("SELECT * FROM lg_entity_positions")
    
    if not result then
        if IsValid(ply) then
            ply:ChatPrint("[legendary_money_fabric] Aucune entité sauvegardée")
        else
            print("[legendary_money_fabric] Aucune entité sauvegardée")
        end
        return
    end
    
    if IsValid(ply) then
        ply:ChatPrint("[legendary_money_fabric] Entités sauvegardées:")
        for _, row in ipairs(result) do
            ply:ChatPrint("  - " .. row.entity_class .. " (ID: " .. row.id .. ")")
        end
    else
        print("[legendary_money_fabric] Entités sauvegardées:")
        for _, row in ipairs(result) do
            print("  - " .. row.entity_class .. " (ID: " .. row.id .. ")")
        end
    end
end)
