AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Configuration
local config = {
    requiredItems = 2,  -- Nombre d'entités nécessaires pour lancer le lavage
    washingTime = 25, -- Temps en secondes pour laver l'entité
    inputEntity = "lg_cut_money", -- L'entité absorbée par la machine à laver (issue du slicer)
    outputEntity = "lg_clean_money", -- L'entité donnée en sortie après lavage
    absorbRadius = 150, -- Rayon de détection pour absorber l'entité
}

-- Fonction pour absorber les entités proches
local function CollectNearbyItems(ent)
    local nearbyEntities = ents.FindInSphere(ent:GetPos(), config.absorbRadius) -- Cherche dans un rayon de 150 unités
    for _, entity in ipairs(nearbyEntities) do
        if entity:GetClass() == config.inputEntity then
            ent.ItemStock = ent.ItemStock + 1 -- Incrémente le stock d'entités
            ent:SetNWInt("ItemStock", ent.ItemStock) -- Synchronise le stock avec le client
            entity:Remove() -- Supprime l'entité absorbée

            -- Si le stock est suffisant, démarrer le lavage
            if ent.ItemStock >= config.requiredItems and not ent.isWashing then
                ent:StartWashing()
            end
        end
    end
end

-- Initialisation de l'entité
function ENT:Initialize()
    self:SetModel("models/props_wasteland/laundry_washer001a.mdl")  -- Modèle de la machine à laver
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self.ItemStock = 0 -- Stock d'entités
    self:SetNWInt("ItemStock", self.ItemStock) -- Initialise le stock sur le réseau
    self.isWashing = false
    self.washingEndTime = 0
end

-- Démarrer le lavage
function ENT:StartWashing()
    self.isWashing = true
    self.washingEndTime = CurTime() + config.washingTime -- Définir l'heure de fin de lavage
    self:SetNWFloat("WashingEndTime", self.washingEndTime) -- Envoyer le temps au client
    self.ItemStock = 0 -- Réinitialiser le stock après le début du lavage
    self:SetNWInt("ItemStock", self.ItemStock) -- Mettre à jour le stock sur le réseau
end

-- Terminer le lavage et donner l'entité finale
function ENT:FinishWashing()
    self.isWashing = false
    self:SetNWFloat("WashingEndTime", 0) -- Réinitialiser le temps de lavage pour le client

    -- Créer l'entité finale après lavage (ex: clean_money)
    local output = ents.Create(config.outputEntity)
    if IsValid(output) then
        local spawnPos = self:GetPos() + Vector(0, 0, 50) -- Positionner l'entité au-dessus de la machine à laver
        output:SetPos(spawnPos)
        output:Spawn()
    end
end

-- Fonction appelée à chaque cycle de mise à jour (serveur)
function ENT:Think()
    -- Si la machine à laver n'est pas en lavage, elle absorbe les entités proches
    if not self.isWashing then
        CollectNearbyItems(self) -- Absorbe les entités
    -- Si la machine est en lavage, vérifier si le temps est écoulé
    elseif CurTime() >= self.washingEndTime then
        self:FinishWashing() -- Terminer le lavage
    end

    -- Exécuter la fonction `Think` toutes les secondes
    self:NextThink(CurTime() + 1)
    return true
end
