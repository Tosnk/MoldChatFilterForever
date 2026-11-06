# Contract: Chat Sources and Event Routing

Every chat event the addon hooks resolves to exactly one source key. The filter consults
`MoldChatFilterForeverDB.sources[key]` for that key.

## Source registry (order = Options panel order)

| key | label | default | events / resolution |
|-----|-------|---------|---------------------|
| `general` | General | ON | `CHAT_MSG_CHANNEL` with `zoneChannelID == 1` (fallback `channelBaseName == "General"`) |
| `trade` | Trade | ON | `CHAT_MSG_CHANNEL` with `zoneChannelID == 2` (fallback `"Trade"`) |
| `lfg` | LookingForGroup | ON | `CHAT_MSG_CHANNEL` with `zoneChannelID == 26` (fallback `"LookingForGroup"`) |
| `localdefense` | LocalDefense | ON | `CHAT_MSG_CHANNEL` with `zoneChannelID == 22` (fallback `"LocalDefense"`) |
| `other` | Other channels (World, custom, ...) | ON | any other `CHAT_MSG_CHANNEL` |
| `say` | Say | OFF | `CHAT_MSG_SAY` |
| `yell` | Yell | OFF | `CHAT_MSG_YELL` |
| `emote` | Emote | OFF | `CHAT_MSG_EMOTE`, `CHAT_MSG_TEXT_EMOTE` |
| `party` | Party | OFF | `CHAT_MSG_PARTY`, `CHAT_MSG_PARTY_LEADER` |
| `raid` | Raid | OFF | `CHAT_MSG_RAID`, `CHAT_MSG_RAID_LEADER`, `CHAT_MSG_RAID_WARNING` |
| `instance` | Instance / Battleground | OFF | `CHAT_MSG_INSTANCE_CHAT`, `CHAT_MSG_INSTANCE_CHAT_LEADER`, `CHAT_MSG_BATTLEGROUND`, `CHAT_MSG_BATTLEGROUND_LEADER` |
| `guild` | Guild / Officer | OFF | `CHAT_MSG_GUILD`, `CHAT_MSG_OFFICER` |
| `whisper` | Whisper (incoming) | OFF | `CHAT_MSG_WHISPER` |

Not hooked, by design: `CHAT_MSG_WHISPER_INFORM` (own outgoing), `CHAT_MSG_BN_*` (Battle.net),
`CHAT_MSG_SYSTEM`, `CHAT_MSG_MONSTER_*`, loot, combat, achievements.

## Filter callback contract

```
filter(chatFrame, event, text, sender, language, channelName, target, flags,
       zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, ...)
  -> true   (drop the whole line)
  -> false  (show unchanged; never returns modified arguments)
```

Decision order (`ns.ShouldHide`):
1. `db.enabled == false` → show.
2. Sender is the player (`guid == UnitGUID("player")`, else name match) → show.
3. `source = EventToSource(event, zoneChannelID, channelBaseName)`; `db.sources[source] ~= true` → show.
4. `db.blockNames and NameIsCyrillic(sender)` → hide.
5. `IsCyrillic(text)` → hide.
6. Otherwise show.

`NameIsCyrillic` strips everything from the first `-` onward before testing (realm suffix).

## Detection contract (`Core/Detect.lua`)

- `IsCyrillic(s)` returns `true` iff `s` contains a byte sequence in
  `[\208-\211][\128-\191]` or `\212[\128-\175]`; `nil`/`""` → `false`.
- Must not allocate; must not depend on any global except `string`.
