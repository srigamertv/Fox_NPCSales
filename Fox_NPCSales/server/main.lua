local Framework = {
    name = nil,
    core = nil,
}

local playerCooldowns = {}

local function notify(source, message, notifyType, duration)
    TriggerClientEvent(
        "Fox_NPCSales:client:notify",
        source,
        message,
        notifyType or "inform",
        duration or 5000
    )
end

local function detectFramework()
    local configured = string.lower(tostring(Config.Framework or "auto"))

    if configured == "vorp" then
        if GetResourceState("vorp_core") ~= "started" then
            return false
        end
        Framework.name = "vorp"
    elseif configured == "rsg" then
        if GetResourceState("rsg-core") ~= "started" then
            return false
        end
        Framework.name = "rsg"
    else
        if GetResourceState("vorp_core") == "started" then
            Framework.name = "vorp"
        elseif GetResourceState("rsg-core") == "started" then
            Framework.name = "rsg"
        else
            return false
        end
    end

    if Framework.name == "vorp" then
        Framework.core = exports.vorp_core:GetCore()
    else
        Framework.core = exports["rsg-core"]:GetCoreObject()
    end

    print(("[%s] Framework detectado: %s"):format(GetCurrentResourceName(), Framework.name:upper()))
    return true
end

CreateThread(function()
    while not detectFramework() do
        print(("[%s] Aguardando VORP ou RSG iniciar..."):format(GetCurrentResourceName()))
        Wait(3000)
    end
end)

local function getPlayerData(source)
    if not Framework.name or not Framework.core then
        return nil
    end

    if Framework.name == "vorp" then
        local user = Framework.core.getUser(source)
        if not user then
            return nil
        end

        local character = user.getUsedCharacter
        if not character then
            return nil
        end

        return {
            raw = character,
            job = character.job,
            name = (character.firstname or "") .. " " .. (character.lastname or ""),
        }
    end

    local player = Framework.core.Functions.GetPlayer(source)
    if not player then
        return nil
    end

    local data = player.PlayerData or {}
    local charinfo = data.charinfo or {}
    local job = data.job or {}

    return {
        raw = player,
        job = job.name,
        name = (charinfo.firstname or "") .. " " .. (charinfo.lastname or ""),
    }
end

local function getItemCount(source, itemName, playerData)
    if Framework.name == "vorp" then
        local ok, count = pcall(function()
            return exports.vorp_inventory:getItemCount(source, nil, itemName)
        end)

        if ok then
            return tonumber(count) or 0
        end

        return 0
    end

    local ok, count = pcall(function()
        return exports["rsg-inventory"]:GetItemCount(source, itemName)
    end)

    if ok and count ~= nil then
        return tonumber(count) or 0
    end

    if playerData and playerData.raw and playerData.raw.Functions.GetItemByName then
        local item = playerData.raw.Functions.GetItemByName(itemName)
        return item and tonumber(item.amount) or 0
    end

    return 0
end

local function removeItem(source, itemName, amount, playerData)
    if Framework.name == "vorp" then
        local ok, result = pcall(function()
            return exports.vorp_inventory:subItem(source, itemName, amount)
        end)

        return ok and result ~= false
    end

    local ok, result = pcall(function()
        return exports["rsg-inventory"]:RemoveItem(
            source,
            itemName,
            amount,
            nil,
            "fox-npcsales-sale"
        )
    end)

    if ok then
        return result ~= false
    end

    if playerData and playerData.raw and playerData.raw.Functions.RemoveItem then
        return playerData.raw.Functions.RemoveItem(itemName, amount) ~= false
    end

    return false
end

local function addCash(playerData, amount)
    if Framework.name == "vorp" then
        playerData.raw.addCurrency(0, amount)
        return true
    end

    return playerData.raw.Functions.AddMoney(
        "cash",
        amount,
        "fox-npcsales-sale"
    ) ~= false
end

local function isPoliceJob(jobName)
    if not jobName then
        return false
    end

    if Config.PoliceJobs[jobName] == true then
        return true
    end

    for _, configuredJob in ipairs(Config.PoliceJobs) do
        if configuredJob == jobName then
            return true
        end
    end

    return false
end

