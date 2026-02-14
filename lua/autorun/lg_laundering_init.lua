-- Chargement de la configuration
if SERVER then
    AddCSLuaFile("autorun/sh_config.lua")
    include("autorun/sh_config.lua")
else
    include("autorun/sh_config.lua")
end
if SERVER then
    AddCSLuaFile()
    
    -- Créer la table SQL pour sauvegarder les bâtiments
    sql.Query([[
        CREATE TABLE IF NOT EXISTS lg_laundering_buildings (
            steamid TEXT NOT NULL,
            building_id TEXT NOT NULL,
            PRIMARY KEY (steamid, building_id)
        )
    ]])
    
    print("[legendary_money_fabric] Système de blanchiment chargé!")
    
    -- Fonction pour charger les bâtiments d'un joueur
    local function LoadPlayerBuildings(ply)
        local steamid = ply:SteamID64()
        local result = sql.Query("SELECT building_id FROM lg_laundering_buildings WHERE steamid = '" .. sql.SQLStr(steamid, true) .. "'")
        
        ply.launderingBuildings = {}
        
        if result then
            for _, row in ipairs(result) do
                ply.launderingBuildings[row.building_id] = true
            end
        end
        
        print("[legendary_money_fabric] Chargé " .. table.Count(ply.launderingBuildings) .. " bâtiment(s) pour " .. ply:Nick())
    end
    
    -- Fonction pour sauvegarder un bâtiment acheté
    local function SavePlayerBuilding(ply, buildingID)
        local steamid = ply:SteamID64()
        
        sql.Query(string.format(
            "INSERT OR IGNORE INTO lg_laundering_buildings (steamid, building_id) VALUES ('%s', '%s')",
            sql.SQLStr(steamid, true),
            sql.SQLStr(buildingID, true)
        ))
    end
    
    -- Fonction pour vérifier si un joueur possède un bâtiment
    local function PlayerHasBuilding(ply, buildingID)
        return ply.launderingBuildings and ply.launderingBuildings[buildingID] == true
    end
    
    -- Exposer les fonctions
    LegendaryMoneyFabric.LoadPlayerBuildings = LoadPlayerBuildings
    LegendaryMoneyFabric.SavePlayerBuilding = SavePlayerBuilding
    LegendaryMoneyFabric.PlayerHasBuilding = PlayerHasBuilding
    
    -- Charger les données au spawn
    hook.Add("PlayerInitialSpawn", "LG_LoadLaunderingData", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                LoadPlayerBuildings(ply)
            end
        end)
    end)
    
    -- Commande pour voir ses bâtiments
    hook.Add("PlayerSay", "LG_LaunderingCommands", function(ply, text)
        if string.lower(text) == "!mybuildings" or string.lower(text) == "!mesbatiments" then
            local count = table.Count(ply.launderingBuildings or {})
            
            if count == 0 then
                DarkRP.notify(ply, 0, 5, "Vous ne possédez aucun bâtiment de blanchiment.")
            else
                DarkRP.notify(ply, 0, 5, "Vos bâtiments de blanchiment :")
                
                for buildingID, _ in pairs(ply.launderingBuildings) do
                    for _, building in ipairs(LegendaryMoneyFabric.Laundering.buildings) do
                        if building.id == buildingID then
                            DarkRP.notify(ply, 0, 5, "- " .. building.name)
                            break
                        end
                    end
                end
            end
            
            return ""
        end
    end)
end
