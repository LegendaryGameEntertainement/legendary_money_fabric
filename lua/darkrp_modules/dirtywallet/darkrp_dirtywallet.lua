-- darkrp_dirtywallet.lua

if SERVER then
    AddCSLuaFile("cl_dirtywallet.lua")
    include("sh_dirtywallet.lua")
    include("sv_dirtywallet.lua")
end

if CLIENT then
    include("cl_dirtywallet.lua")
end
