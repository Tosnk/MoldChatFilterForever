# Changelog

## 1.1.0

- Options are now three independent switches plus the channel list: **Filter enabled** (locks everything else while off), **Cyrillic names only** (act only on messages from Cyrillic-named characters; Cyrillic text from Latin-named players is left alone) and **Use spoiler instead of hiding**.
- Spoiler mode (new default): a matched line is kept but its text is collapsed behind a "[Petrovych detected, click to read]" link; a click reveals the original text in place. It follows the same channel selection as hiding.
- Filtered-messages log: a "Filtered this session: N" counter with an "Open log" button in the Options page (also `/npcf log`) lists every line hidden or collapsed this session with time, channel and sender. Session only, newest 500 kept.
- `/npcf names` and `/npcf spoiler` toggle the two switches; `/npcf status` and `/npcf test` report "collapsed" as well as "hidden".
- Upgrading from 1.0.x: "mode 2 only" becomes "Cyrillic names only"; spoiler mode is switched on. Untick it to go back to removing lines.

## 1.0.2

- New icon

## 1.0.1

- Renamed to NoPetrovychChatFilter (saved settings start fresh; slash commands are now `/npcf` and `/nopetrovych`)

## 1.0.0

- Initial release for World of Warcraft: Forever
- Mode 1: hides any chat line containing Cyrillic letters, whole line including the sender (locks mode 2 on)
- Mode 2: hides every line from Cyrillic-named characters, even when written in Latin letters; on its own it leaves Cyrillic text from Latin-named players visible
- Per-source toggles in Escape > Options > AddOns > NoPetrovychChatFilter: General, Trade, LookingForGroup, LocalDefense and other channels filtered by default; Say, Yell, Emote, Party, Raid, Instance, Guild and Whisper untouched by default
- Your own messages are never hidden
- `/npcf` and `/nopetrovych` commands: open options, on/off, status, test, reset
