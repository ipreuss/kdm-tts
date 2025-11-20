# Code Review - PanelKit Dialog Adoption and Safe Init/Save

## Date
2025-11-20

## Changes
- Updated: `Campaign.ttslua`, `Hunt.ttslua`, `Showdown.ttslua`, `Timeline.ttslua` to wrap major UIs in `PanelKit.Dialog`; Hunt/Showdown now use `OptionList` for monster/level selection.
- Added: `Ui/PanelKit.ttslua` plus `tests/panelkit_test.lua`; registered in `tests/run.lua`.
- Updated: `Global.ttslua` to wrap save/init steps in `pcall` logging.
- Updated: `PROCESS.md` with debugging guidance; `updateTTS.sh` switches bundling to use uncompressed `bundle.lua`.

## Positive Aspects
- Dialog creation now centralized via `PanelKit.Dialog`, simplifying close handling and open/close state.
- Shared option list helper reduces duplicated scroll/list code for Hunt/Showdown.
- New PanelKit unit tests cover dialog open-state for per-player vs global mode.
- Save/Init safety wrappers in `Global.ttslua` add resilience and clearer error logs when a subsystem fails.

## Issues & Recommendations
- **Global Timeline dialog misuse (Severity: Medium)** — `Timeline.InitUi` sets the dialog as global (`perPlayer = false`), but `Timeline.ShowUi/HideUi` still call `dialog:ShowForPlayer/HideForPlayer` and expect a player color (Timeline.ttslua:702-724). Global dialogs return `"All"`, so these functions log spurious errors even when the UI opens/closes correctly. Fix by calling `Timeline.ShowUiForAll/HideUiForAll` (or accepting `"All"`) to align with the new dialog contract.
- **Coverage gap for Global UI flows (Severity: Low)** — `tests/panelkit_test` validates PanelKit, but no tests exercise module-level callers (Timeline/Hunt/Showdown) after the dialog swap. A minimal smoke test for `Timeline.ShowUiForAll/HideUiForAll` (global) and per-player flows for Hunt/Showdown would catch contract drift like the issue above.

## Test Results
- Not run (not requested). Note new `tests.panelkit_test` is added to `tests/run.lua`.

## Summary
PanelKit adoption improves reuse and adds baseline tests, and `Global.ttslua` now guards save/init with safer logging. The main fix needed is to align Timeline’s show/hide functions with its global dialog to avoid false error logs and ensure future tests pass; consider adding a small UI toggle test to prevent regressions. Otherwise changes look ready once the Timeline hookup is corrected.
