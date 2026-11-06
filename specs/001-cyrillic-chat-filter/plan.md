# Implementation Plan: Cyrillic Chat Filter

**Branch**: `001-cyrillic-chat-filter` | **Date**: 2026-11-06 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-cyrillic-chat-filter/spec.md`

## Summary

Hide every chat line whose text, or whose sender's character name, contains Cyrillic letters,
but only for chat sources the player has ticked (public channels by default, never party/raid/
whisper/guild unless asked). Implemented as a single-folder WoW: Forever addon that registers
`ChatFrame_AddMessageEventFilter` callbacks (whole-line drop), detects Cyrillic by UTF-8 lead
bytes, stores settings in one account-wide SavedVariables table, and exposes them through the
client's Settings API panel plus `/npcf` slash commands. Pure logic (detection, event-to-source
routing, defaults) lives in `Core/` without WoW API calls and is exercised by a Python+lupa test
harness run with `uv`.

## Technical Context

**Language/Version**: Lua 5.1 (WoW client embedded Lua); Python 3.12 + `lupa` only for the
out-of-game test harness

**Primary Dependencies**: None at runtime (FrameXML `ChatFrame_AddMessageEventFilter`, Blizzard
`Settings` API). Dev-only: `uv`, `lupa`

**Storage**: SavedVariables table `NoPetrovychChatFilterDB` (account-wide, written by the client on
logout/reload)

**Testing**: `uv run tests/run_tests.py` executes `tests/*.lua` against `Core/*.lua` in a lupa
Lua runtime with a stub addon namespace; UI verified in-client via quickstart checklist

**Target Platform**: World of Warcraft: Forever, Interface 16001, Windows client at
`D:\Games\World of Warcraft\_forever_`

**Project Type**: Game addon (single folder, loaded from TOC)

**Performance Goals**: Filter callback must do one `string.find` per message in the common case;
no table allocation per message; no measurable frame-time impact in busy Trade chat
(hundreds of messages per minute)

**Constraints**: No libraries; no `AddMessage` hooking; no `utf8` library; settings panel must be
plain checkboxes; defaults must never filter group/private chat (constitution III)

**Scale/Scope**: ~6 Lua files, ~400 lines; 13 chat sources; 1 settings page; 2 slash aliases

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. WoW: Forever Only | TOC declares `## Interface: 16001` only; Settings API confirmed on this client (ForeverVO, UALLF use `Settings.RegisterAddOnSetting` with the 7-arg signature) | PASS |
| II. Zero Dependencies | No `## Dependencies`, no `Libs/`, no LibStub; test harness is dev-only and outside the addon folder | PASS |
| III. Private Chat Untouchable | Defaults table in `Core/Sources.lua`: only general/trade/lfg/localdefense/other = true; own-message guard in `Core/Filter.lua` | PASS |
| IV. Whole-Message Removal | Filter returns `true` to drop the line; never returns modified text | PASS |
| V. Settings In Options UI | `UI/Options.lua` registers a vertical-layout AddOns category with one checkbox per setting + reset button; slash commands only mirror | PASS |
| VI. Testable Core | `Core/Detect.lua` and `Core/Sources.lua` contain no WoW API calls; `tests/` covers them; quickstart lists in-game checks | PASS |

Post-design re-check (after Phase 1): no deviations introduced. Complexity Tracking left empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-cyrillic-chat-filter/
├── plan.md              # This file
├── research.md          # Phase 0: API choices and detection approach
├── data-model.md        # Phase 1: settings schema, source registry, counter
├── quickstart.md        # Phase 1: install, run tests, in-game verification
├── contracts/
│   ├── chat-sources.md  # event → source mapping contract
│   └── slash-commands.md
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
NoPetrovychChatFilter/                 # the addon folder (junction target in the game's AddOns/)
├── NoPetrovychChatFilter.toc
├── Core/
│   ├── Detect.lua                # IsCyrillic(text), NameIsCyrillic(sender) — pure
│   ├── Sources.lua               # source registry, defaults, EventToSource() — pure
│   ├── Config.lua                # SavedVariables init/migration/reset
│   └── Filter.lua                # ChatFrame_AddMessageEventFilter wiring, own-message guard, counter
└── UI/
    ├── Options.lua               # Settings API panel
    └── Slash.lua                 # /npcf, /nopetrovych

tests/
├── run_tests.py                  # uv script (PEP 723 deps: lupa); loads Core/*.lua with stub namespace
├── test_detect.lua
└── test_sources.lua

.github/workflows/tests.yml       # runs the harness on push/PR
README.md
LICENSE                           # MIT
.gitignore
```

**Structure Decision**: Single addon folder named exactly `NoPetrovychChatFilter` at repo root so a
directory junction from `_forever_\Interface\AddOns\NoPetrovychChatFilter` points straight at the
checked-in code (constitution: Development Workflow). Tests and CI live beside it, outside the
folder the game loads.

## Complexity Tracking

No constitution violations; table intentionally empty.
