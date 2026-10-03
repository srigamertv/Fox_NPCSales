local prompt = nil
local promptGroup = nil
local promptTarget = nil
local busy = false
local lastSoldPed = nil

local function notify(message, notifyType, duration)
    duration = duration or 5000
    notifyType = notifyType or "inform"

    if GetResourceState("vorp_core") == "started" then
        local ok, core = pcall(function()
            return exports.vorp_core:GetCore()
        end)

        if ok and core and core.NotifyRightTip then
            core.NotifyRightTip(message, duration)
            return
        end
    end

    if GetResourceState("ox_lib") == "started" then
        TriggerEvent("ox_lib:notify", {
            description = message,
            type = notifyType,
            duration = duration,
        })
        return
    end

    if GetResourceState("rsg-core") == "started" then
        TriggerEvent("RSGCore:Notify", message, notifyType, duration)
        return
    end

    TriggerEvent("chat:addMessage", {
        args = { "NPC Sales", message },
    })
end

local function destroyPrompt()
    if prompt and PromptIsValid(prompt) then
        PromptDelete(prompt)
    end

    prompt = nil
    promptGroup = nil
    promptTarget = nil
end

local function createPrompt(targetPed)
    if prompt and PromptIsValid(prompt) and promptTarget == targetPed then
        return
    end

    destroyPrompt()

    promptGroup = Citizen.InvokeNative(0xB796970BD125FCE8, targetPed)
    promptTarget = targetPed
    prompt = PromptRegisterBegin()
    PromptSetControlAction(prompt, Config.PromptKey)
    PromptSetText(prompt, CreateVarString(10, "LITERAL_STRING", Config.PromptName))
    PromptSetEnabled(prompt, true)
    PromptSetVisible(prompt, true)
    Citizen.InvokeNative(0xCC6656799977741B, prompt, true)
    PromptSetGroup(prompt, promptGroup)
    PromptRegisterEnd(prompt)
end

local function isInsideSaleArea(coords)
    local radius = tonumber(Config.SaleRadius) or 0.0

    for i = 1, #Config.SaleLocations do
        local location = Config.SaleLocations[i]
        local dx = coords.x - location.x
        local dy = coords.y - location.y
        local dz = coords.z - location.z

        if (dx * dx + dy * dy + dz * dz) <= (radius * radius) then
            return true
        end
    end

    return false
end

local function getTargetPed()
    local playerId = PlayerId()

    if not Citizen.InvokeNative(0x4605C66E0F935F83, playerId) then
        return nil
    end

    local found, entity = GetPlayerTargetEntity(playerId)
    if not found or not entity or entity == 0 or not DoesEntityExist(entity) then
        return nil
    end

    if not IsEntityAPed(entity) or IsPedAPlayer(entity) then
        return nil
    end

    if IsEntityDead(entity) or not IsPedOnFoot(entity) or IsPedInMeleeCombat(entity) then
        return nil
    end

    local pedType = GetPedType(entity)
    if pedType ~= 4 and pedType ~= 5 then
        return nil
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(entity)

    if #(playerCoords - targetCoords) > (tonumber(Config.InteractionDistance) or 2.5) then
        return nil
    end

    if not isInsideSaleArea(playerCoords) then
        return nil
    end

    return entity
end

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then
        return true
    end

    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000

    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() >= timeout then
            return false
        end

        Wait(10)
    end

    return true
end

local function playExchangeAnimation(targetPed)
    local playerPed = PlayerPedId()
    local dict = "script_re@new_love@give_ring"
    local anim = "give_ring_player"

    SetBlockingOfNonTemporaryEvents(targetPed, true)
    TaskTurnPedToFaceEntity(targetPed, playerPed, 1500)
    TaskTurnPedToFaceEntity(playerPed, targetPed, 1500)
    Wait(1000)

    if loadAnimDict(dict) then
        TaskPlayAnim(targetPed, dict, anim, 1.0, 8.0, 5000, 1, 0.0, false, false, false)
        TaskPlayAnim(playerPed, dict, anim, 1.0, 8.0, 5000, 1, 0.0, false, false, false)
    end

    Wait(4000)
end

local function releaseTarget(targetPed)
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)

    if targetPed and DoesEntityExist(targetPed) then
        ClearPedTasks(targetPed)
        SetBlockingOfNonTemporaryEvents(targetPed, false)
        TaskWanderStandard(targetPed, 10.0, 10)
    end
end

local function attemptSale(targetPed)
    if busy or not targetPed or not DoesEntityExist(targetPed) then
        return
    end

    busy = true
    destroyPrompt()
    playExchangeAnimation(targetPed)

    if DoesEntityExist(targetPed) then
        local targetCoords = GetEntityCoords(targetPed)
        TriggerServerEvent("Fox_NPCSales:server:attemptSale", {
            x = targetCoords.x,
            y = targetCoords.y,
            z = targetCoords.z,
        })
    end

    lastSoldPed = targetPed
    releaseTarget(targetPed)
    busy = false
end

RegisterNetEvent("Fox_NPCSales:client:notify", function(message, notifyType, duration)
    notify(message, notifyType, duration)
end)

RegisterNetEvent("Fox_NPCSales:client:policeAlert", function(coords)
    notify(Config.Messages.policeAlert, "warning", 5000)

    if not Config.PoliceBlip.enabled or not coords then
        return
    end

    local blip = Citizen.InvokeNative(
        0x45F13B7E0A15C880,
        Config.PoliceBlip.sprite,
        coords.x + 0.0,
        coords.y + 0.0,
        coords.z + 0.0,
        Config.PoliceBlip.radius + 0.0
    )

    if blip and blip ~= 0 then
        SetTimeout(Config.PoliceBlip.duration, function()
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end)
    end
end)

CreateThread(function()
    while true do
        local waitTime = 250

        if not busy then
            local targetPed = getTargetPed()

            if targetPed then
                waitTime = 0

                if targetPed ~= lastSoldPed then
                    createPrompt(targetPed)

                    if prompt and PromptHasStandardModeCompleted(prompt) then
                        attemptSale(targetPed)
                    end
                else
                    destroyPrompt()
                end
            else
                destroyPrompt()
            end
        else
            destroyPrompt()
        end

        Wait(waitTime)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    destroyPrompt()
end)
