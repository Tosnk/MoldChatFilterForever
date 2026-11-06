# MoldFilterForver

A World of Warcraft: **Forever** addon that hides Cyrillic chat where you want it hidden and
nowhere else.

- A message containing any Cyrillic letter is dropped **whole**: no channel tag, no name, no
  placeholder.
- Optionally, **every** message from a character whose name is Cyrillic is dropped too, even if
  that message is in Latin letters.
- You pick **where** it applies, per chat source, from Escape > Options > AddOns > MoldFilterForver.
- Your own messages are never hidden, so you can still write Cyrillic yourself.
- No libraries, no dependencies, one folder.

## Defaults

| Source | Filtered by default |
|--------|---------------------|
| General, Trade, LookingForGroup, LocalDefense, Other channels (World, custom) | **yes** |
| Say, Yell, Emote, Party, Raid, Instance / Battleground, Guild / Officer, Whisper | no |

Battle.net whispers, system messages, NPC speech, loot and combat text are never touched.
Chat bubbles above heads are drawn by the client and are not affected.

## Install

Copy the `MoldFilterForver` folder (the one containing `MoldFilterForver.toc`) into
`World of Warcraft\_forever_\Interface\AddOns\`.

For development, point a junction at the checked-out folder instead:

```powershell
New-Item -ItemType Junction -Path "D:\Games\World of Warcraft\_forever_\Interface\AddOns\MoldFilterForver" -Target "C:\Repos\MoldFilterForver\MoldFilterForver"
```

## Slash commands

| Command | Effect |
|---------|--------|
| `/mff` or `/moldfilter` | open the Options page |
| `/mff on` / `off` / `toggle` | master switch |
| `/mff status` | settings and how many lines were hidden this session |
| `/mff test <text>` | would this text be hidden in Trade? |
| `/mff reset` | restore defaults |

## Development

Spec-driven with [Spec Kit](https://github.com/github/spec-kit): see `specs/001-cyrillic-chat-filter/`
for the spec, plan, contracts, tasks and the in-game verification checklist (`quickstart.md`).

Core logic (detection, routing, settings) has no WoW API dependency and is tested out of game:

```bash
uv run tests/run_tests.py
```

## License

MIT
