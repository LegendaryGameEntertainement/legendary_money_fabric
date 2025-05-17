-- sv_dirtywallet.lua

local function getDirtyMoney(ply)
    return DarkRP.getDirtyMoney(ply)
end

local function setDirtyMoney(ply, amount)
    DarkRP.setDirtyMoney(ply, amount)
end

local function addDirtyMoney(ply, amount)
    local current = getDirtyMoney(ply)
    setDirtyMoney(ply, current + amount)
end

local function removeDirtyMoney(ply, amount)
    local current = getDirtyMoney(ply)
    setDirtyMoney(ply, current - amount)
end

local PLAYER = FindMetaTable("Player")
function PLAYER:GetDirtyMoney()
    return getDirtyMoney(self)
end
function PLAYER:SetDirtyMoney(amount)
    setDirtyMoney(self, amount)
end
function PLAYER:AddDirtyMoney(amount)
    addDirtyMoney(self, amount)
end
function PLAYER:RemoveDirtyMoney(amount)
    removeDirtyMoney(self, amount)
end


-- Gestion des commandes dans le chat
hook.Add("PlayerSay", "DirtyMoneyCommands", function(ply, text)
    local args = string.Explode(" ", text)

    if string.lower(args[1]) == "/dirtymoney" then
        local dm = ply:GetDirtyMoney()
        ply:ChatPrint("Vous avez "..DarkRP.formatMoney(dm).." en argent sale.")
        return "" -- empêche le message dans le chat
    end

    if string.lower(args[1]) == "/paydirty" then
        if #args < 3 then
            ply:ChatPrint("Usage : /paydirty <joueur> <montant>")
            return ""
        end

        local targetName = args[2]
        local amount = tonumber(args[3])
        if not amount or amount <= 0 then
            ply:ChatPrint("Montant invalide.")
            return ""
        end

        if ply:GetDirtyMoney() < amount then
            ply:ChatPrint("Vous n'avez pas assez d'argent sale.")
            return ""
        end

        local target = DarkRP.findPlayer(targetName)
        if not IsValid(target) then
            ply:ChatPrint("Joueur introuvable.")
            return ""
        end

        if target == ply then
            ply:ChatPrint("Vous ne pouvez pas vous payer vous-même.")
            return ""
        end

        ply:RemoveDirtyMoney(amount)
        target:AddDirtyMoney(amount)

        ply:ChatPrint("Vous avez donné "..DarkRP.formatMoney(amount).." d'argent sale à "..target:Nick()..".")
        target:ChatPrint("Vous avez reçu "..DarkRP.formatMoney(amount).." d'argent sale de "..ply:Nick()..".")
        return ""
    end
end)
