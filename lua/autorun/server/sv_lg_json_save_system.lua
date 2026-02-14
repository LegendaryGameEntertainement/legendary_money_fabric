-- Système de sauvegarde en JSON
if not SERVER then return end

LegendaryMoneyFabric = LegendaryMoneyFabric or {}
LegendaryMoneyFabric.JSONSave = {}

local DATA_FOLDER = "legendary_money_fabric"
local PLAYERS_FILE = DATA_FOLDER .. "/players_buildings.json"

-- Créer le dossier si il n'existe pas
if not file.Exists(DATA_FOLDER, "DATA") then
    file.CreateDir(DATA_FOLDER)
end

-- Charger toutes les données des joueurs
local function LoadAllPlayersData()
    if not file.Exists(PLAYERS_FILE, "DATA") then
        return {}
    end
    
    local json = file.Read(PLAYERS_FILE, "DATA")
    if not json then return {} end
    
    local data = util.JSONToTable(json)
    return data or {}
end

-- Sauvegarder toutes les données des joueurs
local function SaveAllPlayersData(data)
    local json = util.TableToJSON(data, true)
    file.Write(PLAYERS_FILE, json)
end

-- Charger les bâtiments d'un joueur
local function LoadPlayerBuildings(ply)
    local steamid = ply:SteamID64()
    local allData = LoadAllPlayersData()
    
    ply.launderingBuildings = allData[steamid] or {}
    
    print("[legendary_money_fabric] Chargé " .. table.Count(ply.launderingBuildings) .. " bâtiment(s) pour " .. ply:Nick())
end

-- Sauvegarder les bâtiments d'un joueur
local function SavePlayerBuildings(ply)
    local steamid = ply:SteamID64()
    local allData = LoadAllPlayersData()
    
    allData[steamid] = ply.launderingBuildings or {}
    
    SaveAllPlayersData(allData)
end

-- Ajouter un bâtiment à un joueur
local function SavePlayerBuilding(ply, buildingID)
    ply.launderingBuildings = ply.launderingBuildings or {}
    ply.launderingBuildings[buildingID] = true
    
    SavePlayerBuildings(ply)
end

-- Vérifier si un joueur possède un bâtiment
local function PlayerHasBuilding(ply, buildingID)
    return ply.launderingBuildings and ply.launderingBuildings[buildingID] == true
end

-- Exposer les fonctions
LegendaryMoneyFabric.LoadPlayerBuildings = LoadPlayerBuildings
LegendaryMoneyFabric.SavePlayerBuilding = SavePlayerBuilding
LegendaryMoneyFabric.PlayerHasBuilding = PlayerHasBuilding
LegendaryMoneyFabric.SavePlayerBuildings = SavePlayerBuildings

-- Charger les données au spawn
hook.Add("PlayerInitialSpawn", "LG_LoadLaunderingDataJSON", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            LoadPlayerBuildings(ply)
        end
    end)
end)

-- Sauvegarder les données à la déconnexion
hook.Add("PlayerDisconnected", "LG_SaveLaunderingDataJSON", function(ply)
    SavePlayerBuildings(ply)
end)

-- Sauvegarder toutes les X minutes (backup auto)
timer.Create("LG_AutoSaveBuildings", 300, 0, function() -- Toutes les 5 minutes
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            SavePlayerBuildings(ply)
        end
    end
    print("[legendary_money_fabric] Sauvegarde automatique effectuée")
end)

-- Commande admin pour voir le fichier JSON
concommand.Add("lg_show_json", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Vous devez être admin!")
        return
    end
    
    local data = LoadAllPlayersData()
    local output = "garrysmod/data/" .. PLAYERS_FILE
    
    if IsValid(ply) then
        ply:ChatPrint("Fichier JSON : " .. output)
        ply:ChatPrint("Joueurs enregistrés : " .. table.Count(data))
    else
        print("Fichier JSON : " .. output)
        print("Joueurs enregistrés : " .. table.Count(data))
    end
end)

-- Commande pour forcer la sauvegarde
concommand.Add("lg_force_save", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Vous devez être admin!")
        return
    end
    
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) then
            SavePlayerBuildings(p)
        end
    end
    
    if IsValid(ply) then
        ply:ChatPrint("Toutes les données ont été sauvegardées!")
    else
        print("Toutes les données ont été sauvegardées!")
    end
end)

print("[legendary_money_fabric] Système de sauvegarde JSON chargé!")
