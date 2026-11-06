# Quickstart: Cyrillic Chat Filter

## Install for development (one time)

The game loads the checked-in folder directly through a directory junction:

```powershell
New-Item -ItemType Junction -Path "D:\Games\World of Warcraft\_forever_\Interface\AddOns\NoPetrovychChatFilter" -Target "C:\Repos\NoPetrovychChatFilter"
```

Remove with `Remove-Item` on the junction path (the repo folder is untouched).

## Run the tests

```bash
uv run tests/run_tests.py
```

Expected: every case prints `ok`, last line `N passed, 0 failed`, exit code 0.

## Verify in the game (manual checklist, run before tagging a version)

1. Launch WoW: Forever, log in. AddOns list shows **NoPetrovychChatFilter** with no "out of date" tag.
2. `/npcf` opens Options, AddOns, NoPetrovychChatFilter. Checked: Filter enabled, Filter all
   Cyrillic messages, Filter Cyrillic-named players (indented and greyed out while mode 1 is on),
   General, Trade, LookingForGroup, LocalDefense, Other channels. Unchecked: Say, Yell, Emote,
   Party, Raid, Instance / Battleground, Guild / Officer, Whisper.
   Untick "Filter all Cyrillic messages": the names checkbox becomes editable and stays ticked.
   Untick it too, then re-tick mode 1: the names checkbox turns back on and locks.
3. `/npcf test привет` prints `hidden`; `/npcf test hello` prints `shown`; `/npcf test Ärger` prints
   `shown`.
4. Stand in a city. Wait for a Cyrillic line in Trade or General: it never appears. Latin lines
   look unchanged (timestamps, class colours, links intact).
5. Type a Cyrillic word into Trade yourself: your own line is shown.
6. With a friend or second account: Cyrillic in Party is shown; tick **Party** in Options; next
   Cyrillic party line is hidden; untick it again.
7. Untick **Trade**; a Cyrillic Trade line is shown; tick it back.
8. `/npcf status` shows `hidden this session: N` with N > 0.
9. `/reload`; reopen Options: ticks are as left. Log out and in: same.
10. Click **Reset to defaults**: ticks return to step 2 state.
11. BugSack shows no errors from NoPetrovychChatFilter for the session.
