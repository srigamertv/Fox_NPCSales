Config = {}

-- Framework: "auto", "vorp" ou "rsg".
-- Em "auto", o recurso detecta qual framework está iniciado.
Config.Framework = "auto"

-- Itens que podem ser vendidos para NPCs.
-- O preço é pago por 1 unidade vendida.
Config.Items = {
    water = {
        label = "Água",
        price = 10,
    },
    marihuana = {
        label = "Maconha",
        price = 20,
    },
}

-- Quantidade mínima de policiais online necessária para permitir a venda.
Config.RequiredPolice = 0

-- Jobs considerados como polícia.
Config.PoliceJobs = {}

-- Chance de o NPC aceitar a venda.
Config.SuccessRate = 50

-- Chance de a tentativa gerar um alerta para a polícia.
Config.PoliceAlertChance = 100

-- Texto e tecla do prompt.
Config.PromptName = "Vender Mercadorias"
Config.PromptKey = 0xCEFD9220 -- E
Config.InteractionDistance = 2.5

-- Tempo mínimo entre tentativas do mesmo jogador.
Config.ServerCooldown = 2 -- segundos

Config.SaleLocations = {
    { x = -799.94,  y = -1314.05, z = 43.58 },  -- Blackwater
    { x = -309.17,  y = 789.33,   z = 117.69 }, -- Valentine
    { x = 1342.84,  y = -1311.97, z = 76.49 },  -- Rhodes
    { x = 2664.50,  y = -1267.08, z = 52.17 },  -- Saint Denis
    { x = 2928.99,  y = 1339.90,  z = 44.00 },  -- Annesburg
    { x = -1804.55, y = -390.63,  z = 158.81 }, -- Strawberry
    { x = -3674.27, y = -2611.69, z = -14.08 }, -- Armadillo
    { x = -5511.55, y = -2940.39, z = -2.05 },  -- Tumbleweed
}

Config.SaleRadius = 999.0

Config.Messages = {
    noItems = "Você não possui nenhuma mercadoria para vender.",
    noPolice = "Não há policiais suficientes em serviço para realizar a venda.",
    refused = "O NPC recusou a mercadoria.",
    sold = "Você vendeu %sx %s por $%s.",
    tooFar = "Você está fora da área permitida para vender mercadorias.",
    invalidTarget = "Este NPC não pode receber a mercadoria.",
    policeAlert = "Uma possível venda ilegal foi denunciada.",
}

Config.PoliceBlip = {
    enabled = true,
    radius = 25.0,
    duration = 60000,
    sprite = -1282792512,
}

Config.Webhook = ""
Config.WebhookName = "Fox NPC Sales"
