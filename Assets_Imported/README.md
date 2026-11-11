# Assets_Imported

Only the asset files that the game **actually uses** are copied here, organized
by purpose. The raw packs they come from live outside the repository in the
private `assets/` library (see `../../../assets/README.md`).

```
Assets_Imported/
├── clinic/     clinic tilesets, props, dental objects
├── villains/   sugar-creature sprites
├── town/       village exteriors, buildings, vehicles
├── ui/         notebook, HUD, icons, item frames
└── audio/      sound effects and music
```

## Rules

- Copy individual files or the smallest needed folder — never a whole pack.
- Keep the original filenames where practical so the source pack is traceable.
- Do not add files whose license forbids redistribution in a public repo.
- Credit every pack in the in-game credits screen (see the private
  `assets/CREDITS.md`).
- Pixel-art import defaults: filter **Nearest**, mipmaps **off**, compress
  **lossless**. The project already sets nearest filtering globally.
