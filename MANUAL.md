# mri_Qrobnpcs — Manual

Permite assaltar NPCs da cidade apontando uma arma para eles: o ped se rende, foge ou revida, e o assalto libera dinheiro e itens com chance configurável.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Configuração](#configuração)
4. [Fluxo do assalto](#fluxo-do-assalto)
5. [Proteções contra abuso](#proteções-contra-abuso)
6. [Integrações](#integrações)
7. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
8. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `ox_lib` | Sim | Cache, callbacks, `progressCircle`, notificações, `requestAnimDict` |
| `qbx_core` / `qb-core` | Não | Bridge QB (`bridge/*/qb.lua`) — job do jogador e evento de logout |
| `ox_core` | Não | Bridge OX (`bridge/*/ox.lua`) |
| `es_extended` | Não | Bridge ESX (`bridge/*/esx.lua`) |
| `qb-target` ou `ox_target` | Sim (padrão) | Opção "Roubar" no ped rendido, quando `useInteract = false` |
| `interact` | Não | Alternativa ao target, quando `useInteract = true` |
| `ox_inventory` | Não | Usado pelas funções `addCash` e `addItem` de fábrica em `configs/server.lua` |
| `ps-dispatch` | Não | Usado pela função `dispatch` de fábrica em `configs/client.lua` |

As bridges se auto-selecionam por `GetResourceState`: cada arquivo em `bridge/` só executa se o framework correspondente estiver iniciado. Pelo menos um framework precisa estar presente para as funções `getPlayerJob` e `isBlacklistedJob` existirem.

---

## Instalação

1. Copie a pasta `mri_Qrobnpcs` para `resources/`.
2. Adicione ao `server.cfg`:
   ```
   ensure mri_Qrobnpcs
   ```
3. Ajuste `configs/server.lua`: as funções `addCash` e `addItem` chamam `ox_inventory` por padrão. Se você usa outro inventário, troque o corpo dessas funções (o objeto do jogador já vem resolvido em `getPlayer(src)`).
4. Ajuste `configs/client.lua`: a função `dispatch` chama `exports['ps-dispatch']:CustomAlert`. Se usa outro dispatch, troque a chamada.
5. Garanta que os itens de `lootableItems` (`rolex`, `phone` de fábrica) existam no seu inventário.

Não há SQL. Não há comandos.

---

## Configuração

### `configs/shared.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `requiredCops` | number | Sim | Quantidade mínima de policiais online para permitir assaltos. `0` desativa a checagem (e também desativa o loop de contagem no servidor) |

### `configs/client.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `useInteract` | bool | Sim | `true` usa o recurso `interact`; `false` (padrão) usa `qb-target` |
| `targetDistance` | number | Sim | Distância máxima (m) em que o ped reage à mira; acima disso, um ped já rendido se levanta |
| `blacklistedJobs` | tabela de strings | Sim | Jobs proibidos de assaltar NPCs. Vazia por padrão |
| `robLength` | number | Sim | Duração da revista, em segundos |
| `chancePedFlees` | `{min, max}` | Sim | Faixa de chance (%) de o ped fugir em vez de se render |
| `chancePedFights` | `{min, max}` | Sim | Faixa de chance (%) de o ped partir para cima do jogador |
| `chancePedIsArmedWhileFighting` | `{min, max}` | Sim | Faixa de chance (%) de o ped que briga estar armado |
| `pedWeapons` | tabela de strings | Sim | Armas que o ped pode sacar ao brigar |
| `copsChance` | `{min, max}` | Sim | Faixa de chance (%) de a polícia ser acionada ao iniciar o assalto |
| `allowedWeapons` | tabela de strings | Sim | Armas que habilitam o assalto quando equipadas |
| `dispatch` | function(coords) | Sim | Função chamada quando a polícia é acionada |

### `configs/server.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `payOut` | `{min, max}` | Sim | Faixa de dinheiro pago por assalto bem-sucedido |
| `payOutChance` | `{min, max}` | Sim | Faixa de chance (%) de o NPC ter dinheiro. Se falhar, o jogador recebe a notificação "No Cash!" |
| `chanceItemsFound` | `{min, max}` | Sim | Faixa de chance (%) de o NPC ter itens |
| `lootableItems` | tabela | Sim | Itens saqueáveis. Cada entrada: `{ item = 'nome', min = 1, max = 2 }` — um deles é sorteado |
| `policeJobs` | tabela de strings | Sim | Jobs contados como polícia para o `requiredCops` |
| `addCash` | function(src, amount) | Sim | Entrega o dinheiro. Deve retornar valor verdadeiro em caso de sucesso |
| `addItem` | function(src, item, amount) | Sim | Entrega o item. Deve retornar valor verdadeiro em caso de sucesso |

As chances funcionam sempre da mesma forma: sorteia-se um limiar dentro da faixa `{min, max}` e depois um número de 1 a 100; se o número for menor ou igual ao limiar, o evento ocorre.

---

## Fluxo do assalto

1. O jogador equipa uma arma de `allowedWeapons`. Se o job dele estiver em `blacklistedJobs`, nada acontece.
2. Enquanto a arma está na mão, um loop verifica se ele está mirando (mira travada ou livre) em um ped humano válido dentro de `targetDistance`.
3. Após ~2 s mirando, o assalto começa: a polícia pode ser acionada (`copsChance`) e o ped é sorteado entre render-se, fugir (`chancePedFlees`) ou brigar (`chancePedFights`).
4. Se o ped se rende, ele levanta as mãos, é congelado e ganha a opção "Roubar" (target ou interact).
5. A revista roda um `progressCircle` de `robLength` segundos com a animação `random@shop_robbery / robbery_action_b`.
6. O servidor valida a distância (≤ 5 m), marca o ped como roubado e paga dinheiro e/ou item conforme as chances.
7. Ao terminar, o ped se levanta e sorteia de novo entre brigar (`chancePedFights`) e fugir.

Se o ped brigar, ele recebe atributos de combate agressivos, entra no grupo `HATES_PLAYER` e pode sacar uma arma de `pedWeapons`.

---

## Proteções contra abuso

- **Statebag `robbed`** — todo ped que foi assaltado, fugiu ou brigou recebe `Entity(ped).state.robbed`, e não pode mais ser alvo.
- **Peds de missão** — peds com `GetEntityPopulationType == 7` (criados por scripts) são ignorados.
- **Só humanos vivos e fora de veículo** — `IsPedHuman`, `IsPedDeadOrDying`, `IsPedInAnyVehicle` e `IsPedAPlayer` são checados.
- **Validação de distância no servidor** — o callback `xt-robnpcs:server:robNPC` recusa o pagamento se o jogador estiver a mais de 5 m do ped.
- **Contagem de policiais** — quando `requiredCops > 0`, o servidor recalcula `GlobalState.copCount` a cada 60 s e o client bloqueia o assalto abaixo do mínimo.
- **Limpeza** — ao dar logout ou parar o recurso, o ped sob assalto é liberado.

---

## Integrações

### ps-dispatch

A função `dispatch` de fábrica em `configs/client.lua` chama `exports["ps-dispatch"]:CustomAlert` com o alerta "Assalto à Cidadão" para o job `police`. Trocar de dispatch é só reescrever essa função.

### ox_inventory

As funções `addCash` e `addItem` em `configs/server.lua` chamam `exports.ox_inventory:AddItem` — o dinheiro é entregue como o item `money`. Os comentários no arquivo mostram a alternativa QB/QBX (`player.Functions.AddMoney` / `player.Functions.AddItem`).

### interact

Com `useInteract = true`, a opção "Roubar" é registrada via `exports.interact:AddEntityInteraction` em vez do target.

---

## Entrypoints para outros recursos

### Callback `xt-robnpcs:server:robNPC`

Executa o pagamento do assalto. Recebe o net ID do ped, valida a distância e marca o statebag `robbed`. Retorna `true` se o assalto foi concluído.

```lua
local robbed = lib.callback.await('xt-robnpcs:server:robNPC', false, netID)
```

### Evento `xt-robnpcs:client:onUnload`

Libera o ped que está sob assalto. É disparado pelas bridges no logout do jogador (`QBCore:Client:OnPlayerUnload`, `esx:onPlayerLogout`, `ox:playerLogout`).

```lua
TriggerEvent('xt-robnpcs:client:onUnload')
```

### GlobalState `copCount`

O servidor mantém `GlobalState.copCount` com o número de jogadores online cujo job está em `policeJobs`. Só é atualizado se `requiredCops > 0`.

---

## Estrutura de arquivos

```
mri_Qrobnpcs/
├── client/
│   ├── cl_main.lua      — loop de mira, reação do ped, revista, opções de target/interact
│   └── utils.lua        — animações, chances de brigar/fugir, dispatch, checagem de arma permitida
├── server/
│   └── sv_main.lua      — callback de pagamento, sorteio de dinheiro/itens, contagem de policiais
├── configs/
│   ├── shared.lua       — requiredCops
│   ├── client.lua       — target/interact, chances, armas, jobs bloqueados, função de dispatch
│   └── server.lua       — payout, itens saqueáveis, jobs de polícia, funções addCash/addItem
├── bridge/
│   ├── client/          — qb.lua, ox.lua, esx.lua (job do jogador, evento de logout)
│   └── server/          — qb.lua, ox.lua, esx.lua (objeto do jogador, job)
└── fxmanifest.lua
```
