-- Système de sauvegarde manuel des positions des entités
if not SERVER then return end

print("[legendary_money_fabric] ========================================")
print("[legendary_money_fabric] sv_lg_entity_persistence.lua CHARGÉ !")
print("[legendary_money_fabric] ========================================")


LegendaryMoneyFabric = LegendaryMoneyFabric or {}
LegendaryMoneyFabric.Persistence = LegendaryMoneyFabric.Persistence or {}

-- Entités à sauvegarder
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

-- Sauvegarder toutes les entités présentes sur la map
local function SaveAllEntities()
    -- D'abord, vider la table
    sql.Query("DELETE FROM lg_entity_positions")
    
    local count = 0
    
    -- Parcourir toutes les entités
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and PERSISTENT_ENTITIES[ent:GetClass()] then
            local class = ent:GetClass()
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
            
            count = count + 1
        end
    end
    
    return count
end

-- Charger toutes les entités sauvegardées
local function LoadAllEntities()
    local result = sql.Query("SELECT * FROM lg_entity_positions")
    
    if not result then
        print("[legendary_money_fabric] Aucune entité à charger")
        return 0
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
            
            count = count + 1
        end
    end
    
    print("[legendary_money_fabric] " .. count .. " entité(s) chargée(s)")
    return count
end

-- Supprimer toutes les positions sauvegardées
local function DeleteAllPositions()
    -- Supprimer toutes les entités présentes
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and PERSISTENT_ENTITIES[ent:GetClass()] then
            ent:Remove()
        end
    end
    
    -- Vider la base de données
    sql.Query("DELETE FROM lg_entity_positions")
    
    print("[legendary_money_fabric] Toutes les positions ont été supprimées")
end

-- Charger les entités au démarrage du serveur
hook.Add("InitPostEntity", "LG_LoadPersistentEntities", function()
    timer.Simple(2, function()
        LoadAllEntities()
    end)
end)

-- Exposer les fonctions
LegendaryMoneyFabric.Persistence.SaveAllEntities = SaveAllEntities
LegendaryMoneyFabric.Persistence.LoadAllEntities = LoadAllEntities
LegendaryMoneyFabric.Persistence.DeleteAllPositions = DeleteAllPositions

-- Commande !launderingsaveposition
hook.Add("PlayerSay", "LG_LaunderingSaveCommand", function(ply, text)
    local cmd = string.lower(text)
    
    if cmd == "!launderingsaveposition" then
        if not ply:IsAdmin() then
            DarkRP.notify(ply, 1, 5, "Vous devez être admin!")
            return ""
        end
        
        local count = SaveAllEntities()
        
        DarkRP.notify(ply, 0, 5, count .. " entité(s) sauvegardée(s)!")
        
        -- Message en chat pour tous les admins
        for _, admin in ipairs(player.GetAll()) do
            if admin:IsAdmin() then
                admin:ChatPrint("[Blanchiment] " .. ply:Nick() .. " a sauvegardé " .. count .. " entité(s)")
            end
        end
        
        return ""
    end
    
    if cmd == "!launderingdeleteposition" then
        if not ply:IsAdmin() then
            DarkRP.notify(ply, 1, 5, "Vous devez être admin!")
            return ""
        end
        
        DeleteAllPositions()
        
        DarkRP.notify(ply, 1, 5, "Toutes les positions ont été supprimées!")
        
        -- Message en chat pour tous les admins
        for _, admin in ipairs(player.GetAll()) do
            if admin:IsAdmin() then
                admin:ChatPrint("[Blanchiment] " .. ply:Nick() .. " a supprimé toutes les positions")
            end
        end
        
        return ""
    end
end)

-- Commandes console (au cas où)
concommand.Add("lg_save_positions", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Vous devez être admin!")
        return
    end
    
    local count = SaveAllEntities()
    
    if IsValid(ply) then
        ply:ChatPrint("[legendary_money_fabric] " .. count .. " entité(s) sauvegardée(s)!")
    else
        print("[legendary_money_fabric] " .. count .. " entité(s) sauvegardée(s)!")
    end
end)

concommand.Add("lg_delete_positions", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Vous devez être admin!")
        return
    end
    
    DeleteAllPositions()
    
    if IsValid(ply) then
        ply:ChatPrint("[legendary_money_fabric] Toutes les positions ont été supprimées!")
    else
        print("[legendary_money_fabric] Toutes les positions ont été supprimées!")
    end
end)

concommand.Add("lg_load_positions", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Vous devez être admin!")
        return
    end
    
    local count = LoadAllEntities()
    
    if IsValid(ply) then
        ply:ChatPrint("[legendary_money_fabric] " .. count .. " entité(s) chargée(s)!")
    else
        print("[legendary_money_fabric] " .. count .. " entité(s) chargée(s)!")
    end
end)
