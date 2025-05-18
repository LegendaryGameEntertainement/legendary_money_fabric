util.AddNetworkString("Zone_OpenMenu")
util.AddNetworkString("OpenZoneCreationMenu")
util.AddNetworkString("ZoneCreationData")

hook.Add("PlayerSay", "OpenZoneMenuCommand", function(ply, text)
    if string.StartWith(text, "!createzonemenu") then
        net.Start("OpenZoneCreationMenu")
        net.Send(ply)
        return ""
    end
end)

