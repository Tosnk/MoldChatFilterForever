# Data Model: Cyrillic Chat Filter

**Date**: 2026-11-06 | **Plan**: [plan.md](plan.md)

## Settings (`MoldChatFilterForeverDB`, SavedVariables, account-wide)

```lua
MoldChatFilterForeverDB = {
    version    = 1,        -- schema version for future migrations
    enabled    = true,     -- master switch (FR-006)
    blockNames = true,     -- hide everything from Cyrillic-named senders (FR-003)
    sources    = {         -- one boolean per Chat Source key (FR-005, FR-006)
        general      = true,
        trade        = true,
        lfg          = true,
        localdefense = true,
        other        = true,
        say          = false,
        yell         = false,
        emote        = false,
        party        = false,
        raid         = false,
        instance     = false,
        guild        = false,
        whisper      = false,
    },
}
```

**Rules**
- On `ADDON_LOADED` for this addon, every missing key is filled from the defaults table; unknown
  keys are left untouched (forward compatibility).
- "Reset to defaults" overwrites `enabled`, `blockNames` and every `sources.*` with the defaults.
- The table is read on every message; no copy is cached so Options changes apply immediately
  (FR-009).
- Changing a default toward more filtering bumps `version` and the addon's MAJOR version
  (constitution III).

## Chat Source (static registry in `Core/Sources.lua`)

| Field | Type | Meaning |
|-------|------|---------|
| `key` | string | stable identifier, used as `sources[key]` |
| `label` | string | checkbox text in the Options panel |
| `tooltip` | string | one-line explanation under the checkbox |
| `default` | boolean | fresh-install state |
| `events` | string[] | chat events that belong to this source (empty for channel sources, which are resolved by `zoneChannelID`) |

The ordered list drives both the Options panel (same order, public channels first) and filter
registration. See `contracts/chat-sources.md` for the full table.

## Session Counter

`ns.hiddenCount` (number, starts at 0 on load, never saved). Incremented each time a filter
callback returns `true`. Read by `/mff status` and by the Options panel's status line (FR-011).

## Runtime namespace (`ns`, the addon's private table)

| Field | Set by | Used by |
|-------|--------|---------|
| `ns.IsCyrillic(text)` | Core/Detect.lua | Filter, Slash (`test`) |
| `ns.NameIsCyrillic(sender)` | Core/Detect.lua | Filter |
| `ns.SOURCES`, `ns.DEFAULTS` | Core/Sources.lua | Config, Options, Filter |
| `ns.EventToSource(event, zoneChannelID, channelBaseName)` | Core/Sources.lua | Filter |
| `ns.db` | Core/Config.lua | everyone |
| `ns.ResetDefaults()` | Core/Config.lua | Options, Slash |
| `ns.hiddenCount` | Core/Filter.lua | Options, Slash |
| `ns.ShouldHide(event, msg, sender, guid, zoneChannelID, channelBaseName)` | Core/Filter.lua | filter callbacks, Slash (`test`) |
| `ns.OpenOptions()` | UI/Options.lua | Slash |
