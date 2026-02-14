LegendaryMoneyFabric = LegendaryMoneyFabric or {}

-- Config pour la printing machine
LegendaryMoneyFabric.PrintingMachine = {
    requiredPaper = 2,  -- Nombre de papiers requis pour démarrer la production
    requiredInk = 1,
    productionTime = 10, -- Temps en secondes pour produire l'entité finale
}

-- Config pour le slicer
LegendaryMoneyFabric.Slicer = {
    requiredItems = 1,  -- Nombre d'entités nécessaires pour lancer la transformation
    transformationTime = 10, -- Temps en secondes pour transformer l'entité
    absorbRadius = 150, -- Rayon de détection pour absorber l'entité
}

-- Config pour la machine à laver
LegendaryMoneyFabric.WashingMachine = {
    requiredItems = 1,  -- Nombre d'entités nécessaires pour lancer le lavage
    washingTime = 10, -- Temps en secondes pour laver l'entité
    absorbRadius = 150, -- Rayon de détection pour absorber l'entité
}

-- Config pour le PNJ vendeur
LegendaryMoneyFabric.PNJ = {
    sellRadius = 100,  -- Rayon autour du PNJ pour détecter les entités "clean_money"
    moneyMin = 100,    -- Montant minimum que le joueur peut recevoir
    moneyMax = 500,    -- Montant maximum que le joueur peut recevoir
    cleanMoneyEntity = "lg_clean_money",
}

//////////////////////////////////////////////////////
-- Configuration du système de blanchiment
//////////////////////////////////////////////////////


LegendaryMoneyFabric.Laundering = {
    -- NPC Vendeur
    vendorModel = "models/Humans/Group01/male_07.mdl",
    vendorName = "Vendeur de Bâtiments",
    
    -- Bâtiments disponibles à l'achat
    buildings = {
        {
            id = "laundromat",
            name = "Laverie Automatique",
            price = 50000, -- Prix en argent propre
            maxAmount = 100000, -- Montant max d'argent sale blanchissable
            launderTime = 1, -- Temps en minutes
            lossRate = 0.20, -- 20% de perte (1$ sale = 0.80$ propre)
            image = "UI/laundry.png"
        },
        {
            id = "carwash",
            name = "Station de Lavage",
            price = 75000,
            maxAmount = 150000,
            launderTime = 7,
            lossRate = 0.15,
            image = "materials/laundering/carwash.png"
        },
        {
            id = "postoffice",
            name = "Bureau de Poste",
            price = 100000,
            maxAmount = 200000,
            launderTime = 10,
            lossRate = 0.10,
            image = "materials/laundering/postoffice.png"
        },
        {
            id = "nightclub",
            name = "Boîte de Nuit",
            price = 150000,
            maxAmount = 300000,
            launderTime = 15,
            lossRate = 0.05,
            image = "materials/laundering/nightclub.png"
        },
        {
            id = "casino",
            name = "Casino",
            price = 250000,
            maxAmount = 500000,
            launderTime = 20,
            lossRate = 0.03,
            image = "materials/laundering/casino.png"
        }
    }
}

if SERVER then
    AddCSLuaFile()
end