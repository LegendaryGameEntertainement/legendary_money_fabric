-- sh_dirtywallet.lua

if SERVER then
    util.AddNetworkString("DirtyMoneyUpdated")
end

-- Ajoute ou récupère l'argent sale dans le PData du joueur
local function getDirtyMoney(ply)
    local dm = ply:GetPData("dirty_money", "0")
    return tonumber(dm) or 0
end

local function setDirtyMoney(ply, amount)
    ply:SetPData("dirty_money", tostring(math.max(0, math.floor(amount))))
    -- Notifier client pour mise à jour HUD
    net.Start("DirtyMoneyUpdated")
    net.Send(ply)
end

-- Méthodes utiles accessibles depuis sv_dirtywallet.lua
DarkRP = DarkRP or {}
DarkRP.getDirtyMoney = getDirtyMoney
DarkRP.setDirtyMoney = setDirtyMoney
