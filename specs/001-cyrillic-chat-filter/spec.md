# Feature Specification: Cyrillic Chat Filter

**Feature Branch**: `001-cyrillic-chat-filter`

**Created**: 2026-11-06

**Status**: Draft

**Input**: User description: "Create addon for wow forever only that: 1. Can filter the cyrillic text in chat and delete full message along with nickname info. Can filter out ALL text from cyrillic-named chars in the same way. 2. It should provide possibility to select where this should work. For example: LFG, City, Trade filtered. Raid/Party/Yell/Say - Not. Name it MoldChatFilterForever. Install it to my wow forever dir. Settings should be simple and be accessible from UI, not only chat."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Public channels free of Cyrillic messages (Priority: P1)

A player on an EU WoW: Forever realm opens Trade, General or LookingForGroup chat and sees only
messages that contain no Cyrillic letters. Any message written in Cyrillic (Russian, Ukrainian,
Bulgarian, ...) is removed entirely: the channel tag, the sender's name and the text never appear,
and nothing is left behind to show a message was removed.

**Why this priority**: This is the core complaint. Public channels on EU realms carry a large
share of Cyrillic text the player cannot read, and it buries the lines they want.

**Independent Test**: With the addon enabled and default settings, have a second character (or a
friend) post a Cyrillic line and a Latin line in Trade. Only the Latin line is shown, and the
Latin line looks exactly as it did without the addon.

**Acceptance Scenarios**:

1. **Given** the addon is enabled with defaults, **When** a message containing at least one Cyrillic
   letter arrives in General, Trade, LookingForGroup, LocalDefense or a custom channel such as
   "World", **Then** the whole line (channel tag, sender, text) is not shown in any chat window.
2. **Given** the addon is enabled with defaults, **When** a message with only Latin letters, digits,
   punctuation or item links arrives in those channels, **Then** it is shown unchanged.
3. **Given** the addon is enabled with defaults, **When** the player themselves types Cyrillic into
   Trade, **Then** their own line is still shown to them.
4. **Given** the addon is disabled via its master switch, **When** a Cyrillic message arrives,
   **Then** it is shown as if the addon were not installed.

---

### User Story 2 - Ignore everything from Cyrillic-named characters (Priority: P2)

The player wants characters whose names are written in Cyrillic to be silent in the filtered
channels, even when a given message of theirs happens to be in Latin letters (for example
"WTS gold" or "LFM").

**Why this priority**: Cyrillic-named characters are the main source of the unwanted text, and
their Latin-letter messages are usually advertising. It is a separate switch so the player can
keep it off if they want to see those.

**Independent Test**: With "Filter Cyrillic-named players" on, a character named in Cyrillic posts
"LFM SM" in LookingForGroup. The line is not shown. With both modes off, the line is shown. With
only mode 2 on, a Latin-named player's Cyrillic line is shown while the Cyrillic-named player's
Latin line is hidden.

**Acceptance Scenarios**:

1. **Given** the name switch is on, **When** a character whose name contains Cyrillic letters posts
   any message in a filtered source, **Then** the whole line is hidden.
2. **Given** the name switch is on, **When** a Cyrillic-named character posts in a source that is
   not filtered (for example Party), **Then** the line is shown.
3. **Given** a sender name is realm-qualified (`Name-Realm`), **When** the name part contains
   Cyrillic, **Then** the sender counts as Cyrillic-named; the realm part is never considered.

---

### User Story 3 - Choose where filtering applies, from the Options UI (Priority: P3)

The player opens Escape, Options, AddOns, MoldChatFilterForever and sees a short list of chat
sources with a checkbox each: General, Trade, LookingForGroup, LocalDefense, Other channels,
Say, Yell, Emote, Party, Raid, Instance/Battleground, Guild/Officer, Whisper. Public channels are
checked by default; everything else is unchecked. Changes apply immediately and survive relog.

**Why this priority**: The player reads and writes Cyrillic with friends in Party, Raid and
whispers. Filtering must never leak into those unless they ask for it.

**Independent Test**: Untick "Trade", post a Cyrillic line in Trade, see it appear. Tick "Party",
have a party member post Cyrillic, see it disappear. `/reload`; the ticks are as left.

**Acceptance Scenarios**:

1. **Given** a fresh install, **When** the Options panel is opened, **Then** General, Trade,
   LookingForGroup, LocalDefense and Other channels are checked and Say, Yell, Emote, Party, Raid,
   Instance/Battleground, Guild/Officer and Whisper are unchecked.
2. **Given** the panel is open, **When** a source checkbox is changed, **Then** the next message
   from that source follows the new setting without a reload.
3. **Given** settings were changed, **When** the player reloads the UI or logs out and back in,
   **Then** the settings are as they left them.
4. **Given** the panel is open, **When** the player clicks "Reset to defaults", **Then** every
   setting returns to its fresh-install value.
5. **Given** the player types `/mff` (or `/moldfilter`) with no arguments, **Then** the Options panel
   opens on the addon's page.

---

### User Story 4 - Quick status and test from chat (Priority: P4)

