# Releasing TemporalFocus.jl

This document covers first registration in the [General](https://github.com/JuliaRegistries/General) registry and subsequent releases.

**This prep PR does not create git tags and does not register the package.** Registration is a human post-merge step.

## Preconditions

- [ ] `main` is green (CI, reviews)
- [ ] `Project.toml` `version` matches the intended release (currently `0.1.0`)
- [ ] `CHANGELOG.md` has a dated section for that version (see also #24 / related changelog PRs)
- [ ] Top-level `LICENSE` exists (dual MIT OR Apache-2.0); `LICENSE-MIT` and `LICENSE-APACHE` remain the canonical full texts
- [ ] TagBot workflow is present (`.github/workflows/TagBot.yml`)
- [ ] Optional but recommended for versioned docs: repository secret `DOCUMENTER_KEY` (SSH deploy key) so TagBot tag pushes can trigger the Documentation workflow

### UUID hygiene (first registration only)

`Project.toml` currently has:

```toml
uuid = "7f3c9f2a-6b2e-4d91-9c4f-1a2b3c4d5e6f"
```

**Review this UUID before the first `@JuliaRegistrator register` comment.** Once a package is registered in General, the UUID is effectively immutable. Do not regenerate it after registration. Only change it *before* first registration if you confirm it was hand-crafted or collides with an existing package.

Generate a fresh UUID if needed:

```julia
using UUIDs
uuid4()
```

## First registration (v0.1.0)

1. **Freeze `main`** — merge all release-prep and changelog work; ensure `Project.toml` version is `0.1.0` and CI is green.
2. **Do not pre-create a git tag** (e.g. `v0.1.0`). With TagBot enabled, pre-tagging races or confuses automated tagging after registration.
3. On a **commit on the default branch** you want to register, open an **issue comment** or a **commit comment** and write:

   ```text
   @JuliaRegistrator register
   ```

   Optionally add release notes:

   ```text
   @JuliaRegistrator register

   Release notes:

   First public release of TemporalFocus.jl.
   ```

   Registrator only accepts those comment locations (issue comment or commit comment). Do **not** put the trigger only on a GitHub Release body — that does not open a General PR.

4. **Workflow-file / TagBot caveat** — if the *registration target commit* itself adds or changes `.github/workflows/*.yml` (including this prep PR’s TagBot file), GitHub blocks `GITHUB_TOKEN` from creating tags/releases for that commit ([TagBot: commits that modify workflow files](https://github.com/JuliaRegistries/TagBot#commits-that-modify-workflow-files)). Prefer registering a **later** default-branch commit that does not touch workflows, or use TagBot’s documented PAT / manual tag workaround. Still do not pre-tag from the prep PR.

5. **Wait for General** — Registrator opens a PR against [JuliaRegistries/General](https://github.com/JuliaRegistries/General). AutoMerge runs checks; maintainers may comment. Do not force-merge unless you know what you are doing.
6. **TagBot tags** — after the General PR merges, [JuliaTagBot](https://github.com/JuliaTagBot) comments on the registration issue/PR and the TagBot workflow creates the `vX.Y.Z` git tag and GitHub release. You can also run the TagBot workflow manually via `workflow_dispatch` if needed. With `DOCUMENTER_KEY` configured, tag pushes can deploy stable docs via the Documentation workflow.

## Subsequent releases

1. Bump `version` in `Project.toml` (semver).
2. Update `CHANGELOG.md` (move Unreleased notes under the new version heading with a date).
3. Merge to `main` (prefer a commit that does not only change workflow files if you rely on automatic TagBot tagging).
4. Comment `@JuliaRegistrator register` on the release commit (issue comment or commit comment on the default branch).
5. Wait for General AutoMerge; TagBot creates the tag.

## Explicit non-goals of release-prep PRs

- No `git tag` / GitHub Release creation in prep PRs
- No `@JuliaRegistrator register` until after prep is merged and review is complete
- No UUID changes after the package is in General

## References

- [Registrator.jl](https://github.com/JuliaRegistries/Registrator.jl)
- [General registry](https://github.com/JuliaRegistries/General)
- [TagBot](https://github.com/JuliaRegistries/TagBot)
- [Package naming / registration guidelines](https://github.com/JuliaRegistries/General#registering-a-package-in-general)
