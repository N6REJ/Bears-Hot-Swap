# Bears Hot Swap

[![WoW Version](https://img.shields.io/badge/WoW-Forever-darkgreen)](https://worldofwarcraft.blizzard.com/) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![GitHub](https://img.shields.io/badge/GitHub-Source-blue?logo=github)](https://github.com/N6REJ/Bears-Hot-Swap)

Automatically swaps a saved equipment set when you shift in or out of a tracked form or aura (e.g. Bear Form). Built for **WoW:Forever** (interface 16001).

## Features
- Auto-detects form/aura changes via `UNIT_AURA` and swaps gear after a short delay.
- Configurable triggers (aura → set) with a movable UI.
- Auto-discovers shapeshift/stance forms on login.
- Creates Blizzard Equipment Manager sets for BetterBags categorization (`Gear: <name>`).
- Shows which saved set is currently worn; debug tab with diagnostics and logs.
- Movable minimap button (top-right by default).

## Installation
1. Copy the `Bears-Hot-Swap` folder into your `Interface/AddOns` directory.
2. Enable the addon in-game.

## How to use (UI does everything)
1. Put on the gear you want for a situation (for example, your normal/caster gear).
2. Open the window with `/bhs` (or the minimap button).
3. On the **Sets** tab, type a name (e.g. `normal`) and click **Save**. The addon saves what you are wearing now. Repeat for each form/gear set (e.g. `bear`).
4. On the **Triggers** tab, add a trigger for each form/aura: enter the spell ID or aura name, pick the set it should equip, and click **Add**. Or click **Discover** to auto-detect your shapeshift/stance forms and create triggers for them.
5. Use the **Cycle** button (or `/bhs default <name>`) to set the default set worn when no tracked form/aura is active.
6. Done — when you shift forms, Bears Hot Swap equips the matching set automatically after a short delay. Use **Equip** on a set row (or `/bhs <name>`) to force-equip manually.

> **BetterBags:** each saved set is also stored as a Blizzard Equipment Manager set named `Gear: <name>`, so BetterBags (and similar addons) categorize those items automatically.

## Commands (optional shortcuts)
- `/bhs` — open the window.
- `/bhs save <name>` / `/bhs <name>` — save or force-equip a set.
- `/bhs status` — list saved sets.
- `/bhs trigger list|add <spellId> <setName>|remove <spellId>|set <key> <setName>` — manage triggers.
- `/bhs discover` — auto-detect shapeshift/stance forms.
- `/bhs default <setName>` — set the default set (no form).
- `/bhs debug` — open the debug tab.

## Compatibility
Built for **WoW:Forever** only (`## Interface: 16001`).

## License
MIT License — see `LICENSE`.