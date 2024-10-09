AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Configuration
local config = {
    requiredPaper = 2,  -- Nombre de papiers requis pour démarrer la production
    productionTime = 10, -- Temps en secondes pour produire l'entité finale
    paperEntity = "lg_paper", -- Nom de l'entité papier acceptée par la machine
    outputEntity = "lg_uncut_money", -- Nom de l'entité produite par la machine
    absorbRadius = 300, -- Rayon de détection pour absorber les papiers (300 unités)
}

-- Fonction pour absorber les entités de papier proches
local function CollectNearbyPaper(ent)
    local paperEntities = ents.FindInSphere(ent:GetPos(), config.absorbRadius) -- Trouve les entités dans un rayon
    for _, paperEntity in ipairs(paperEntities) do
        if paperEntity:GetClass() == config.paperEntity then
            ent.PaperStock = ent.PaperStock + 1 -- Incrémente le stock de papier
            ent:SetNWInt("PaperStock", ent.PaperStock) -- Synchronise le stock de papier avec le client
            paperEntity:Remove() -- Supprime l'entité de papier

            -- Démarrer la production quand le nombre requis de papiers est atteint
            if ent.PaperStock >= config.requiredPaper and not ent.isProducing then
                ent:StartProduction()
            end
        end
    end
end

-- Initialisation de l'entité
function ENT:Initialize()
    self:SetModel("models/props_c17/consolebox01a.mdl")  -- Change this to the model of your machine
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self.PaperStock = 0 -- Stock de papier
    self:SetNWInt("PaperStock", self.PaperStock) -- Initialise la valeur sur le réseau pour le client
    self.isProducing = false
    self.productionEndTime = 0
end

-- Démarrer la production
function ENT:StartProduction()
    self.isProducing = true
    self.productionEndTime = CurTime() + config.productionTime -- Définir l'heure de fin de production
    self:SetNWFloat("ProductionEndTime", self.productionEndTime) -- Envoyer l'info de temps au client
    self.PaperStock = 0 -- Réinitialiser le stock de papier après le début de la production
    self:SetNWInt("PaperStock", self.PaperStock) -- Réinitialiser le stock de papier sur le réseau
end

-- Terminer la production
function ENT:FinishProduction()
    self.isProducing = false
    self:SetNWFloat("ProductionEndTime", 0) -- Réinitialiser le temps de production pour le client

    -- Créer l'entité finale après production (ex: argent)
    local output = ents.Create(config.outputEntity)
    if IsValid(output) then
        -- Positionner l'entité produite au-dessus de la machine
        local spawnPos = self:GetPos() + Vector(0, 0, 50) -- 50 unités au-dessus de la machine (ajuste la hauteur si nécessaire)
        output:SetPos(spawnPos)
        output:Spawn()
    end
end

-- Fonction appelée à chaque cycle de mise à jour (serveur)
function ENT:Think()
    -- Si la machine ne produit pas encore, elle absorbe les papiers autour d'elle
    if not self.isProducing then
        CollectNearbyPaper(self) -- Absorbe les papiers
    -- Si la machine est en production, vérifier si le temps est écoulé
    elseif CurTime() >= self.productionEndTime then
        self:FinishProduction() -- Terminer la production
    end

    -- Exécuter la fonction `Think` toutes les secondes
    self:NextThink(CurTime() + 1)
    return true
end
