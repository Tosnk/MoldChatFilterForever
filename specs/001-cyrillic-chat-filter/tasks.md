# Tasks: Cyrillic Chat Filter

**Input**: Design documents from `/specs/001-cyrillic-chat-filter/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/chat-sources.md,
contracts/slash-commands.md, quickstart.md

**Tests**: Required by constitution VI for `Core/` logic (Detect, Sources). UI is verified by the
quickstart checklist in-game.

**Organization**: Tasks grouped by user story so each can be implemented and verified on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1..US4)

## Path Conventions

Addon code in the repository root (folder the game loads); tests in `tests/`; CI in `.github/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Repository and addon skeleton

- [x] T001 Create `NoPetrovychChatFilter.toc` with `## Interface: 16001`, title, notes, author, version 1.0.0, `## SavedVariables: NoPetrovychChatFilterDB`, and the load order Core/Detect.lua, Core/Sources.lua, Core/Config.lua, Core/Filter.lua, UI/Options.lua, UI/Slash.lua
- [x] T002 [P] Create `.gitignore` (Python caches, `.specify/feature.json` stays tracked, editor files) and `LICENSE` (MIT, 2026)
- [x] T003 [P] Create `tests/run_tests.py` uv script (PEP 723 `dependencies = ["lupa"]`) that builds a Lua runtime, loads `Core/Detect.lua` and `Core/Sources.lua` with `("NoPetrovychChatFilter", ns)` varargs, runs every `tests/test_*.lua`, prints per-case results and exits non-zero on failure
- [x] T004 [P] Create `.github/workflows/tests.yml` running `uv run tests/run_tests.py` on push and pull_request (ubuntu, astral-sh/setup-uv)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Pure logic and persistence every story depends on

- [x] T005 [P] Write failing tests in `tests/test_detect.lua`: Cyrillic detected (Russian, Ukrainian і/ї/є/ґ, Serbian ђ, Supplement U+0500), not detected (ASCII, accented Latin, Greek, CJK, emoji, Armenian U+0530, empty, nil); `NameIsCyrillic` on `Имя-Realm` true, `Name-Реалм` true only via name part rule (false), `Name` false
- [x] T006 [P] Write failing tests in `tests/test_sources.lua`: `EventToSource` for every event in contracts/chat-sources.md; `CHAT_MSG_CHANNEL` with zoneChannelID 1/2/22/26 → general/trade/localdefense/lfg; 0 with base name "Trade" → trade; 0 with "World" → other; 23 → other; unknown event → nil; `DEFAULTS` match data-model.md (public ON, rest OFF); `SOURCES` order matches contract
- [x] T007 Implement `Core/Detect.lua`: `ns.IsCyrillic`, `ns.NameIsCyrillic` per contract (byte patterns, no globals but `string`); tests from T005 pass
- [x] T008 Implement `Core/Sources.lua`: ordered `ns.SOURCES` registry (key, label, tooltip, default, events), `ns.DEFAULTS`, `ns.EventToSource(event, zoneChannelID, channelBaseName)`; tests from T006 pass
- [x] T009 Implement `Core/Config.lua`: on `ADDON_LOADED` for this addon create/merge `NoPetrovychChatFilterDB` from `ns.DEFAULTS` (version 1), expose `ns.db`, `ns.ResetDefaults()`, and `ns.RunWhenLoaded(fn)` hooks so later files can register after the DB exists
- [x] T010 Run `uv run tests/run_tests.py`; all green before any story work

**Checkpoint**: Detection and routing proven; settings table exists on load

---

## Phase 3: User Story 1 - Public channels free of Cyrillic messages (Priority: P1) 🎯 MVP

**Goal**: Cyrillic lines in ticked sources vanish entirely; own lines and Latin lines untouched

**Independent Test**: quickstart steps 1, 3 (`/npcf test` arrives in US4; use a Cyrillic Trade line), 4, 5

- [x] T011 [US1] Implement `Core/Filter.lua`: `ns.hiddenCount`, `ns.ShouldHide(event, text, sender, guid, zoneChannelID, channelBaseName)` following the decision order in contracts/chat-sources.md (master switch, own-message guard via `UnitGUID("player")` with name fallback, source lookup, text check); name check left as a call to `ns.NameIsCyrillic` guarded by `db.blockNames`
- [x] T012 [US1] In `Core/Filter.lua` register one callback with `ChatFrame_AddMessageEventFilter` for every event listed in `ns.SOURCES[*].events` plus `CHAT_MSG_CHANNEL`; callback maps filter args (text=arg1, sender=arg2, zoneChannelID=arg7, channelBaseName=arg9, guid=arg12) to `ns.ShouldHide`, increments the counter, returns `true` to drop
- [ ] T013 [US1] Install junction `AddOns\NoPetrovychChatFilter` → repo folder (quickstart); launch Forever, confirm addon loads with no error and a Cyrillic Trade line is hidden while Latin lines and own lines show

**Checkpoint**: MVP filtering works with hard-coded defaults

---

## Phase 4: User Story 2 - Ignore everything from Cyrillic-named characters (Priority: P2)

**Goal**: With `blockNames` on, any line from a Cyrillic-named sender in a ticked source is hidden

**Independent Test**: `ShouldHide("CHAT_MSG_CHANNEL", "LFM SM", "Иван-Realm", nil, 26, "LookingForGroup")` → true with blockNames, false without; in-game with a Cyrillic-named character posting Latin text in LFG

