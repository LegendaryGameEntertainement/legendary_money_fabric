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
}
