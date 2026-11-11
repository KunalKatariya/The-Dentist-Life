# The Dentist Life — project rules for coding agents

Godot 4.4.1, GDScript. This repository is a personal gift. Do not break the
existing gift scenes.

## Never modify without an explicit task

- `Scenes/Surprise/` — the birthday reveal
- `Scenes/AIChat/` — the tea chat
- `Scenes/Badminton/` — the badminton minigame
- `Scenes/MainMenu/` art (script fixes are allowed when requested)
- Do not reformat or re-save the large scenes `playground.tscn` or
  `Scenes/Badminton/badminton_game.tscn`.

## Rendering

- Keep the 480x270 viewport and pixel-art settings.
- Tiles are 16x16. Player and NPC sprites are 32x32 frames.
- Nearest filtering, no mipmaps, lossless compression.

## Architecture

- `GameState` — flags, quest stages, recovered items, stickers, per-scene
  positions. Persists to `user://save.json`.
- `SceneRouter` — named destinations only (`menu`, `hub`, `clinic`,
  `badminton`, `surprise`, `chat`). Never hard-code scene paths in new code.
- `ActionRouter` — dialog branch actions. Scene-specific actions are emitted
  through `action_requested`; the current scene handles its own.
- `DialogInteraction` / `DialogBranch` — use `required_flag`,
  `forbidden_flag`, `set_flag_on_finish`, `give_item_on_finish`,
  `action_on_finish` instead of adding one-off scripts.
- New content lives in new files. Keep edits to existing scripts small.

## Gameplay rules

- No combat, no player death, no lost progress.
- Every challenge is retryable and offers "skip after 3 tries".
- Teach before testing: the first instance of a challenge is easy.
- The player can only walk, idle and interact. Express actions through UI
  overlays, sparkles, popups and sound.

## Assets

- Raw asset packs live outside the repo in `../assets/`.
- Only files the game uses are copied to `Assets_Imported/`.
- Respect licenses; add credit lines to the in-game credits.

## Definition of done for every change

1. Run the project headlessly and read the console.
2. Regression-check: menu, hub dialog routes, badminton, surprise, AI chat,
   clinic exit, day/night cycle.
3. Commit with a small, focused message.
