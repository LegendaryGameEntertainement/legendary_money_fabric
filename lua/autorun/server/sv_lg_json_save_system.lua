-- Système de sauvegarde en JSON avec SteamID32
if not SERVER then return end

LegendaryMoneyFabric = LegendaryMoneyFabric or {}
LegendaryMoneyFabric.JSONSave = {}

local DATA_FOLDER = "legendary_money_fabric"
local PLAYERS_FILE = DATA_FOLDER .. "/players_buildings.json" 


-- Créer le dossier si il n'existe pas
if not file.Exists(DATA_FOLDER, "DATA") then
    file.CreateDir(DATA_FOLDER)
end

-- Encoder en JSON proprement
local function EncodeJSON(data)
    local lines = {}
    table.insert(lines, "{")
    
    local first = true
    for steamid, buildings in pairs(data) do
        if not first then
            table.insert(lines, ",")
        end
        first = false
        
        table.insert(lines, '    "' .. tostring(steamid) .. '": {')
        
        local firstBuilding = true
        for buildingID, owned in pairs(buildings) do
            if not firstBuilding then
                table.insert(lines, ",")
            end
            firstBuilding = false
            table.insert(lines, '        "' .. tostring(buildingID) .. '": ' .. tostring(owned))
        end
        
        table.insert(lines, "    }")
    end
    
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

-- Charger toutes les données
local function LoadAllPlayersData()
    if not file.Exists(PLAYERS_FILE, "DATA") then
        print("[legendary_money_fabric] Aucun fichier de sauvegarde")
        return {}
    end
    
    local content = file.Read(PLAYERS_FILE, "DATA")
    if not content or content == "" then 
        print("[legendary_money_fabric] Fichier vide")
        return {} 
    end
    
    local data = util.JSONToTable(content)
    if not data then 
        print("[legendary_money_fabric] Erreur de lecture JSON")
        return {} 
    end
    
    print("[legendary_money_fabric] Fichier chargé : " .. table.Count(data) .. " joueur(s)")
    return data
end

-- Sauvegarder toutes les données
local function SaveAllPlayersData(data)
    local json = EncodeJSON(data)
    file.Write(PLAYERS_FILE, json)
    print("[legendary_money_fabric] Données sauvegardées")
end

-- Charger les bâtiments d'un joueur
local function LoadPlayerBuildings(ply)
    if not IsValid(ply) then return end
    
    local steamid = ply:SteamID() -- Utilise SteamID32 : STEAM_0:1:12345678
    local allData = LoadAllPlayersData()
    
    ply.launderingBuildings = allData[steamid] or {}
    
    local count = table.Count(ply.launderingBuildings)
    print("[legendary_money_fabric] Chargé " .. count .. " bâtiment(s) pour " .. ply:Nick() .. " (SteamID: " .. steamid .. ")")
    
    if count > 0 then
        for buildingID, _ in pairs(ply.launderingBuildings) do
            print("  ✓ " .. buildingID)
        end
    end
end

-- Sauvegarder les bâtiments d'un joueur
local function SavePlayerBuildings(ply)
    if not IsValid(ply) then return end
    
    local steamid = ply:SteamID()
    local allData = LoadAllPlayersData()
    
    allData[steamid] = ply.launderingBuildings or {}
    
    SaveAllPlayersData(allData)
    
    print("[legendary_money_fabric] Sauvegardé " .. table.Count(ply.launderingBuildings or {}) .. " bâtiment(s) pour " .. ply:Nick())
end

-- Ajouter un bâtiment
local function SavePlayerBuilding(ply, buildingID)
    if not IsValid(ply) then return end
    
    ply.launderingBuildings = ply.launderingBuildings or {}
    ply.launderingBuildings[buildingID] = true
    
    SavePlayerBuildings(ply)
    
    print("[legendary_money_fabric] Bâtiment '" .. buildingID .. "' ajouté pour " .. ply:Nick())