- [x] T014 [P] [US2] Add tests to `tests/test_sources.lua` (or new `tests/test_filter_logic.lua` if `ShouldHide` is made loadable with stubbed `UnitGUID`/`UnitName`): Latin text from Cyrillic name in enabled source → hidden; same in disabled source (party) → shown; `blockNames=false` → shown; own GUID → shown even with Cyrillic text
- [x] T015 [US2] Ensure `Core/Filter.lua` consults `db.blockNames` before `ns.NameIsCyrillic(sender)` and that the own-message guard runs first; make `Core/Filter.lua` loadable in the harness by reading `UnitGUID`/`UnitName`/`ChatFrame_AddMessageEventFilter` through `_G` lookups at call time (tests stub them)

**Checkpoint**: Name-based blocking verified by tests and in-game

---

## Phase 5: User Story 3 - Choose where filtering applies, from the Options UI (Priority: P3)

**Goal**: Settings panel under Options, AddOns with master, names, 13 source checkboxes, status
line, reset button; persisted; immediate effect

**Independent Test**: quickstart steps 2, 6, 7, 9, 10

- [x] T016 [US3] Implement `UI/Options.lua`: `Settings.RegisterVerticalLayoutCategory("NoPetrovychChatFilter")`; section header "Filter"; checkboxes bound with `Settings.RegisterAddOnSetting(category, "NPCF_enabled", "enabled", ns.db, Settings.VarType.Boolean, "Filter enabled", true)` and likewise `blockNames`; section header "Where to filter"; one checkbox per `ns.SOURCES` entry bound to `ns.db.sources` with label/tooltip from the registry; section header "Maintenance" with `CreateSettingsButtonInitializer("Reset to defaults", "Reset", ...)` that calls `ns.ResetDefaults()` and refreshes bound settings via `setting:SetValue(default)` for every registered setting; `Settings.RegisterAddOnCategory(category)`; `ns.OpenOptions()` calling `Settings.OpenToCategory(category:GetID())`
- [x] T017 [US3] Add a session status line to the panel: a `CreateSettingsListSectionHeaderInitializer` whose text is refreshed on show (`OnShow`/initializer `GetExtent`) to read `Hidden this session: N` from `ns.hiddenCount` (if dynamic header text proves unreliable on this client, fall back to a disabled checkbox-free text initializer and document in research.md)
- [ ] T018 [US3] Run `Config.lua` registration through `ns.RunWhenLoaded` so Options registers only after `ns.db` exists; verify in-game: defaults as spec, toggle Trade off/on affects next line, `/reload` keeps state, reset restores defaults

**Checkpoint**: All settings reachable from UI; constitution V satisfied

---

## Phase 6: User Story 4 - Quick status and test from chat (Priority: P4)

**Goal**: `/npcf` and `/nopetrovych` per contracts/slash-commands.md

**Independent Test**: quickstart steps 3 and 8

- [x] T019 [US4] Implement `UI/Slash.lua`: register `SLASH_NOPETROVYCHCHATFILTER1/2`; dispatch `on|off|toggle|status|test|reset|<none>`; `status` lists enabled sources by label in registry order; `test` evaluates `ns.ShouldHide("CHAT_MSG_CHANNEL", text, "Stranger", nil, 2, "Trade")`; `<none>` calls `ns.OpenOptions()`; output prefixed `|cff33ff99NoPetrovychChatFilter|r:`
- [ ] T020 [US4] In-game check: `/npcf test привет` hidden, `/npcf test hello` shown, `/npcf status` counts, `/npcf off` reflected in panel

---

## Phase 7: Polish & Cross-Cutting Concerns

- [x] T021 [P] Write `README.md`: what it does, defaults table, install (CurseForge-style manual copy and the dev junction), slash commands, how to run tests, Forever-only note
- [x] T022 [P] Add `## X-Website`, `## X-License: MIT`, `## IconTexture` (optional) and `## Category: Chat` lines to the TOC
- [ ] T023 Run full quickstart checklist in-game with BugSack; record outcome in `specs/001-cyrillic-chat-filter/quickstart.md` footer with date
- [ ] T024 Update `research.md` with any API deviation found in-game (e.g. header text refresh); bump nothing unless contract changed
- [x] T025 Create GitHub repository `NoPetrovychChatFilter`, push `main` and `001-cyrillic-chat-filter`, open PR

---

## Dependencies & Execution Order

- Phase 1 → Phase 2 → (Phase 3 → Phase 4) and Phase 5 and Phase 6 → Phase 7
- US1 (Filter.lua) is required by US2 (adds name branch) and US4 (`test`, `status` read it).
- US3 (Options) depends only on Phase 2 (`ns.db`, `ns.SOURCES`) and can proceed in parallel with US1.
- Within Phase 2: T005/T006 (tests) before T007/T008 (implementation); T009 independent of both.

## Parallel Example: Phase 2

```text
Task: "Write failing tests in tests/test_detect.lua"       (T005)
Task: "Write failing tests in tests/test_sources.lua"      (T006)
Task: "Implement Core/Config.lua"                          (T009)
```

## Implementation Strategy

1. Setup + Foundational, tests green (T001–T010).
2. US1 → install junction → see Trade filtered in-game (MVP).
3. US2 (name blocking) and US3 (Options) next; US4 last.
4. Polish, full quickstart pass, push and PR.

## Notes

- Keep every `Core/*.lua` free of direct WoW globals at file scope so the harness can load them.
- Commit after each phase with the task ids in the message.
