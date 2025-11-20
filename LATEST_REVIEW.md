# Code Review - PanelKit Integration Follow-up

## Date
2025-11-20

## Changes
- UI modules (`Campaign.ttslua`, `Hunt.ttslua`, `Showdown.ttslua`, `Timeline.ttslua`) refactored to use `PanelKit.Dialog`; Hunt/Showdown swap bespoke scroll lists for `PanelKit.OptionList`.
- New shared UI helpers added in `Ui/PanelKit.ttslua` with accompanying `tests/panelkit_test.lua` (registered in `tests/run.lua`).
- `Global.ttslua` wraps save/init steps in `pcall` with error logging; `PROCESS.md` adds reviewer responsibility to update `LATEST_REVIEW.md`; `updateTTS.sh` disables Lua compression and JSON-encodes the uncompressed bundle.

## Positive Aspects
- Dialog creation and list construction are now centralized, reducing duplicated UI setup and standardizing close behavior.
- PanelKit gains initial unit tests that assert dialog open-state handling for both per-player and global configurations.
- Save/init now fail fast with targeted error logging, improving observability when a subsystem errors during load/save.
- Process doc explicitly calls out that reviewers must update `LATEST_REVIEW.md`, aligning with the repo’s review expectations.

## Issues & Recommendations
- **Medium – Incorrect global Timeline dialog handling** (`Timeline.ttslua:702-724`): The Timeline dialog is configured as global (`perPlayer = false`), but `Timeline.ShowUi/HideUi` still call `dialog:ShowForPlayer/HideForPlayer` and expect a player color. Global dialogs return `"All"`, causing spurious “already looking” errors even when the UI opens/closes. Call `Timeline.ShowUiForAll/HideUiForAll` (or accept `"All"`) to match the dialog contract and avoid false error logs.
- **Low – Missing coverage for module show/hide flows**: `tests/panelkit_test` covers PanelKit internals only. There is no test exercising Timeline/Hunt/Showdown show/hide paths after the dialog swap, so contract drift (as above) isn’t caught. Add a minimal test (or integration check) to assert global Timeline uses `ShowUiForAll/HideUiForAll` and that per-player dialogs return the caller’s color without logging errors.

## Test Results
- Not run (not requested).

## Summary
Refactor consolidates UI dialogs and list building, with initial PanelKit tests and clearer process guidance. The remaining fix is to align Timeline’s show/hide functions with its global dialog; adding a small toggle test would prevent regressions. Once the Timeline hook is corrected, the changes look sound.
