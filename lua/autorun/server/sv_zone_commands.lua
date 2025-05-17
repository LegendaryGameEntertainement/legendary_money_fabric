util.AddNetworkString("ZoneMenu")

local zoneFile = "zones.json"
local zones = {}

-- Chargement des zones existantes
if file.Exists(zoneFile, "DATA") then
    zones = util.JSONToTable(file.Read(zoneFile, "DATA")) or {}
end

local function saveZones()
    file.Write(zoneFile, util.TableToJSON(zones, true))
end

local function spawnZone(name, pos)
    local ent = ents.Create("zone_sphere")
    ent:SetPos(pos)
    ent:SetZoneName(name)
    ent:Spawn()
    ent:Activate()
end

hook.Add("InitPostEntity", "SpawnSavedZones", function()
    for name, data in pairs(zones) do
        spawnZone(name, Vector(unpack(data.pos)))
    end
end)

hook.Add("PlayerSay", "ZoneChatCommands", function(ply, text)
    local args = string.Explode(" ", text)

    if string.lower(args[1]) == "!createzone" then
        local name = args[2]
        if not name then
            ply:ChatPrint("Utilisation : !createzone [nom]")
            return ""
        end

        local trace = ply:GetEyeTrace()
        local pos = trace.HitPos

        if zones[name] then
            ply:ChatPrint("Une zone avec ce nom existe déjà.")
            return ""
        end

        zones[name] = { pos = { pos.x, pos.y, pos.z } }
        saveZones()
        spawnZone(name, pos)

        ply:ChatPrint("Zone '" .. name .. "' créée.")
        return ""
    end

    if string.lower(args[1]) == "!deletezone" then
        local name = args[2]
        if not zones[name] then
            ply:ChatPrint("Zone introuvable.")
            return ""
        end

        -- Supprime l'entité dans le monde
        for _, ent in ipairs(ents.FindByClass("zone_sphere")) do
            if ent:GetZoneName() == name then
                ent:Remove()
            end
        end

        zones[name] = nil
        saveZones()
        ply:ChatPrint("Zone '" .. name .. "' supprimée.")
        return ""
    end
end)
