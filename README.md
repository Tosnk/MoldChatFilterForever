# MoldChatFilterForever

A World of Warcraft: **Forever** addon that hides Cyrillic chat where you want it hidden and
nowhere else.

- Two modes, both on by default:
  1. **Filter all Cyrillic messages**: any line containing a Cyrillic letter is dropped **whole**,
     no channel tag, no name, no placeholder. Turning this on also locks mode 2 on.
  2. **Filter Cyrillic-named players**: **every** line from a character whose name is Cyrillic is
     dropped, even if they type in Latin letters. With only this mode on, Cyrillic text from
     Latin-named players stays visible.
- You pick **where** it applies, per chat source, from Escape > Options > AddOns > MoldChatFilterForever.
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

From CurseForge (recommended, auto-updates through the CurseForge app): see the project page
linked in the TOC's `X-Website`. Manual install:

Copy the `MoldChatFilterForever` folder (the one containing `MoldChatFilterForever.toc`) into
`World of Warcraft\_forever_\Interface\AddOns\`.

For development, point a junction at the checked-out folder instead:

```powershell
New-Item -ItemType Junction -Path "D:\Games\World of Warcraft\_forever_\Interface\AddOns\MoldChatFilterForever" -Target "C:\Repos\MoldChatFilterForever"
```

## Slash commands

| Command | Effect |
|---------|--------|
| `/mcff` (also `/mff`, `/moldfilter`) | open the Options page |
| `/mcff on` / `off` / `toggle` | master switch |
| `/mcff status` | settings and how many lines were hidden this session |
| `/mcff test <text>` | would this text be hidden in Trade? |
| `/mcff reset` | restore defaults |

## Releasing

1. Bump `## Version` in `MoldChatFilterForever.toc` and add a matching `## X.Y.Z` section to `CHANGELOG.md`.
2. `powershell scripts/release-check.ps1 -ExpectedVersion X.Y.Z`
3. Commit, tag `vX.Y.Z`, push the tag. GitHub Actions publishes the GitHub release; CurseForge's
   GitHub webhook packages the tag with `.pkgmeta` and uses the CHANGELOG section as the file changelog.

## Development

Spec-driven with [Spec Kit](https://github.com/github/spec-kit): see `specs/001-cyrillic-chat-filter/`
for the spec, plan, contracts, tasks and the in-game verification checklist (`quickstart.md`).

Core logic (detection, routing, settings) has no WoW API dependency and is tested out of game:

```bash
uv run tests/run_tests.py
```

## License

MIT
