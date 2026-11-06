<!--
Sync Impact Report
- Version change: 1.0.0 → 1.0.1 (PATCH: Development Workflow wording after the repository-root layout)
- Modified principles: none
- Added sections: Core Principles (I–VI), Technical Constraints, Development Workflow, Governance
- Removed sections: none
- Templates: plan-template.md / spec-template.md / tasks-template.md read this file at runtime; no edits needed
- Follow-up TODOs: none
-->

# MoldChatFilterForever Constitution

## Core Principles

### I. WoW: Forever Only
The addon targets World of Warcraft: Forever exclusively. The TOC declares only the Forever
interface version. No compatibility shims for Retail, Classic Era or other flavors are added, and
no API path is kept "just in case" another client needs it.
Rationale: one client keeps the code small, testable and free of version branches.

### II. Zero Dependencies
The addon ships as a single folder of plain Lua and the client's own FrameXML/Settings APIs.
No embedded or external libraries (Ace3, LibStub, etc.) and no optional-dependency hooks.
Rationale: nothing to update when libraries break, and nothing to trust besides the addon itself.

### III. Private Chat Is Untouchable By Default (NON-NEGOTIABLE)
Filtering is opt-in per chat source. Party, raid, instance/battleground, guild, officer, whisper,
say, yell and emote sources ship DISABLED. Only public numbered channels (General, Trade,
LookingForGroup, LocalDefense and custom/world channels) ship enabled. The player's own messages
are never hidden. A release that changes a default toward more filtering is a MAJOR version.
Rationale: the author reads and writes Cyrillic with friends; losing a party message is worse than
seeing one unwanted Trade line.

### IV. Whole-Message Removal
A filtered message is dropped before it reaches any chat frame: no sender line, no channel tag,
no placeholder text, no sound. The addon never edits message text, never replaces it with "***",
and never hides only part of a line.
Rationale: the user asked for the message and the nickname to disappear together.

### V. Settings Live In The Options UI
Every setting is reachable from the game's Options → AddOns panel with plain checkboxes and
short labels. Slash commands mirror the panel but never offer a setting the panel lacks.
Settings persist per account via SavedVariables and survive `/reload` and relog.
Rationale: the user asked for settings that are simple and not chat-only.

### VI. Testable Core, Verified UI
Detection and routing logic (is this text Cyrillic? which source is this event?) lives in files
free of WoW API calls and is covered by an out-of-game test harness that runs on every change.
UI and chat-hook behaviour is verified in the Forever client against the feature's quickstart
checklist before a version is tagged.
Rationale: the game cannot be unit-tested, so everything that can be isolated from it must be.

## Technical Constraints

- Language: Lua 5.1 as embedded in the WoW client; no `goto`, no integer division, no `utf8` lib.
- Cyrillic detection operates on UTF-8 bytes (lead bytes 0xD0–0xD4), never on code points.
- Chat interception uses `ChatFrame_AddMessageEventFilter` only; no hooking of `AddMessage`.
- Realm-qualified sender names (`Name-Realm`) are judged on the character name part only.
- The addon folder name, TOC name and SavedVariables name are all `MoldChatFilterForever`.

## Development Workflow

- Spec-driven: every feature goes constitution → spec → plan → tasks → implement, using the
  Spec Kit artifacts under `specs/`.
- Tests for `Core/` logic run via `uv run tests/run_tests.py` and MUST pass before commit.
- The addon lives at the repository root (TOC beside `Core/` and `UI/`), the layout the CurseForge
  GitHub packager expects; it is installed into the Forever client via a directory junction from
  `AddOns\MoldChatFilterForever` to the repository root so checked-in and installed code are the
  same files. Tooling folders (`specs/`, `tests/`, `.specify/`) are ignored by the game and by `.pkgmeta`.
- Commits are small and reference the task id (`T0xx`) they complete.

## Governance

This constitution supersedes any other practice note in the repository. Amendments are made by
editing this file with a bumped version and an updated Sync Impact Report. Versioning follows
semantic rules: MAJOR for principle removal/redefinition (including any default that filters more),
MINOR for new principles or materially expanded guidance, PATCH for wording. Every plan's
Constitution Check must cite the principle it is evaluating and justify any deviation in the
plan's Complexity Tracking table.

**Version**: 1.0.1 | **Ratified**: 2026-11-06 | **Last Amended**: 2026-11-06
