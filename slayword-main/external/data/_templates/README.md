# External Data Templates

These files are safe reference templates for text/content editing.

Why they live here:

- `external/data/_templates/` is not listed in [`external/mod_info.json`](D:/code/slayword/external/mod_info.json), so the game will not load these files as live content.
- This avoids accidental data pollution while you are drafting text.

How to use them:

1. Copy a template into the real target folder such as `external/data/cards/` or `external/data/keywords/`.
2. Rename the file to match the object you want to patch, for example `card_attack.json`.
3. Change `properties.object_id` to the real object id you want to override.
4. Keep only the fields you actually want to edit, or expand the file after you export the full base data.

Recommended long-term workflow:

1. Install or open the project with Godot 4.
2. Run the project once with the command-line flag `--export-test-data`.
3. The project will call `FileLoader.export_test_data()` and write the current built-in test data into the real `external/data/*` folders.
4. After that, edit those exported json files directly.

Export command after Godot is available:

```powershell
godot4 --path D:\code\slayword -- --export-test-data
```

If your executable name is different, replace `godot4` with your local Godot binary path.

