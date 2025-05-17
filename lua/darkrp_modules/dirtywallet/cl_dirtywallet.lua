local dirtyMoneyAmount = 0

net.Receive("DirtyMoneyUpdated", function()
    dirtyMoneyAmount = net.ReadInt(32) or 0
end)

-- Fonction simple pour récupérer l'argent sale
function GetDirtyMoney()
    return dirtyMoneyAmount
end
