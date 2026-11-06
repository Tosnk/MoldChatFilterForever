# Tasks: 003 log, names-only and spoiler mode

- [x] T001 `Core/Log.lua`: LogAdd / LogFind / LogClear, 500-entry cap, counter, callbacks
- [x] T002 `Core/Filter.lua`: `ns.Judge` returning hide / spoiler / nil, spoiler link text, arg pass-through
- [x] T003 `Core/Sources.lua`, `Core/Config.lua`: `namesOnly` + `spoiler` defaults, 1.0.x migration, reset
- [x] T004 `UI/Log.lua`: log window, live updates, click-to-read reveal via SetItemRef
- [x] T005 `UI/Options.lua`: counter + Open log row, three peer checkboxes, master switch locks the rest
- [x] T006 `UI/Slash.lua`: `log`, `names`, `spoiler`, status and test verdicts
- [x] T007 Tests: `tests/test_log.lua`, rewritten `tests/test_filter.lua`, `tests/test_sources.lua`
- [x] T008 TOC 1.1.0, CHANGELOG, README, `scripts/install-dev.ps1`
- [x] T009 In-game check (user, 2026-11-06): spoiler renders, click reveals in place in the default chat (1.1.2) and in EllesmereUIChat (1.1.3), log opens from Options
- [x] T010 CurseForge description and summary shortened to one line plus `/npcf`
- [x] T011 Tagged v1.1.0, v1.1.1 (EllesmereUI reveal), v1.1.2 (buffer rewrite); 1.1.0 and older archived on CurseForge, 1.1.1 demoted to Alpha
