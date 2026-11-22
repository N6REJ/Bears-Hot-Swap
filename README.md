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

## Usage
- `/bhs` — open the window (Sets / Triggers / Debug tabs).
- `/bhs save <name>` — save current gear as a named set.
- `/bhs <name>` — force equip a saved set.
- `/bhs status` — list saved sets.
- `/bhs trigger list|add <spellId> <setName>|remove <spellId>|set <key> <setName>` — manage triggers.
- `/bhs discover` — auto-detect shapeshift/stance forms.
- `/bhs default <setName>` — set the default set (no form).
- `/bhs debug` — toggle the debug window.

## Compatibility
Built for **WoW:Forever** only (`## Interface: 16001`).

## License
MIT License — see `LICENSE`.