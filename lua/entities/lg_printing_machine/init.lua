AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local config = LegendaryMoneyFabric and LegendaryMoneyFabric.PrintingMachine
if not config then
    error("[legendary_money_fabric] Config LegendaryMoneyFabric.PrintingMachine is missing!")
end

-- Fonction pour absorber les entités proches (papier et encre)
local function CollectNearbyResources(ent)
    local nearbyEntities = ents.FindInSphere(ent:GetPos(), config.absorbRadius or 150) -- Rayon par défaut 150
    for _, entity in ipairs(nearbyEntities) do
        local class = entity:GetClass()
        if class == (config.paperEntity or "lg_paper") then
            ent.PaperStock = ent.PaperStock + 1 -- Incrémente le stock de papier
            ent:SetNWInt("PaperStock", ent.PaperStock) -- Sync papier client
            entity:Remove() -- Supprime l'entité papier
        elseif class == (config.inkEntity or "lg_ink") then
            ent.InkStock = ent.InkStock + 1 -- Incrémente le stock d'encre
            ent:SetNWInt("InkStock", ent.InkStock) -- Sync encre client
            entity:Remove() -- Supprime l'entité encre
        end
    end

    -- Démarrer la production uniquement si on a assez de papier ET d'encre
    if not ent.isProducing and ent.PaperStock >= (config.requiredPaper or 1) and ent.InkStock >= (config.requiredInk or 1) then
        ent:StartProduction()
    end
end

-- Initialisation de l'entité
function ENT:Initialize()
    self:SetModel("models/props_c17/consolebox03a.mdl")  -- Modèle de la machine
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self.PaperStock = 0 -- Stock papier
    self.InkStock = 0 -- Stock encre
    self:SetNWInt("PaperStock", self.PaperStock)
    self:SetNWInt("InkStock", self.InkStock)

    self.isProducing = false
    self.productionEndTime = 0
end

-- Démarrer la production
function ENT:StartProduction()
    self.isProducing = true
    self.productionEndTime = CurTime() + (config.productionTime or 10) -- Temps de production depuis config
    self:SetNWFloat("ProductionEndTime", self.productionEndTime)
    -- on ne reset pas encore les stocks ici, on fera ça à la fin
end

-- Terminer la production
function ENT:FinishProduction()
    self.isProducing = false
    self:SetNWFloat("ProductionEndTime", 0)

    -- Créer l'entité produite (ex: argent)
    local output = ents.Create(config.outputEntity or "lg_uncut_money")
    if IsValid(output) then
        output:SetPos(self:GetPos() + Vector(0, 0, 50))
        output:Spawn()
    end

    -- Soustraire les ressources utilisées
    self.PaperStock = self.PaperStock - (config.requiredPaper or 1)
    if self.PaperStock < 0 then self.PaperStock = 0 end
    self.InkStock = self.InkStock - (config.requiredInk or 1)
    if self.InkStock < 0 then self.InkStock = 0 end

    self:SetNWInt("PaperStock", self.PaperStock)
    self:SetNWInt("InkStock", self.InkStock)

    -- Relancer la production automatiquement si on a encore assez de ressources
    if self.PaperStock >= (config.requiredPaper or 1) and self.InkStock >= (config.requiredInk or 1) then
        self:StartProduction()
    end
end

-- Fonction Think
function ENT:Think()
    if not self.isProducing then
        CollectNearbyResources(self)
    elseif CurTime() >= self.productionEndTime then
        self:FinishProduction()
    end

    self:NextThink(CurTime() + 1)
    return true
end
