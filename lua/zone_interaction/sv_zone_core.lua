util.AddNetworkString("Zone_OpenMenu")

include("zone_interaction/sh_zone_config.lua")

local function SaveZones()
    file.CreateDir("interaction_zones")
    file.Write(ZONE.FilePath, util.TableToJSON(ZONE.Data, true))
end

local function LoadZones()
    if file.Exists(ZONE.FilePath, "DATA") then
        ZONE.Data = util.JSONToTable(file.Read(ZONE.FilePath, "DATA")) or {}
    end
end

hook.Add("Initialize", "Zone_LoadOnInit", LoadZones)

concommand.Add("zone_save", SaveZones)

hook.Add("PlayerSay", "Zone_ChatCommands", function(ply, text)
    if not ply:IsAdmin() then return end
    local args = string.Explode(" ", text)
    if args[1] == "!createzone" and args[2] then
        local name = args[2]
        ZONE.Data[name] = {
            pos = ply:GetPos(),
            radius = 150 -- rayon fixe
        }
        SaveZones()
        ply:ChatPrint("Zone '" .. name .. "' créée.")
        return ""
    elseif args[1] == "!deletezone" and args[2] then
        local name = args[2]
        if ZONE.Data[name] then
            ZONE.Data[name] = nil
            SaveZones()
            ply:ChatPrint("Zone '" .. name .. "' supprimée.")
        else
            ply:ChatPrint("Zone introuvable.")
        end
        return ""
    end
end)

hook.Add("KeyPress", "Zone_UseDetection", function(ply, key)
    if key ~= IN_USE then return end

    local pos = ply:GetPos()
    for name, zone in pairs(ZONE.Data) do
        if pos:DistToSqr(zone.pos) <= (zone.radius * zone.radius) then
            net.Start("Zone_OpenMenu")
            net.Send(ply)
            break
        end
    end
end)
