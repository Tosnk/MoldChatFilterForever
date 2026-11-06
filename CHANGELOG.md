# Changelog

## 1.0.1

- Renamed to NoPetrovychChatFilter (saved settings start fresh; slash commands are now `/npcf` and `/nopetrovych`)

## 1.0.0

- Initial release for World of Warcraft: Forever
- Mode 1: hides any chat line containing Cyrillic letters, whole line including the sender (locks mode 2 on)
- Mode 2: hides every line from Cyrillic-named characters, even when written in Latin letters; on its own it leaves Cyrillic text from Latin-named players visible
- Per-source toggles in Escape > Options > AddOns > NoPetrovychChatFilter: General, Trade, LookingForGroup, LocalDefense and other channels filtered by default; Say, Yell, Emote, Party, Raid, Instance, Guild and Whisper untouched by default
- Your own messages are never hidden
- `/npcf` and `/nopetrovych` commands: open options, on/off, status, test, reset