end

-- Vérifier si possède un bâtiment
local function PlayerHasBuilding(ply, buildingID)
    if not IsValid(ply) then return false end
    return ply.launderingBuildings and ply.launderingBuildings[buildingID] == true
end

-- Exposer les fonctions
LegendaryMoneyFabric.LoadPlayerBuildings = LoadPlayerBuildings
LegendaryMoneyFabric.SavePlayerBuilding = SavePlayerBuilding
LegendaryMoneyFabric.PlayerHasBuilding = PlayerHasBuilding
LegendaryMoneyFabric.SavePlayerBuildings = SavePlayerBuildings

-- Charger au spawn
hook.Add("PlayerInitialSpawn", "LG_LoadLaunderingDataJSON", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            LoadPlayerBuildings(ply)
        end
    end)
end)

-- Sauvegarder à la déco
hook.Add("PlayerDisconnected", "LG_SaveLaunderingDataJSON", function(ply)
    SavePlayerBuildings(ply)
end)

-- Sauvegarde automatique toutes les 5 minutes
timer.Create("LG_AutoSaveBuildings", 300, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            SavePlayerBuildings(ply)
        end
    end
    print("[legendary_money_fabric] Sauvegarde automatique effectuée")
end)

-- Commande de debug
concommand.Add("lg_debug_buildings", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Vous devez être admin!")
        return
    end
    
    local target = ply
    if #args > 0 and IsValid(ply) then
        target = DarkRP.findPlayer(args[1])
    end
    
    if not IsValid(target) then
        print("Joueur introuvable!")
        return
    end
    
    print("========================================")
    print("DEBUG - " .. target:Nick())
    print("SteamID: " .. target:SteamID())
    print("========================================")
    
    if target.launderingBuildings then
        print("En mémoire: " .. table.Count(target.launderingBuildings))
        for k, v in pairs(target.launderingBuildings) do
            print("  - " .. k .. " = " .. tostring(v))
        end
    else
        print("Rien en mémoire")
    end
    
    print("----------------------------------------")
    
    local allData = LoadAllPlayersData()
    local steamid = target:SteamID()
    
    if allData[steamid] then
        print("Dans fichier: " .. table.Count(allData[steamid]))
        for k, v in pairs(allData[steamid]) do
            print("  - " .. k .. " = " .. tostring(v))
        end
    else
        print("Rien dans le fichier")
    end
    
    print("========================================")
end)

-- Forcer le rechargement
concommand.Add("lg_force_reload", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Vous devez être admin!")
        return
    end
    
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) then
            LoadPlayerBuildings(p)
        end
    end
    
    if IsValid(ply) then
        ply:ChatPrint("Rechargement forcé!")
    else
        print("Rechargement forcé!")
    end
end)

-- Forcer la sauvegarde
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
        ply:ChatPrint("Sauvegarde forcée!")
    else
        print("Sauvegarde forcée!")
    end
end)

-- Voir l'emplacement du fichier
concommand.Add("lg_show_json", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Vous devez être admin!")
        return
    end
    
    local data = LoadAllPlayersData()
    local output = "garrysmod/data/" .. PLAYERS_FILE
    
    if IsValid(ply) then
        ply:ChatPrint("Fichier : " .. output)
        ply:ChatPrint("Joueurs : " .. table.Count(data))
        
        for steamid, buildings in pairs(data) do
            ply:ChatPrint("  - " .. steamid .. " : " .. table.Count(buildings) .. " bâtiment(s)")
        end
    else
        print("Fichier : " .. output)
        print("Joueurs : " .. table.Count(data))
        
        for steamid, buildings in pairs(data) do
            print("  - " .. steamid .. " : " .. table.Count(buildings) .. " bâtiment(s)")
        end
    end
end)

print("[legendary_money_fabric] Système de sauvegarde JSON chargé (SteamID32)!")
