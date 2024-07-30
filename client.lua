local cannonCoords = vector3(0.0, 0.0, 0.0) -- Coordonnées par défaut
local discordWebhookURL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN" -- Remplace par ton URL de webhook
local explosionType = 0 -- Type d'explosion par défaut
local explosionForce = 50.0 -- Force d'explosion agrandie
local visualScale = 3.0 -- Échelle visuelle agrandie
local ESX = nil

-- Récupérer l'instance ESX
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100) -- Attendre un moment pour que ESX soit correctement initialisé
    end
    print("ESX est initialisé")
end)

-- Fonction pour envoyer un message embed au webhook Discord
function SendDiscordLog(title, description)
    local data = {
        embeds = {{
            title = title,
            description = description,
            color = 16711680, -- Rouge (en hexadécimal : #FF0000)
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"), -- Date/heure en UTC
            footer = {
                text = "FiveM Server Logs"
            }
        }}
    }
    PerformHttpRequest(discordWebhookURL, function(err, text, headers) 
        if err ~= 204 then
            print("Erreur lors de l'envoi des logs à Discord : " .. tostring(err) .. " - " .. tostring(text))
        else
            print("Logs envoyés avec succès à Discord.")
        end
    end, 'POST', json.encode(data), { ['Content-Type'] = 'application/json' })
end

-- Fonction pour tirer une explosion
function FireExplosion(coords, explosionType)
    print("Tir de l'explosion demandé.")
    
    local playerPed = PlayerPedId()
    RequestNamedPtfxAsset("scr_xm_orbital")
    while not HasNamedPtfxAssetLoaded("scr_xm_orbital") do
        Wait(0)
    end

    -- Jouer l'effet visuel avec une échelle agrandie
    UseParticleFxAssetNextCall("scr_xm_orbital")
    local effect = StartParticleFxLoopedAtCoord("scr_xm_orbital_blast", coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, visualScale, false, false, false, false)
    print("Effet visuel démarré.")
    
    -- Jouer l'effet sonore de l'explosion
    PlaySoundFromCoord(-1, "DLC_XM_Explosions_Orbital_Cannon", coords.x, coords.y, coords.z, "dlc_xm_orbital_cannon_sounds", false, 0, false)
    print("Son de l'explosion joué.")
    
    Wait(3000) -- Attend un moment pour permettre à l'effet visuel de se terminer
    StopParticleFxLooped(effect, 0)
    print("Effet visuel arrêté.")

    -- Appliquer l'explosion avec un rayon plus grand
    AddExplosion(coords.x, coords.y, coords.z, explosionType, explosionForce, true, false, 1.0) -- `explosionForce` est le paramètre ajusté
    print("Explosion appliquée.")

    -- Envoyer un log à Discord
    SendDiscordLog(
        "Explosion Tirée",
        "Une explosion de type " .. explosionType .. " a été tirée aux coordonnées :\nX: " .. coords.x .. "\nY: " .. coords.y .. "\nZ: " .. coords.z .. "\nRayon de l'explosion : " .. explosionForce
    )
    ShowESXNotification("Explosion de type " .. explosionType .. " tirée.")
end

-- Fonction pour afficher une notification ESX
function ShowESXNotification(message)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(message)
        print("Notification ESX affichée : " .. message)
    else
        print("ESX ou ESX.ShowNotification n'est pas disponible.")
    end
end

-- Commande pour définir les coordonnées du canon orbital
RegisterCommand("setcannoncoords", function()
    local playerPed = PlayerPedId()
    cannonCoords = GetEntityCoords(playerPed)
    ShowESXNotification("Coordonnées du canon orbital définies à : " .. cannonCoords.x .. ", " .. cannonCoords.y .. ", " .. cannonCoords.z)
    SendDiscordLog(
        "Coordonnées du Canon Orbital Définies",
        "Les coordonnées du canon orbital ont été définies à :\nX: " .. cannonCoords.x .. "\nY: " .. cannonCoords.y .. "\nZ: " .. cannonCoords.z
    )
end, false)

-- Commande pour tirer une explosion avec un type spécifique
RegisterCommand("fireexplosion", function(source, args)
    local types = {
        [0] = "Explosion Standard",
        [1] = "Explosion Grenade",
        [2] = "Explosion Grenade Collante",
        [3] = "Explosion Dynamite",
        [4] = "Explosion Gaz",
        [5] = "Explosion Missile",
        [6] = "Explosion Roquette",
        [7] = "Explosion Vapeur",
        [8] = "Explosion Attaque",
        [9] = "Explosion Feux d'Artifice",
        [10] = "Explosion Alarme"
    } -- Liste des types d'explosion disponibles
    local typeIndex = tonumber(args[1])
    
    if typeIndex and types[typeIndex] then
        explosionType = typeIndex
        FireExplosion(cannonCoords, explosionType)
        ShowESXNotification("Explosion de type " .. types[typeIndex] .. "a atteint sa cible")
    else
        ShowESXNotification("Explosion de type " .. types[typeIndex] .. " a rater")
    end
end, false)
