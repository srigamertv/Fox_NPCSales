# Fox_NPCSales

Sistema de venda de mercadorias para NPCs no RedM, com suporte a **VORP** e **RSG**.

## 🔥 Funcionalidades

- Venda de itens configuráveis para NPCs.
- Preço individual por item.
- Chance configurável do NPC aceitar ou recusar a venda.
- Quantidade mínima de policiais online.
- Chance de alerta para policiais.
- Blip temporário de denúncia.
- Validação server-side de distância, item, cooldown e pagamento.
- Logs opcionais por webhook.
- Framework automático por `Config.Framework = "auto"`.

## 🛠️ Instalação

1. Coloque a pasta `Fox_NPCSales` em `resources`.
2. Adicione no `server.cfg`:

```cfg
ensure Fox_NPCSales
```

3. Configure os itens, preços, empregos policiais e locais em `shared/config.lua`.

## 📦 Dependências

### VORP
- `vorp_core`
- `vorp_inventory`

### RSG
- `rsg-core`
- `rsg-inventory`

## ⚙️ Configuração

Os itens vendidos ficam em:

```lua
Config.Items = {
    water = {
        label = "Água",
        price = 10,
    },
}
```

Os locais válidos ficam em `Config.SaleLocations` e o raio em `Config.SaleRadius`.

## ✍️ Créditos

Desenvolvido e adaptado por **SR.IGAMER TV | FOX**.

<br>

**MINHA LOJA:**
<div>
  <a href="https://discord.gg/ySk8WVzY5n" target="_blank"><img src="https://img.shields.io/badge/Discord-7289DA?style=for-the-badge&logo=discord&logoColor=white" target="_blank"></a>
</div>

<br>

**Siga-nos:**
<div>
  <a href="https://www.youtube.com/@SRIGAMERTV" target="_blank"><img src="https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white" target="_blank"></a>
  <a href="https://www.instagram.com/sr.igamer_tv" target="_blank"><img src="https://img.shields.io/badge/-Instagram-%23E4405F?style=for-the-badge&logo=instagram&logoColor=white" target="_blank"></a>
  <a href="https://discord.gg/kh2KTGvaVX" target="_blank"><img src="https://img.shields.io/badge/Discord-7289DA?style=for-the-badge&logo=discord&logoColor=white" target="_blank"></a>
</div>

<br>

**Entrar-contato:**
<div>
  <a href="mailto:kelvinsom22kb@gmail.com"><img src="https://img.shields.io/badge/-Gmail-%23333?style=for-the-badge&logo=gmail&logoColor=white" target="_blank"></a>
</div>

## 🛡️ Licença

Distribuído sob a licença MIT. Consulte o arquivo `LICENSE`.
