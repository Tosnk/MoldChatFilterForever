# Feature Specification: Rename and CurseForge Release Pipeline

**Feature Branch**: `002-curseforge-release`

**Created**: 2026-11-06

**Status**: Draft

**Input**: User description: "rename it to NoPetrovychChatFilter. Then prepare it for curseforge publishing (I already published EasyPrescience) make sure it supports changelogs and autoupdates with github hook (use docs and info from my existing addon) publish it to curse forge and provide me a project curse forge link"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The addon is called NoPetrovychChatFilter everywhere (Priority: P1)

The player sees "NoPetrovychChatFilter" in the AddOns list, the Options page, chat output, the
GitHub repository and the CurseForge project. No trace of the old spelling remains.

**Independent Test**: search the repository for the old name and find nothing; the game's AddOns
list shows the new name; `/npcf` opens the options.

**Acceptance Scenarios**:

1. **Given** the renamed addon is installed, **When** the game starts, **Then** the AddOns list,
   Options page and `/npcf status` prefix all read NoPetrovychChatFilter.
2. **Given** the repository, **When** searched for the old name, **Then** no file matches.
3. **Given** `/npcf` and `/nopetrovych` worked before, **When** typed now, **Then** they still work and
   `/npcf` is a third alias.

---

### User Story 2 - Pushing a version tag publishes to CurseForge with a changelog (Priority: P1)

The author bumps the TOC version and the CHANGELOG, tags `vX.Y.Z` and pushes. CurseForge
receives the packaged addon through its GitHub webhook, with the CHANGELOG section as the file's
changelog, and players with the CurseForge app receive the update automatically.

**Independent Test**: push `v1.0.0`; within minutes the CurseForge project lists a 1.0.0 file for
WoW: Forever whose changelog is the 1.0.0 section; the GitHub release 1.0.0 exists with a zip.

**Acceptance Scenarios**:

1. **Given** a CurseForge project with its GitHub packager webhook installed on the repository,
   **When** a `v*` tag is pushed, **Then** CurseForge packages the tag using `.pkgmeta` and shows
   the CHANGELOG.md content as the file changelog.
2. **Given** the TOC version or CHANGELOG does not match the tag, **When** the release workflow
   runs, **Then** it fails and no GitHub release is created.
3. **Given** the packaged zip, **When** extracted, **Then** it contains one folder
   `NoPetrovychChatFilter` with the TOC, Core, UI, icon, license and changelog, and none of the
   repository's specs, tests or tooling.

---

### User Story 3 - A public CurseForge project page exists (Priority: P2)

The author has a CurseForge project link to share, in the Chat & Communication category, marked
for WoW: Forever, with the README as the description and the addon icon as its avatar.

**Independent Test**: open the link; the project page shows the name, icon, description and a
downloadable 1.0.0 file.

## Requirements *(mandatory)*

- **FR-001**: Folder, TOC, SavedVariables, Settings category, chat prefix, repository and
  installation junction MUST use the name NoPetrovychChatFilter.
- **FR-002**: The repository layout MUST match what the CurseForge packager expects for this
  author's existing addon: TOC at repository root, `.pkgmeta` with `package-as`, `ignore`,
  `manual-changelog: CHANGELOG.md`, `license-output`.
- **FR-003**: `CHANGELOG.md` MUST have one `## X.Y.Z` section per release, newest first, and the
  release tooling MUST refuse a release whose TOC version or CHANGELOG section does not match.
- **FR-004**: A GitHub release with the packaged zip and the CHANGELOG section as notes MUST be
  created automatically on every `v*` tag.
- **FR-005**: The CurseForge packager webhook MUST be installed on the GitHub repository; the
  repository MUST be public so the packager can clone it.
- **FR-006**: The TOC MUST carry `## IconTexture` and `## X-Curse-Project-ID` once the project exists.
- **FR-007**: The webhook token MUST never be committed or printed.

## Success Criteria *(mandatory)*

- **SC-001**: Within 15 minutes of pushing `v1.0.0`, the CurseForge project lists file 1.0.0.
- **SC-002**: The file's changelog on CurseForge equals the 1.0.0 section of CHANGELOG.md.
- **SC-003**: A search for the old name across the repository returns zero matches.

## Assumptions

- The author's EasyPrescience setup (CurseForge GitHub webhook packager, `.pkgmeta` with manual
  changelog, hand-maintained TOC version, PowerShell release check) is the pattern to copy.
- Project creation on CurseForge has no API; it is done through the authors site in the browser.
- The repository becomes public; the addon is MIT licensed already.
