# Tasks: 003 log, names-only and spoiler mode

- [x] T001 `Core/Log.lua`: LogAdd / LogFind / LogClear, 500-entry cap, counter, callbacks
- [x] T002 `Core/Filter.lua`: `ns.Judge` returning hide / spoiler / nil, spoiler link text, arg pass-through
- [x] T003 `Core/Sources.lua`, `Core/Config.lua`: `namesOnly` + `spoiler` defaults, 1.0.x migration, reset
- [x] T004 `UI/Log.lua`: log window, live updates, click-to-read reveal via SetItemRef
- [x] T005 `UI/Options.lua`: counter + Open log row, three peer checkboxes, master switch locks the rest
- [x] T006 `UI/Slash.lua`: `log`, `names`, `spoiler`, status and test verdicts
- [x] T007 Tests: `tests/test_log.lua`, rewritten `tests/test_filter.lua`, `tests/test_sources.lua`
- [x] T008 TOC 1.1.0, CHANGELOG, README, `scripts/install-dev.ps1`
- [ ] T009 In-game check: spoiler line renders, click reveals in place, master switch greys rows live, log window opens from Options
- [x] T010 CurseForge description and summary shortened to one line plus `/npcf`
- [ ] T011 Tag v1.1.0 after approval
