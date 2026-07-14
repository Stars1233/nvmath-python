# Release Notes

Release notes for nvmath-python are managed with
[reno](https://docs.openstack.org/reno/). Each user-visible change ships
with a small YAML "note fragment" under `releasenotes/notes/`; reno reads
these alongside git history at docs-build time and renders the
`Release Notes` page in the Sphinx documentation.

Configuration lives in [`reno.yaml`](../reno.yaml) at the repository root.

---

## Adding a release note

### With `reno` installed (recommended)

From the repository root:

```bash
reno new short-slug-describing-the-change
```

This creates a new file under `releasenotes/notes/` named
`short-slug-describing-the-change-<16-hex-chars>.yaml` and pre-populates
it with the section template defined in `reno.yaml`. Open it, uncomment
the relevant section header(s), and replace the placeholder text with
your note. Then commit the YAML file alongside the code change in the
same PR.

### Without `reno` installed

Copy the template snippet shown below into a new file at
`releasenotes/notes/<your-slug>-<16-hex-chars>.yaml`. The
16-character hex suffix prevents merge conflicts when two PRs choose
similar slugs — pick anything random and unique (e.g.,
`a1b2c3d4e5f60718`).

```yaml
---
# Uncomment a section header and replace with your own note.
#release_summary:
#features:
#api:
#deprecations:
#fixes:
#issues:
#security:
#doc:
  - Write a note here.
```

### Note sections

The available sections are declared in `reno.yaml` and rendered in this
order on the release-notes page:

| Section            | YAML key          | Use for                                                 |
| ------------------ | ----------------- | ------------------------------------------------------- |
| Prelude            | `release_summary` | A short paragraph describing the release theme          |
| Breaking Changes   | `api`             | Backwards-incompatible API changes                      |
| Deprecations       | `deprecations`    | APIs newly marked deprecated                            |
| New Features       | `features`        | User-visible additions                                  |
| Bugs Fixed         | `fixes`           | User-visible bug fixes                                  |
| Known Issues       | `issues`          | Unfixed problems users should be aware of               |
| Security Issues    | `security`        | CVE-class fixes and disclosures                         |
| Documentation Changes | `doc`          | Notable documentation updates                           |

Each section's body is a YAML list. Use `|` for multi-line entries so
RST formatting is preserved:

```yaml
---
features:
  - |
    Add :py:func:`nvmath.fft.fft` support for FP8 input tensors on
    Blackwell GPUs. See :ref:`fft-fp8` for usage notes.
fixes:
  - Fixed a memory leak in the Matmul handle cache.
```

The chosen section also drives the semver bump heuristic (see
`semver_major`, `semver_minor`, `semver_patch` in `reno.yaml`):

- `api` → major bump
- `features`, `deprecations` → minor bump
- `fixes`, `security`, `doc` → patch bump
- `issues` → no bump (known issues do not warrant a release)

---

## Cutting a release

Reno relies on **branch names** and **tag names** matching the regexes
configured in `reno.yaml`. Deviating from the conventions below will
cause notes to be attributed to the wrong release or omitted entirely.

### Naming conventions (configured in `reno.yaml`)

| Concept              | Format                                          | Examples                            |
| -------------------- | ----------------------------------------------- | ----------------------------------- |
| Release branch       | `release-X.Y.x` (literal lowercase `x` suffix)  | `release-0.10.x`, `release-1.0.x`   |
| Release tag          | `vX.Y.Z` with optional PEP 440 pre-release      | `v0.10.0`, `v0.10.1`, `v1.0.0`      |
| Pre-release tag      | `vX.Y.Z` + `aN` / `bN` / `rcN`                  | `v0.10.0rc0`, `v0.10.0rc1`, `v1.0.0b1` |

Reno strips the pre-release suffix (`aN` / `bN` / `rcN`) when bucketing
notes, so `v0.10.0rc0`, `v0.10.0rc1`, and `v0.10.0` all collapse under a
single "v0.10.0" heading on the rendered notes page.

### Branching procedure

A new minor or major release lives on its own long-lived branch. To
start the `0.10` series:

```bash
# 1. From main, at the commit you want to release as rc0:
git checkout main
git pull --ff-only

# 2. Tag the release-candidate. The tag MUST exist before the branch
#    is cut — reno's stop_at_branch_base relies on the branch base
#    being a tagged commit matching release_tag_re.
git tag v0.10.0rc0
git push origin v0.10.0rc0

# 3. Create the release branch from that exact tag:
git checkout -b release-0.10.x v0.10.0rc0
git push -u origin release-0.10.x
```

After this, `main` continues advancing toward 0.11; `release-0.10.x`
receives only commits destined for the 0.10 line (bugfixes,
backports, the eventual final tag).

### RC cycle

For each subsequent release candidate, tag on the release branch:

```bash
git checkout release-0.10.x
# (cherry-pick bugfixes from main as needed; each one should include
#  its own release note YAML in the same commit)
git tag v0.10.0rc1
git push origin release-0.10.x v0.10.0rc1
```

### Final release

The final tag goes on the release branch when the rc cycle ends:

```bash
git checkout release-0.10.x
git tag v0.10.0
git push origin release-0.10.x v0.10.0
```

No `reno build` step exists — reno renders notes live at docs-build
time from git history plus the YAML fragments. Tagging is the entire
release operation as far as release notes are concerned.

### Patch releases

Patch releases (`v0.10.1`, `v0.10.2`, …) live on the same
`release-0.10.x` branch:

```bash
git checkout release-0.10.x
# (cherry-pick fixes from main with their release-note YAML)
git tag v0.10.1
git push origin release-0.10.x v0.10.1
```

---

## How reno reads this layout

A few configuration choices are worth knowing because they constrain
the conventions above:

- **`stop_at_branch_base: true`** — when docs build from a release
  branch, reno stops scanning at the branch base (the `vX.Y.0rc0`
  tag). This is why the rc0 tag must exist *before* the branch is
  cut: it anchors the boundary between "this release's notes" and
  "future main work."
- **`branch_name_re: 'release-\d.+\.x'`** — enables reno to enumerate
  all release branches and deduplicate notes that have already shipped
  on an earlier release. A note cherry-picked from `main` into
  `release-0.10.x` will be attributed to `v0.10.0` and *not* re-listed
  under a later `v0.11.0` — reno detects the prior shipping via this
  pattern.
- **`release_tag_re` is anchored with `$`** — `v0.10.0-something-else`
  would *not* match. Stick to the documented tag forms.
- **Fragment file paths are sticky** — once a fragment is committed
  under `releasenotes/notes/<name>-<hash>.yaml`, do not rename or
  relocate it. Reno tracks notes by the 16-character hash suffix in
  the filename, but the path is what release-branch checkouts use to
  find the content. Renaming a fragment after it has shipped on a
  release branch breaks cross-branch dedup.

For deeper detail on each configuration knob, see the comments in
[`reno.yaml`](../reno.yaml) and the upstream reno documentation at
<https://docs.openstack.org/reno/>.
