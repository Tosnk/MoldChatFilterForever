# Implementation Plan: Rename and CurseForge Release Pipeline

**Branch**: `002-curseforge-release` | **Date**: 2026-11-06 | **Spec**: [spec.md](spec.md)

## Summary

Rename everything to NoPetrovychChatFilter, flatten the addon to the repository root (the layout
the CurseForge GitHub packager and the author's EasyPrescience repo use), add `.pkgmeta`,
`CHANGELOG.md`, a release check script and a tag-triggered GitHub release workflow, create the
CurseForge project in the browser, install its packager webhook on the repository, make the
repository public, and push `v1.0.0`.

## Technical Context

**Packaging**: CurseForge GitHub webhook packager (push events, `.pkgmeta`), as on EasyPrescience
(`.pkgmeta`: package-as, ignore, manual-changelog CHANGELOG.md, license-output).

**Versioning**: hand-maintained `## Version` in the TOC + matching `## X.Y.Z` in CHANGELOG.md +
git tag `vX.Y.Z`; `scripts/release-check.ps1` and the release workflow enforce agreement.

**GitHub releases**: `.github/workflows/release.yml` on `v*` tags: check, test, zip, `gh release create`.

**Install**: directory junction `AddOns\NoPetrovychChatFilter` → repository root (the game ignores
the extra tooling folders).

## Constitution Check

| Principle | Check | Status |
|-----------|-------|--------|
| I. Forever only | TOC still declares 16001 only | PASS |
| II. Zero dependencies | packaging adds no runtime code | PASS |
| III. Private chat untouchable | defaults unchanged | PASS |
| IV. Whole-message removal | unchanged | PASS |
| V. Settings in Options UI | category renamed only | PASS |
| VI. Testable core | harness paths updated; release workflow runs it | PASS |
| Development Workflow | junction now targets repository root; constitution amended (PATCH) | PASS |

## Project Structure

```text
NoPetrovychChatFilter.toc      Core/   UI/   icon.png   LICENSE   CHANGELOG.md   README.md
.pkgmeta                       scripts/release-check.ps1
.github/workflows/tests.yml    .github/workflows/release.yml
specs/  tests/  .specify/  .claude/     (ignored by the packager)
```