The player can type `/mff status` to see whether filtering is on, which sources are filtered and
how many lines were hidden this session, `/mff on` or `/mff off` to flip the master switch, and
`/mff test <text>` to check whether a given text would be hidden.

**Why this priority**: Convenience only; everything here is also available in the panel.

**Independent Test**: `/mff test привет` prints "hidden"; `/mff test hello` prints "shown".

**Acceptance Scenarios**:

1. **Given** the addon is loaded, **When** `/mff status` is typed, **Then** one or two lines report
   master state, hidden-line count for this session and the list of filtered sources.
2. **Given** the addon is loaded, **When** `/mff off` is typed, **Then** the master switch is off and
   the Options panel reflects it when next opened.

---

### Edge Cases

- A message that is mostly Latin but contains one Cyrillic letter (for example an item link whose
  name is in a Russian client's locale) counts as Cyrillic and is hidden. Precision over recall is
  not attempted in this version.
- Latin-transliterated Russian ("privet", "prodam") is not Cyrillic and is not hidden.
- Greek, accented Latin (ä, é, ø), CJK and emoji are not Cyrillic and are not hidden.
- Chat bubbles above characters' heads are drawn by the client and are out of scope; the message
  is still hidden in the chat windows.
- System messages, NPC speech, combat log and loot messages are never touched.
- Battle.net whispers (from friends on the friends list) are never touched.
- A message with an empty or missing sender is judged on its text only.
- When the addon's settings have never been saved (fresh install), defaults apply without error.
- A filtered source whose checkbox is on but whose master switch is off shows everything.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The addon MUST hide any chat message whose text contains at least one Cyrillic letter
  when it arrives from a filtered source.
- **FR-002**: Hiding MUST remove the entire chat line: channel tag, sender name, text and any
  timestamp the client would add. No placeholder is shown.
- **FR-003**: Two filter modes MUST exist. Mode 1 "Filter all Cyrillic messages" hides any message
  containing Cyrillic letters (FR-001). Mode 2 "Filter Cyrillic-named players" hides every message
  from a sender whose character name contains at least one Cyrillic letter, in filtered sources,
  regardless of the message text or script. While mode 1 is on, mode 2 MUST be forced on and its
  control locked. With only mode 2 on, Cyrillic text from Latin-named players MUST stay visible.
- **FR-004**: The addon MUST never hide messages sent by the player's own character.
- **FR-005**: Filtering MUST be configurable per chat source with these sources: General, Trade,
  LookingForGroup, LocalDefense, Other channels (any other numbered or custom channel), Say, Yell,
  Emote, Party, Raid, Instance/Battleground, Guild/Officer, Whisper.
- **FR-006**: Default state MUST be: General, Trade, LookingForGroup, LocalDefense and Other
  channels ON; all remaining sources OFF; master switch ON; mode 1 ON; mode 2 ON.
- **FR-007**: All settings MUST be editable from the game's Options, AddOns panel with checkboxes
  and a "Reset to defaults" control.
- **FR-008**: Settings MUST persist per account and survive `/reload` and relog.
- **FR-009**: Setting changes MUST take effect on the next message without a reload.
- **FR-010**: The addon MUST provide `/mff` and `/moldfilter` commands: no argument opens the
  Options page; `on`, `off`, `status`, `test <text>` behave as described in User Story 4.
- **FR-011**: The addon MUST count hidden lines for the current session and show the count in the
  Options panel and in `/mff status`.
- **FR-012**: The addon MUST load only on WoW: Forever and declare no other client versions.
- **FR-013**: The addon MUST NOT depend on any library or other addon.
- **FR-014**: Realm-qualified sender names MUST be judged on the character-name part only.

### Key Entities

- **Chat Source**: a user-facing grouping of chat events (for example "Trade", "Party") with an
  on/off state and a default.
- **Settings**: master switch, name switch and the per-source states; stored per account.
- **Session Counter**: number of lines hidden since login; not persisted.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a 10-minute sample of Trade, General and LFG chat on an EU realm, 100% of lines
  containing Cyrillic letters are absent from the chat window.
- **SC-002**: 0 messages from Party, Raid, Guild or Whisper are hidden at default settings during
  the same session.
- **SC-003**: A player can find and change the "Trade" switch in the Options UI in under 30 seconds
  without reading documentation.
- **SC-004**: Settings changed in one session are identical after `/reload` and after relog, 100% of
  the time.
- **SC-005**: No Lua error is raised by the addon during a full play session with BugSack enabled.

## Assumptions

- The player's own locale is not Russian; item and spell links in their chat window are therefore
  in Latin script unless pasted by a Cyrillic-locale client.
- "City" in the request means the General channel (it is the city/zone channel in Forever), and
  "LFG" means the LookingForGroup channel.
- WoW: Forever exposes the same addon Settings panel API as the modern client (confirmed by other
  addons installed in the user's Forever folder).
- Chat-source defaults follow the user's example: LFG, City (General), Trade filtered; Raid, Party,
  Yell, Say not. Whisper, Guild, Emote and Instance are grouped with the unfiltered side because
  they are private or group chat.
- Only one account profile is needed; per-character settings are out of scope for this version.
- Detecting the language precisely (Russian vs Ukrainian) is out of scope; the filter is by script.
