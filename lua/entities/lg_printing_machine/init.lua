AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local config = LegendaryMoneyFabric and LegendaryMoneyFabric.PrintingMachine
if not config then
    error("[legendary_money_fabric] Config LegendaryMoneyFabric.PrintingMachine is missing!")
end

-- Fonction pour absorber les entités de papier proches
local function CollectNearbyPaper(ent)
    local paperEntities = ents.FindInSphere(ent:GetPos(), LegendaryMoneyFabric.PrintingMachine.absorbRadius or 150) -- Rayon par défaut 150
    for _, paperEntity in ipairs(paperEntities) do
        if paperEntity:GetClass() == (config.paperEntity or "lg_paper") then -- Remplace "lg_paper" par le nom correct de l'entité papier
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
    self:SetModel("models/props_c17/consolebox03a.mdl")  -- Modèle de la machine
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self.PaperStock = 0 -- Stock de papier
    self:SetNWInt("PaperStock", self.PaperStock) -- Synchronise avec client
    self.isProducing = false
    self.productionEndTime = 0
end

-- Démarrer la production
function ENT:StartProduction()
    self.isProducing = true
    self.productionEndTime = CurTime() + config.productionTime -- Temps de production depuis la config
    self:SetNWFloat("ProductionEndTime", self.productionEndTime) -- Sync client
    self.PaperStock = 0 -- Reset stock
    self:SetNWInt("PaperStock", self.PaperStock)
end

-- Terminer la production
function ENT:FinishProduction()
    self.isProducing = false
    self:SetNWFloat("ProductionEndTime", 0) -- Reset timer

    -- Créer l'entité produite (ex: argent)
    local output = ents.Create("lg_uncut_money") -- Mets ici ton nom d'entité de sortie
    if IsValid(output) then
        local spawnPos = self:GetPos() + Vector(0, 0, 50)
        output:SetPos(spawnPos)
        output:Spawn()
    end
end

-- Fonction Think, appelée régulièrement
function ENT:Think()
    if not self.isProducing then
        CollectNearbyPaper(self)
    elseif CurTime() >= self.productionEndTime then
        self:FinishProduction()
    end

    self:NextThink(CurTime() + 1)
    return true
end
