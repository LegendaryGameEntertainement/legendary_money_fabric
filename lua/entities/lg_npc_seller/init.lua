AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Configuration
local config = LegendaryMoneyFabric and LegendaryMoneyFabric.PNJ
if not config then
    error("[legendary_money_fabric] Config LegendaryMoneyFabric.PNJ is missing!")
end


-- Fonction pour vérifier si une entité "clean_money" est à proximité
local function FindNearbyCleanMoney(ply, pnj)
    local nearbyEntities = ents.FindInSphere(pnj:GetPos(), config.sellRadius)
    for _, ent in ipairs(nearbyEntities) do
        if ent:GetClass() == config.cleanMoneyEntity then
            return ent -- Retourne l'entité "clean_money" trouvée
        end
    end
    return nil -- Aucune entité "clean_money" n'a été trouvée
end

-- Initialisation du PNJ
function ENT:Initialize()
    self:SetModel("models/Humans/Group01/male_02.mdl")  -- Modèle du PNJ
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetNPCState(NPC_STATE_SCRIPT)
    self:SetSolid(SOLID_BBOX)
    self:CapabilitiesAdd(CAP_ANIMATEDFACE, CAP_TURN_HEAD)
    self:SetUseType(SIMPLE_USE)
    self:DropToFloor()
end

-- Fonction appelée lorsque le joueur interagit avec le PNJ (appuie sur "E")
function ENT:Use(activator, caller)
    if IsValid(caller) and caller:IsPlayer() then
        local cleanMoney = FindNearbyCleanMoney(caller, self) -- Vérifie s'il y a de l'argent propre près du PNJ

        if cleanMoney then
            -- Supprime l'entité "clean_money"
            cleanMoney:Remove()

            -- Calcul d'une récompense aléatoire entre le minimum et le maximum
            local reward = math.random(config.moneyMin, config.moneyMax)

            -- Donne l'argent au joueur
            caller:AddDirtyMoney(reward)  -- Remplace cette ligne par le système d'argent de ton serveur (DarkRP par exemple)

            -- Envoie un message au joueur
            caller:ChatPrint("Vous avez vendu de l'argent sale pour " .. reward .. " $ !")
        else
            -- Aucune entité "clean_money" à proximité
            caller:ChatPrint("Vous n'avez pas d'argent propre à vendre.")
        end
    end
end
