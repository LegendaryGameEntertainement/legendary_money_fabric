if SERVER then
    include("darkrp_modules/dirtywallet/darkrp_dirtywallet.lua")
    AddCSLuaFile("darkrp_modules/dirtywallet/cl_dirtywallet.lua")
end

if CLIENT then
    include("darkrp_modules/dirtywallet/cl_dirtywallet.lua")
end
