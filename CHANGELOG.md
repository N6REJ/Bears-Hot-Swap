# Changelog

## Unreleased
- Made `/bhs debug` and the minimap button's right-click open the Debug tab (previously a no-op).
- Corrected README feature/usage docs to match the actual UI.
- Fixed combat handling: gear swaps are now queued while in combat and reliably applied after combat ends (including when combat state is detected via `UnitAffectingCombat`).
- Fixed a Lua syntax error in `swap.lua` (missing `end`) that prevented the file from loading.
- Avoided aura access errors/taint spam: aura reads are now pcall-protected, and form checks are skipped while in combat.

## 1.0.0
- Initial release: auto-swap gear on form/stance changes, configurable triggers, gearset UI, BetterBags categorization.