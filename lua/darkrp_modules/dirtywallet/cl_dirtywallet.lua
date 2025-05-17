-- cl_dirtywallet.lua

local dirtyMoneyAmount = 0

net.Receive("DirtyMoneyUpdated", function()
    local ply = LocalPlayer()
    dirtyMoneyAmount = ply:GetNWInt("DirtyMoney", 0) -- fallback si besoin
end)