local function getPolicePlayers()
    local police = {}

    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        local data = id and getPlayerData(id) or nil

        if data and isPoliceJob(data.job) then
            police[#police + 1] = id
        end
    end

    return police
end

local function getServerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then
        return nil
    end

    local coords = GetEntityCoords(ped)
    if not coords then
        return nil
    end

    return { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 }
end

local function distanceSquared(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

local function isInsideSaleArea(coords)
    if not coords then
        return false
    end

    local radius = tonumber(Config.SaleRadius) or 0.0
    local radiusSquared = radius * radius

    for i = 1, #Config.SaleLocations do
        if distanceSquared(coords, Config.SaleLocations[i]) <= radiusSquared then
            return true
        end
    end

    return false
end

local function chooseSellableItem(source, playerData)
    local available = {}

    for itemName, itemConfig in pairs(Config.Items) do
        local price = tonumber(itemConfig.price)

        if price and price > 0 and getItemCount(source, itemName, playerData) > 0 then
            available[#available + 1] = {
                name = itemName,
                label = itemConfig.label or itemName,
                price = price,
            }
        end
    end

    if #available == 0 then
        return nil
    end

    return available[math.random(1, #available)]
end

local function sendPoliceAlert(coords, policePlayers)
    local alertChance = math.max(0, math.min(100, tonumber(Config.PoliceAlertChance) or 0))

    if alertChance <= 0 or math.random(1, 100) > alertChance then
        return
    end

    for i = 1, #policePlayers do
        TriggerClientEvent("Fox_NPCSales:client:policeAlert", policePlayers[i], coords)
    end
end

local function webhookSale(source, playerData, item, amount, total)
    local webhook = tostring(Config.Webhook or "")
    if webhook == "" then
        return
    end

    local payload = {
        username = Config.WebhookName or "Venda NPC",
        embeds = {
            {
                title = "Mercadoria vendida para NPC",
                description = table.concat({
                    ("**Jogador:** %s"):format(playerData.name ~= " " and playerData.name or GetPlayerName(source) or "Desconhecido"),
                    ("**Item:** %s"):format(item.label),
                    ("**Quantidade:** %d"):format(amount),
                    ("**Valor:** $%s"):format(total),
                    ("**Framework:** %s"):format(Framework.name or "desconhecido"),
                }, "\n"),
                color = 5763719,
            },
        },
    }

    PerformHttpRequest(webhook, function() end, "POST", json.encode(payload), {
        ["Content-Type"] = "application/json",
    })
end

RegisterNetEvent("Fox_NPCSales:server:attemptSale", function(clientTargetCoords)
    local source = source

    if not Framework.name or not Framework.core then
        return
    end

    local now = os.time()
    local cooldown = math.max(0, tonumber(Config.ServerCooldown) or 0)
    local lastAttempt = playerCooldowns[source] or 0

    if now - lastAttempt < cooldown then
        return
    end

    playerCooldowns[source] = now

    local playerData = getPlayerData(source)
    if not playerData then
        return
    end

    local playerCoords = getServerCoords(source)
    if not isInsideSaleArea(playerCoords) then
        notify(source, Config.Messages.tooFar, "error")
        return
    end

    if type(clientTargetCoords) ~= "table"
        or type(clientTargetCoords.x) ~= "number"
        or type(clientTargetCoords.y) ~= "number"
        or type(clientTargetCoords.z) ~= "number"
        or distanceSquared(playerCoords, clientTargetCoords) > ((Config.InteractionDistance + 1.5) ^ 2)
    then
        notify(source, Config.Messages.invalidTarget, "error")
        return
    end

    local policePlayers = getPolicePlayers()
    local requiredPolice = math.max(0, tonumber(Config.RequiredPolice) or 0)

    if #policePlayers < requiredPolice then
        notify(source, Config.Messages.noPolice, "error")
        return
    end

    sendPoliceAlert(playerCoords, policePlayers)

    local item = chooseSellableItem(source, playerData)
    if not item then
        notify(source, Config.Messages.noItems, "error")
        return
    end

    local successRate = math.max(0, math.min(100, tonumber(Config.SuccessRate) or 0))
    if math.random(1, 100) > successRate then
        notify(source, Config.Messages.refused, "error")
        return
    end

    local amount = 1
    if getItemCount(source, item.name, playerData) < amount then
        notify(source, Config.Messages.noItems, "error")
        return
    end

    if not removeItem(source, item.name, amount, playerData) then
        notify(source, Config.Messages.noItems, "error")
        return
    end

    local total = math.floor((item.price * amount) * 100 + 0.5) / 100
    addCash(playerData, total)

    notify(source, Config.Messages.sold:format(amount, item.label, total), "success")
    webhookSale(source, playerData, item, amount, total)
end)

AddEventHandler("playerDropped", function()
    playerCooldowns[source] = nil
end)
