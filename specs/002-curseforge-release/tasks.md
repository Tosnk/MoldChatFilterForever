# Tasks: Rename and CurseForge Release Pipeline

**Input**: [spec.md](spec.md), [plan.md](plan.md)

## Phase 1: Rename (US1)

- [x] T101 [US1] Move `MoldFilterForver/*` to repository root; rename TOC to `NoPetrovychChatFilter.toc`
- [x] T102 [US1] Replace every occurrence of the old name (addon, SavedVariables, slash globals, settings variable prefix, docs, tests, workflows)
- [x] T103 [US1] Add `/npcf` alias; keep `/npcf` and `/nopetrovych`
- [x] T104 [US1] Rename GitHub repository and local folder; recreate the AddOns junction to the repository root
- [x] T105 [US1] Amend constitution Development Workflow (junction target) as PATCH 1.0.1

## Phase 2: Packaging (US2)

- [x] T106 [US2] Add `.pkgmeta` (package-as, ignore tooling folders, manual-changelog CHANGELOG.md, license-output LICENSE)
- [x] T107 [US2] Add `CHANGELOG.md` with the 1.0.0 section
- [x] T108 [US2] Add `scripts/release-check.ps1` (TOC version and CHANGELOG header must match)
- [x] T109 [US2] Add `.github/workflows/release.yml` (tag → check → tests → zip → GitHub release with CHANGELOG notes)
- [x] T110 [US2] Add `icon.png` and `## IconTexture` to the TOC
- [x] T111 [US2] Run `uv run tests/run_tests.py`; green

## Phase 3: CurseForge (US3)

- [x] T112 [US3] Make the repository public
- [x] T113 [US3] Create the CurseForge project (name, summary, Chat & Communication, WoW: Forever, MIT, description from README, avatar icon.png)
- [x] T114 [US3] Add `## X-Curse-Project-ID` to the TOC
- [x] T115 [US3] Install the project's packager webhook on the GitHub repository (push events); never print the token
- [x] T116 [US3] Merge to main, tag `v1.0.0`, push the tag; confirm the GitHub release and the CurseForge 1.0.0 file with changelog

## Outcome (2026-11-06)

- CurseForge project 1786481 created: https://www.curseforge.com/wow/addons/nopetrovychchatfilter (pending moderation).
- Packager webhook installed; tag `v1.0.0` was packaged by CurseForge within a minute (one `NoPetrovychChatFilter/` folder, no tooling files).
- GitHub release 1.0.0 was created by hand because the first workflow run failed on CRLF line endings; `.gitattributes` now forces LF and the check strips CR, so `v1.0.1+` will release automatically.
- The AddOns junction was removed at the user's request; the addon will be installed from CurseForge once approved.

## Rename outcome (2026-11-06, later the same day)

- Renamed everywhere to NoPetrovychChatFilter: repo `Tosnk/NoPetrovychChatFilter`, folder `C:\Repos\NoPetrovychChatFilter`, CurseForge project name + slug (`/wow/addons/nopetrovychchatfilter`, same project ID 1786481 and webhook), slash commands `/npcf` and `/nopetrovych`.
- 1.0.1 (rename) and 1.0.2 (new icon) shipped by tag; CurseForge packaged both, GitHub release workflow now runs automatically (CRLF and literal-newline bugs fixed; `workflow_dispatch` added for re-running an existing tag).
- Old folder `C:\Repos\MoldChatFilterForever` is locked by another process and still has to be deleted by hand.
