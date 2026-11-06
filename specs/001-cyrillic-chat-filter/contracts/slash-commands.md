# Contract: Slash Commands

Aliases: `/mcff`, `/mff`, `/moldfilter`. Arguments are case-insensitive; the first word is the command.

| Command | Effect | Output (chat, prefixed `MoldChatFilterForever:`) |
|---------|--------|------------------------------------------|
| *(none)* | Opens Options → AddOns → MoldChatFilterForever | none |
| `on` | `db.enabled = true` | status line |
| `off` | `db.enabled = false` | status line |
| `toggle` | flips `db.enabled` | status line |
| `status` | no change | `Filter ON/OFF, names ON/OFF, hidden this session: N` then `Filtering: General, Trade, ...` (keys whose source is on, in registry order; `none` if empty) |
| `test <text>` | no change | `"<text>" -> hidden` or `-> shown`, evaluated as if it arrived in Trade from a Latin-named stranger |
| `reset` | `ns.ResetDefaults()` | `Settings reset to defaults.` then status line |
| anything else | no change | one-line usage list |

Every state change made here is visible in the Options panel the next time it is shown, because
the panel reads from `db` (the Settings API re-reads `variableTbl` on open).
