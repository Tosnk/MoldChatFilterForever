# Tasks: Rename and CurseForge Release Pipeline

**Input**: [spec.md](spec.md), [plan.md](plan.md)

## Phase 1: Rename (US1)

- [ ] T101 [US1] Move `MoldFilterForver/*` to repository root; rename TOC to `MoldChatFilterForever.toc`
- [ ] T102 [US1] Replace every occurrence of the old name (addon, SavedVariables, slash globals, settings variable prefix, docs, tests, workflows)
- [ ] T103 [US1] Add `/mcff` alias; keep `/mff` and `/moldfilter`
- [ ] T104 [US1] Rename GitHub repository and local folder; recreate the AddOns junction to the repository root
- [ ] T105 [US1] Amend constitution Development Workflow (junction target) as PATCH 1.0.1

## Phase 2: Packaging (US2)

- [ ] T106 [US2] Add `.pkgmeta` (package-as, ignore tooling folders, manual-changelog CHANGELOG.md, license-output LICENSE)
- [ ] T107 [US2] Add `CHANGELOG.md` with the 1.0.0 section
- [ ] T108 [US2] Add `scripts/release-check.ps1` (TOC version and CHANGELOG header must match)
- [ ] T109 [US2] Add `.github/workflows/release.yml` (tag → check → tests → zip → GitHub release with CHANGELOG notes)
- [ ] T110 [US2] Add `icon.png` and `## IconTexture` to the TOC
- [ ] T111 [US2] Run `uv run tests/run_tests.py`; green

## Phase 3: CurseForge (US3)

- [ ] T112 [US3] Make the repository public
- [ ] T113 [US3] Create the CurseForge project (name, summary, Chat & Communication, WoW: Forever, MIT, description from README, avatar icon.png)
- [ ] T114 [US3] Add `## X-Curse-Project-ID` to the TOC
- [ ] T115 [US3] Install the project's packager webhook on the GitHub repository (push events); never print the token
- [ ] T116 [US3] Merge to main, tag `v1.0.0`, push the tag; confirm the GitHub release and the CurseForge 1.0.0 file with changelog
