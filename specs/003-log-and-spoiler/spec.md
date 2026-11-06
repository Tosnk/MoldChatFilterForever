# Feature 003: Filtered-messages log, "Cyrillic names only" and spoiler mode

**Status**: implemented, awaiting in-game approval (2026-11-06)
**Depends on**: 001-cyrillic-chat-filter (replaces its two-mode settings)

## User request (final wording, same day)

1. Filtered messages are not only counted: next to the counter in the settings there is a Log
   button that opens every filtered message as one list.
2. Options become three peers plus the channel list:
   - **Filter enabled** as before; while off it locks every other option.
   - **Cyrillic names only**: filters ONLY messages from Cyrillic-named characters. Does not
     lock anything. When on, Cyrillic text from Latin-named players is not filtered.
   - **Use spoiler instead of hiding**: does not lock anything. Collapses behind a click-to-read
     link (like the client's mature-language filter) instead of removing. With "names only" on
     it collapses only Cyrillic-named senders; otherwise it collapses every Cyrillic match. It
     follows the channel selection like hiding does.
   Spoiler was the default in 1.1.0; from 1.1.1 hiding is the default and spoiler is opt-in.

## Requirements

- **R1 Log storage**: every line the addon acts on (hidden or collapsed) is recorded with time,
  action, chat source, sender and original text. Session only (not saved), newest 500 kept, the
  counter is not capped and survives clearing the log.
- **R2 Log UI**: the Options page shows "Filtered this session: N" and an "Open log" button on the
  same row. The window lists the entries oldest to newest, scrolls with the mouse wheel, updates
  live while open, has Clear and close buttons, closes on Escape. `/npcf log` toggles it.
- **R3 Decision** (`ns.Judge`): enabled → not own message → source selected → match, where
  match = Cyrillic sender name, or (namesOnly off and Cyrillic text). Verdict is "spoiler" when
  `db.spoiler`, else "hide". Never-touched events (system, Battle.net) stay untouched.
- **R4 Spoiler rendering**: the line is kept, its text replaced by
  `[Petrovych detected, click to read]`; a click swaps the original text back in place in every
  chat window still holding the line, or shows it in the item-ref popup if it scrolled out.
- **R5 Lock**: only "Filter enabled" locks; every other row is its child in the Settings panel.
- **R6 Defaults and upgrade**: enabled on, namesOnly off, spoiler off (db version 2; a version < 2 save gets spoiler reset). 1.0.x saved variables
  migrate: `hideAllCyrillic = false, blockNames = true` → `namesOnly = true`; anything else →
  `namesOnly = false`; the old keys are removed.

## Design notes

- Chat filter: returning `false, newText, <every other arg verbatim>` rewrites the line; the client
  takes all args from the returned list, so they are passed back with `...`.
- Link type `addon:NPCF:<logId>`; the click arrives through `EventRegistry` "SetItemRef" (same path
  BugGrabber uses on this client). Reveal uses `ScrollingMessageFrame:TransformMessages`.
- Settings rows re-evaluate their enabled state when their parent setting changes, so every
  locked row is a child of the master switch.

## Out of scope

- Persisting the log across sessions.
- Replacing the sender name in spoiler mode (the name link must stay clickable).
