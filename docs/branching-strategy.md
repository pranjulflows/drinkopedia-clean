# Branching strategy

Two long-lived branches, and a short-lived branch for every piece of work.

```
main            ──●───────────────────────●──────────>   release only
                   ↑                       ↑
                   │  release PR           │  release PR
                   │                       │
development     ──●──●─────●───────●──────●───────────>   integration, default target
                      ↑     ↑       ↑
                      │     │       │  PR
              feat/spirit-filter   docs/branching-strategy
```

## The rules

1. **`main` is release-only.** Nothing lands on it except a release PR from
   `development`, or a hotfix (below). It is the repo's default branch.
2. **`development` is the integration branch and the default PR target.** Every
   feature, fix and doc PR targets `development`, never `main`.
3. **Never commit directly to `main` or `development`.** Both are reached only through a
   pull request.
4. **Every new thing gets its own branch,** cut fresh from an up-to-date `development`.
   One branch per piece of work — not one branch per day, and not a long-running personal
   branch that accumulates unrelated changes.
5. **Branches are short-lived.** Merge it or close it; delete the branch after merge.

## Branch names

`<type>/<short-kebab-summary>` — lowercase, no ticket numbers unless one exists.

| Type | For |
|---|---|
| `feat/` | A new capability — `feat/spirit-filter`, `feat/onboarding-taste-intro` |
| `fix/` | A bug fix — `fix/abv-chip-on-null` |
| `refactor/` | Behaviour-preserving restructuring — `refactor/extract-empty-states` |
| `docs/` | Documentation only — `docs/branching-strategy` |
| `test/` | Tests only — `test/spirit-repository-cache-ttl` |
| `chore/` | Dependencies, tooling, housekeeping — `chore/bump-drift` |
| `ci/` | Workflow and pipeline changes — `ci/run-on-development-prs` |

## The normal flow

```bash
git checkout development
git pull
git checkout -b feat/spirit-filter

# ... work, committing as you go ...

git push -u origin feat/spirit-filter
gh pr create --base development
```

`--base development` is not optional. `gh` infers the repo default, which is `main`, so
omitting it opens the PR against the wrong branch.

After merge:

```bash
git checkout development && git pull && git branch -d feat/spirit-filter
```

## Releasing

When `development` is in a state worth shipping, open a PR from `development` into
`main`. That PR is the release: its body is the changelog. Tag `main` after the merge.

Nothing else reaches `main`.

## Hotfixes

A production break is the one exception to "branch off `development`":

```bash
git checkout main && git pull
git checkout -b fix/crash-on-empty-story
# ... fix ...
gh pr create --base main
```

Once it is merged into `main`, **merge `main` back into `development` immediately**, or
the next release silently reverts the fix.

## What a PR needs

The bar for "done" is the same as everywhere else in this repo — see `CLAUDE.md`:

- `flutter analyze` clean. Zero issues, not "only infos".
- `flutter test` passing.
- `dart format lib test` applied.
- Codegen run if you touched anything generated (`dart run build_runner build` — no
  `--delete-conflicting-outputs`, it was removed in build_runner 2.15).

A PR body should say what changed, why, and anything a reviewer would otherwise have to
discover by reading the diff. Open PRs ready for review rather than as drafts unless the
work is genuinely unfinished and you want early eyes on it.

## CI

`.github/workflows/dart.yml` runs on pushes to `main` and `development`, and on pull
requests targeting either. Since almost every PR targets `development`, a workflow that
only watched `main` would leave the branch that receives all the work unchecked.
