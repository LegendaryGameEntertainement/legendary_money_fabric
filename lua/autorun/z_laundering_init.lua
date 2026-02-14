-- Chargement automatique du système de blanchiment
timer.Simple(0, function()
    -- Vérifier que la config est chargée
    if not LegendaryMoneyFabric or not LegendaryMoneyFabric.Laundering then
        ErrorNoHalt("[legendary_money_fabric] Configuration non chargée! Vérifiez sh_config.lua\n")
        return
    end
    
    if SERVER then
        print("[legendary_money_fabric] Système de blanchiment chargé avec " .. #LegendaryMoneyFabric.Laundering.buildings .. " bâtiment(s)")
        
        -- Commande pour voir ses bâtiments
        hook.Add("PlayerSay", "LG_LaunderingCommands", function(ply, text)
            local cmd = string.lower(text)
            
            if cmd == "!mybuildings" or cmd == "!mesbatiments" then
                local count = table.Count(ply.launderingBuildings or {})
                
                if count == 0 then
                    DarkRP.notify(ply, 0, 5, "Vous ne possédez aucun bâtiment de blanchiment.")
                else
                    ply:ChatPrint("═══════════════════════════════")
                    ply:ChatPrint("Vos bâtiments de blanchiment :")
                    ply:ChatPrint("═══════════════════════════════")
                    
                    for buildingID, _ in pairs(ply.launderingBuildings) do
                        for _, building in ipairs(LegendaryMoneyFabric.Laundering.buildings) do
                            if building.id == buildingID then
                                ply:ChatPrint("✓ " .. building.name)
                                break
                            end
                        end
                    end
                    
                    ply:ChatPrint("═══════════════════════════════")
                end
                
                return ""
            end
        end)
    else
        -- Côté client : vérifier que la config est bien chargée
        if LegendaryMoneyFabric and LegendaryMoneyFabric.Laundering then
            print("[legendary_money_fabric] Configuration client chargée avec " .. #LegendaryMoneyFabric.Laundering.buildings .. " bâtiment(s)")
        end
    end
end)
