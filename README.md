# NoPetrovychChatFilter

A World of Warcraft: **Forever** addon that keeps Cyrillic chat out of your way. `/npcf` opens the settings.

## What it does

Three switches plus a channel list, in Escape > Options > AddOns > NoPetrovychChatFilter:

- **Filter enabled**: the master switch. While off, nothing happens and the other options are locked.
- **Cyrillic names only**: act only on messages from characters whose name is Cyrillic, whatever
  script they type in. Off (default): any message containing Cyrillic letters is matched too, and
  so is everything from Cyrillic-named characters.
- **Use spoiler instead of hiding** (default on): a matched line is kept, but its text is collapsed
  behind a `[Petrovych detected, click to read]` link; one click reveals the original text in place.
  Off: the line is removed whole, no channel tag, no name, no placeholder.
- **Where**: the chat sources the filter applies to, for both spoiler and hiding.
- **Log**: the Options page shows how many lines were filtered this session and an "Open log" button
  that lists them all (time, channel, sender, text). Session only; the newest 500 are kept.
- Your own messages are never touched, so you can still write Cyrillic yourself.
- No libraries, no dependencies, one folder.

## Default channels

| Source | Filtered by default |
|--------|---------------------|
| General, Trade, LookingForGroup, LocalDefense, Other channels (World, custom) | **yes** |
| Say, Yell, Emote, Party, Raid, Instance / Battleground, Guild / Officer, Whisper | no |

Battle.net whispers, system messages, NPC speech, loot and combat text are never touched.
Chat bubbles above heads are drawn by the client and are not affected.

## Install

From CurseForge (recommended, auto-updates through the CurseForge app): see the project page
linked in the TOC's `X-Website`. Manual install:

Copy the `NoPetrovychChatFilter` folder (the one containing `NoPetrovychChatFilter.toc`) into
`World of Warcraft\_forever_\Interface\AddOns\`.

For development, copy the checked-out files over the installed folder and `/reload`:

```powershell
powershell scripts/install-dev.ps1
```

## Slash commands

| Command | Effect |
|---------|--------|
| `/npcf` (also `/nopetrovych`) | open the Options page |
| `/npcf log` | open or close the filtered-messages log |
| `/npcf on` / `off` / `toggle` | master switch |
| `/npcf names` | toggle "Cyrillic names only" |
| `/npcf spoiler` | toggle "Use spoiler instead of hiding" |
| `/npcf status` | settings and how many lines were filtered this session |
| `/npcf test <text>` | would this text be hidden, collapsed or shown in Trade? |
| `/npcf reset` | restore defaults |

## Releasing

1. Bump `## Version` in `NoPetrovychChatFilter.toc` and add a matching `## X.Y.Z` section to `CHANGELOG.md`.
2. `powershell scripts/release-check.ps1 -ExpectedVersion X.Y.Z`
3. Commit, tag `vX.Y.Z`, push the tag. GitHub Actions publishes the GitHub release; CurseForge's
   GitHub webhook packages the tag with `.pkgmeta` and uses the CHANGELOG section as the file changelog.

## Development

Spec-driven with [Spec Kit](https://github.com/github/spec-kit): see `specs/` for each feature's spec,
plan, contracts and tasks (`001` the filter, `002` the CurseForge release, `003` the log and spoiler mode).

Core logic (detection, routing, settings, log) has no WoW API dependency and is tested out of game:

```bash
uv run tests/run_tests.py
```

## License

MIT
