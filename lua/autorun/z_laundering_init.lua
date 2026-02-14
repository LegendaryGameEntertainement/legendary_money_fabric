-- Chargement automatique du système de blanchiment
-- Note: sh_config.lua est chargé avant ce fichier car "sh" vient avant "z" alphabétiquement

timer.Simple(0, function()
    -- Vérifier que la config est chargée
    if not LegendaryMoneyFabric or not LegendaryMoneyFabric.Laundering then
        ErrorNoHalt("[legendary_money_fabric] Configuration non chargée! Vérifiez sh_config.lua\n")
        return
    end
    
    if SERVER then
        -- Créer la table SQL pour sauvegarder les bâtiments
        sql.Query([[
            CREATE TABLE IF NOT EXISTS lg_laundering_buildings (
                steamid TEXT NOT NULL,
                building_id TEXT NOT NULL,
                PRIMARY KEY (steamid, building_id)
            )
        ]])
        
        print("[legendary_money_fabric] Système de blanchiment chargé avec " .. #LegendaryMoneyFabric.Laundering.buildings .. " bâtiment(s)")
        
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
            local cmd = string.lower(text)
            
            if cmd == "!mybuildings" or cmd == "!mesbatiments" then
                local count = table.Count(ply.launderingBuildings or {})
                
                if count == 0 then
                    DarkRP.notify(ply, 0, 5, "Vous ne possédez aucun bâtiment de blanchiment.")
                else
                    ply:ChatPrint("═══════════════════════════════")
                    ply:ChatPrint("Vos bâtiments de blanchiment :")
                    ply:ChatPrint("═══════════════════════════════")
                    
                    for buildingID, _ in pairs(ply.launderingBuildings) do
                        for _, building in ipairs(LegendaryMoneyFabric.Laundering.buildings) do
                            if building.id == buildingID then
                                ply:ChatPrint("✓ " .. building.name)
                                break
                            end
                        end
                    end
                    
                    ply:ChatPrint("═══════════════════════════════")
                end
                
                return ""
            end
        end)
    else
        -- Côté client : vérifier que la config est bien chargée
        if LegendaryMoneyFabric and LegendaryMoneyFabric.Laundering then
            print("[legendary_money_fabric] Configuration client chargée avec " .. #LegendaryMoneyFabric.Laundering.buildings .. " bâtiment(s)")
        end
    end
end)
