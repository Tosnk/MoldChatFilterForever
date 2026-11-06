# Research: Cyrillic Chat Filter

**Date**: 2026-11-06 | **Plan**: [plan.md](plan.md)

All Technical Context items were resolvable from the client installed at
`D:\Games\World of Warcraft\_forever_` and from well-known FrameXML behaviour. No NEEDS
CLARIFICATION remained.

## R1. How to drop a whole chat line

**Decision**: Register one callback per chat event with `ChatFrame_AddMessageEventFilter(event, fn)`.
Returning `true` from the callback suppresses the line in every chat frame that would display it,
including the channel tag, sender link and timestamp (the frame never calls `AddMessage`).

**Rationale**: It is the documented, addon-cooperative mechanism; many chat addons chain on it.
It satisfies constitution IV (nothing is drawn) with no frame hooking.

**Alternatives considered**:
- Hooking `ChatFrame:AddMessage` on every frame: brittle, conflicts with chat addons that also
  hook it, and the sender prefix is already formatted so parsing is needed. Rejected.
- `C_ChatInfo` / ignore list: would mute players permanently and globally, not per channel. Rejected.

## R2. Settings panel API available on WoW: Forever

**Decision**: Use the modern `Settings` API: `Settings.RegisterVerticalLayoutCategory(name)`,
`Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, VarType, label,
default)` (7-argument form), `Settings.CreateCheckbox(category, setting, tooltip)`,
`CreateSettingsListSectionHeaderInitializer(text)`, `CreateSettingsButtonInitializer(...)`,
`Settings.RegisterAddOnCategory(category)`, `Settings.OpenToCategory(category:GetID())`.

**Rationale**: Two addons already installed in the user's Forever client (ForeverVO
`Core/Settings.lua`, UALLF `Settings.lua`) use exactly these calls with the 7-argument
`RegisterAddOnSetting`, which proves they exist on Interface 16001. Per-source checkboxes bind
directly to the `sources` sub-table via `variableTbl`, so no proxy glue is needed.

**Alternatives considered**:
- Legacy `InterfaceOptions_AddCategory` with a hand-built frame: more code, deprecated on the
  modern engine, and constitution I forbids keeping both paths. Rejected.
- A floating custom frame opened by slash command: not in the Options UI; violates constitution V.
  Rejected.

## R3. Detecting Cyrillic without a `utf8` library

**Decision**: Byte-pattern match on the UTF-8 encoding. Cyrillic U+0400–U+04FF encodes as
`0xD0..0xD3` followed by `0x80..0xBF`; Cyrillic Supplement U+0500–U+052F encodes as `0xD4`
followed by `0x80..0xAF`. Lua pattern: `"[\208-\211][\128-\191]"` or `"\212[\128-\175]"`.
Two `string.find` calls at most per message, zero allocations.

**Rationale**: WoW's Lua has no `utf8` library and strings are raw UTF-8 bytes. The ranges are
exact: `0xD4 0xB0` and up is Armenian and is excluded. Accented Latin (`0xC3 ..`), Greek
(`0xCE/0xCF ..`), CJK (3-byte `0xE..`) and emoji (4-byte `0xF0 ..`) cannot match.

**Not covered (documented)**: Cyrillic Extended-A/B/C blocks (U+2DE0, U+A640, U+1C80) are
historical/phonetic letters that do not occur in chat; ignoring them keeps the pattern to two
ranges.

**Alternatives considered**:
- Counting Cyrillic vs Latin letters and hiding only "mostly Cyrillic" lines: the user asked for
  any Cyrillic to be hidden in public channels; a single-letter false positive is acceptable there.
  Rejected for v1, can be added as a setting later without changing the contract.

## R4. Mapping chat events to user-facing sources

**Decision**: A static registry in `Core/Sources.lua` (see `contracts/chat-sources.md`). For
`CHAT_MSG_CHANNEL`, the source is chosen from the event's `zoneChannelID` argument
(1 General, 2 Trade, 22 LocalDefense, 26 LookingForGroup); any other id (0 for custom channels
such as "World", 23 WorldDefense, future Blizzard channels) maps to **Other channels**. As a
fallback when `zoneChannelID` is 0 but `channelBaseName` equals an English base name, that name is
used.

**Rationale**: `zoneChannelID` is locale-independent and stable across Classic-based clients;
`channelBaseName` is localized, so it is only a fallback.

**Alternatives considered**:
- Matching on the display name "2. Trade": localized and user-renamable. Rejected.
- Using `channelIndex` (the number before the dot): the player can reorder channels. Rejected.

## R5. Never hiding the player's own lines

**Decision**: In the filter callback compare the 12th event argument (`guid`) with
`UnitGUID("player")`; if `guid` is nil, compare the sender's name (before any `-Realm`) with
`UnitName("player")`. A match short-circuits to "show".

**Rationale**: A Ukrainian player typing Cyrillic in Trade must still see their own line
(spec US1 scenario 3). GUID is exact; the name fallback covers events that omit it.

## R6. Out-of-game test harness

**Decision**: `tests/run_tests.py` is a `uv` script with inline metadata (`dependencies = ["lupa"]`).
It creates a Lua runtime (LuaJIT 2.1 when the wheel provides it, else Lua 5.4 with 5.1-compatible
test code), loads each `MoldFilterForver/Core/Detect.lua` and `Core/Sources.lua` by compiling the
file and calling it with `("MoldFilterForver", ns)` so the files' `local ADDON, ns = ...` line
works, then runs `tests/test_*.lua`, which register cases into a table the harness iterates.

**Rationale**: Constitution VI requires pure logic to be tested outside the game; no Lua
interpreter is installed on the dev machine but `uv` is, and `lupa` ships wheels for Windows.

**Alternatives considered**:
- Installing a system Lua via winget: extra machine setup for every contributor. Rejected.
- WoWUnit-style in-game tests: cannot run in CI. Rejected.
