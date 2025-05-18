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

hook.Add("PlayerSay", "OpenZoneMenuCommand", function(ply, text)
    if string.StartWith(text, "!createzone") then
        net.Start("OpenZoneCreationMenu")
        net.Send(ply)
        return ""
    end
end)