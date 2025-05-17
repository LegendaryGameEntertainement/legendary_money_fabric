AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local config = LegendaryMoneyFabric and LegendaryMoneyFabric.Slicer
if not config then
    error("[legendary_money_fabric] Config LegendaryMoneyFabric.Slicer is missing!")
end

-- Fonction pour absorber les entités proches
local function CollectNearbyItems(ent)
    local nearbyEntities = ents.FindInSphere(ent:GetPos(), config.absorbRadius or 150) -- Valeur par défaut 150
    for _, entity in ipairs(nearbyEntities) do
        if entity:GetClass() == (config.inputEntity or "lg_uncut_money") then
            ent.ItemStock = ent.ItemStock + 1 -- Incrémente le stock d'entités
            ent:SetNWInt("ItemStock", ent.ItemStock) -- Synchronise le stock avec le client
            entity:Remove() -- Supprime l'entité absorbée

            -- Si le stock est suffisant, démarrer la transformation
            if ent.ItemStock >= config.requiredItems and not ent.isTransforming then
                ent:StartTransformation()
            end
        end
    end
end

-- Initialisation de l'entité
function ENT:Initialize()
    self:SetModel("models/props_c17/oildrum001.mdl")  -- Modèle du slicer
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self.ItemStock = 0 -- Stock d'entités
    self:SetNWInt("ItemStock", self.ItemStock) -- Initialise le stock sur le réseau
    self.isTransforming = false
    self.transformationEndTime = 0
end

-- Démarrer la transformation
function ENT:StartTransformation()
    self.isTransforming = true
    self.transformationEndTime = CurTime() + (config.transformationTime or 5) -- Définir l'heure de fin de transformation
    self:SetNWFloat("TransformationEndTime", self.transformationEndTime) -- Envoyer le temps au client
    self.ItemStock = 0 -- Réinitialiser le stock
    self:SetNWInt("ItemStock", self.ItemStock) -- Mettre à jour le stock sur le réseau
end

-- Terminer la transformation et donner l'entité finale
function ENT:FinishTransformation()
    self.isTransforming = false
    self:SetNWFloat("TransformationEndTime", 0) -- Réinitialiser le temps de transformation pour le client

    -- Créer l'entité finale après transformation (ex: billets coupés)
    local output = ents.Create(config.outputEntity or "lg_cut_money") -- Nom par défaut
    if IsValid(output) then
        local spawnPos = self:GetPos() + Vector(0, 0, 50) -- Positionner l'entité au-dessus du slicer
        output:SetPos(spawnPos)
        output:Spawn()
    end
end

-- Fonction appelée à chaque cycle de mise à jour (serveur)
function ENT:Think()
    -- Si le slicer n'est pas en transformation, il absorbe les entités proches
    if not self.isTransforming then
        CollectNearbyItems(self) -- Absorbe les entités
    -- Si le slicer est en transformation, vérifier si le temps est écoulé
    elseif CurTime() >= self.transformationEndTime then
        self:FinishTransformation() -- Terminer la transformation
    end

    -- Exécuter la fonction `Think` toutes les secondes
    self:NextThink(CurTime() + 1)
    return true
end
