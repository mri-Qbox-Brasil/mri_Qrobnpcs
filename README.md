<div align="center">
  <h1>xt-robnpcs</h1>
  <a href="https://dsc.gg/xtdev"> <img align="center" src="https://user-images.githubusercontent.com/101474430/233859688-2b3b9ecc-41c8-41a6-b2e3-a9f1aad473ee.gif"/></a><br>
</div>

# Features:
- QB / QBX / OX / ESX / ND support via [Renewed-Lib](https://github.com/Renewed-Scripts/Renewed-Lib)
- Rob local NPCs
- Server-authoritative payouts — the server re-checks distance, job, cop count, ped validity, and per-player + per-ped cooldowns before it pays anyone
- Sets a `robbed` statebag on peds once they are robbed / run away / fight back, preventing them from being robbed again
- Required on-duty cop count, or zero — read from Renewed-Lib's `GlobalState.copCount`, so it
  stays in sync with every other Renewed resource instead of being recounted here. Which jobs
  count as police is Renewed's `inventory:police` convar (default: `["police", "sheriff"]`)
- Min / max payouts
- Blacklisted jobs
  - Set jobs can not rob locals
- Random Chances
  - Chance police are called when NPC is robbed
  - Chance ped has NO cash on them when robbed
  - Chance the ped decides to flee or beat your ass before or after robbing them, rather than surrendering
  - If ped fights back, random chance they have a weapon, random weapon is chosen from the config
  - Chance to receive items from peds pocket
- Animations
  - Ped turns to face you, raises their hands, then eases down into a kneel
  - Player does a 'robbing' animation
  - Ped does animation to get up and flee
- Easy configurations
  - Open function for adding money
  - Open function for adding items (use any inventory)
  - Open function for any dispatch

# [Preview](https://www.youtube.com/watch?v=s-Ihw-aHBbo)

# Dependencies:
- [ox_lib](https://github.com/overextended/ox_lib/releases)
- [Renewed-Lib](https://github.com/Renewed-Scripts/Renewed-Lib) — the framework bridge. **This is required.** Without it the resource will not start.
- Supported Interaction Resources:
    - [ox_target](https://github.com/overextended/ox_target/releases) or [qb-target](https://github.com/qbcore-framework/qb-target)
    - [sleepless_interact](https://github.com/Sleepless-Development/sleepless_interact) — set `useSleeplessInteract = true` in `configs/client.lua`

# Layout

| Path | What lives there |
|---|---|
| `configs/shared.lua` | Values both sides read: required cop count, blacklisted jobs |
| `configs/client.lua` | Client settings, ped reaction chances, allowed weapons, and the `dispatch` bridge |
| `configs/server.lua` | Payouts, loot, cooldowns, and the `addCash` / `addItem` / `hasGroup` bridges |
| `client/utils.lua` | Targeting, raycasting, and every ped animation |
| `client/cl_main.lua` | The aim loop and the holdup state machine |
| `server/sv_main.lua` | The payout callback and its validation |

Everything a server owner should need to change is a value or a function in `configs/`. The
`addCash`, `addItem`, `hasGroup`, and `dispatch` functions are the swap points — rewrite them
for your inventory, framework, or dispatch resource and the rest of the code does not care.

# Notes

- **Robbing with a weapon already drawn:** fixed. The aim loop is armed on resource start and
  on player load, not only when `lib.onCache('weapon')` fires, so restarting the resource with
  a gun in hand works.
- The rob raycast now tests world geometry, so you can no longer hold up a ped through a wall.
