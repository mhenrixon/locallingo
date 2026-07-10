---
model: sonnet
description: "Use when CI checks are failing on a PR — fetches failure logs, diagnoses root causes, implements fixes, and pushes until CI is green."
argument-hint: "PR number (e.g., 41 or #41)"
allowed-tools: Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh pr checks:*), Bash(gh pr diff:*), Bash(gh api:*), Bash(gh run view:*), Bash(git log:*), Bash(git diff:*), Bash(git push:*), Bash(git commit:*), Bash(git add:*), Bash(bundle exec:*), Read, Write, Edit, Glob, Grep, Agent
---

# Fix GitHub CI Failures: $ARGUMENTS

You are diagnosing and fixing CI failures on a GitHub pull request. Work systematically: identify failures, read logs, diagnose root causes, fix locally, verify, push.

## Phase 0: Determine the PR Number

The user may provide a PR number as `$ARGUMENTS`. Parse it flexibly:

- `PR41`, `PR 41`, `pr41` -> PR 41
- `41` -> PR 41
- `#41` -> PR 41
- Empty/blank -> auto-detect from current branch

**If no PR number is provided**, detect it automatically:

```bash
gh pr list --author=@me --head="$(git branch --show-current)" --state=open --json number,title
```

If exactly one open PR exists for the current branch, use it. If none or multiple, ask the user.

Once you have the PR number, confirm it:

```bash
gh pr view <PR_NUMBER> --json title,state,url,mergeable
```

**Pre-flight: merge conflicts (detection only).** If `mergeable` is `CONFLICTING`, STOP — do not diagnose CI on a conflicted branch (the merge itself may fix or cause the failures). Report the conflict and hand off to `/github-review-pr`, whose Phase A0 owns the resolution runbook — this command's toolset deliberately does not include the merge machinery. If `mergeable` is `UNKNOWN`, note it and proceed: the orchestrator resolves the ambiguity; a standalone run shouldn't block on GitHub's recompute.

---

## Phase 1: Identify Failing Checks

```bash
gh pr checks <PR_NUMBER>
```

CI is a single job type — `bundle exec rake` (spec + rubocop, per the Rakefile) — run on a Ruby matrix:

| Check Type | Examples | How to Get Logs |
|------------|----------|----------------|
| Suite + lint (rake = spec + rubocop) | `rake (Ruby 3.2)`, `rake (Ruby 3.3)`, `rake (Ruby 3.4)` | `gh run view <RUN_ID> --job=<JOB_ID> --log-failed` |

Extract the run ID and job IDs from the check URLs. The URL format is:
`https://github.com/mhenrixon/locallingo/actions/runs/<RUN_ID>/job/<JOB_ID>`

If all checks pass or are pending, report that and stop.

---

## Phase 2: Fetch Failure Logs

For each failing check, get the logs:

```bash
# Get the failed job logs (condensed output)
gh run view <RUN_ID> --job=<JOB_ID> --log-failed
```

If `--log-failed` output is too large or unclear, try:

```bash
# Full log for a specific job
gh run view <RUN_ID> --job=<JOB_ID> --log 2>&1 | tail -100
```

---

## Phase 3: Diagnose Each Failure

For each failure, determine the root cause. A `rake (Ruby X.Y)` job fails on the FIRST of specs or rubocop that breaks — read the log to see which half failed.

### Lint Failures

Look for:
- RuboCop offenses: file path, line number, cop name, message

**Key**: RuboCop failures can often be auto-fixed with `bundle exec rubocop -A <file>`. The lint scope is `exe lib spec Rakefile Gemfile locallingo.gemspec` (Rakefile patterns); the `docs/` app has its own separate `.rubocop.yml` and is NOT covered by this job.

### Spec Failures

Look for:
- Test name and file path
- Error class and message
- Relevant backtrace lines (ignore framework noise)
- Whether it's a test environment issue vs actual code bug

**Key patterns**:
- `NameError: uninitialized constant` -> missing require or renamed class
- `NoMethodError: undefined method` -> API change, missing method
- `Errno::ENOENT` in specs -> fixture/tmpdir path issue (the suite writes locale fixtures under `Dir.mktmpdir`)
- `expected: X, got: Y` -> logic bug or test needs updating

### Build/Dependency Failures

Look for:
- Bundle install failures in the `Set up Ruby` step (bundler-cache): dependency conflicts, a gem that dropped support for an older matrix Ruby

---

## Phase 4: Fix Locally

For each diagnosed failure:

1. **Read the relevant file** to understand context before fixing
2. **Make the fix** -- edit the file
3. **Verify locally** before committing:

```bash
# For rubocop failures
bundle exec rubocop <changed_files>

# For spec failures
bundle exec rspec <failing_spec_files>

# For full validation (exactly what CI runs)
bundle exec rake
```

### Fix Priority Order

1. **Lint/style fixes** first (fast, deterministic)
2. **Spec failures** second (may require understanding the code change)
3. **Build/dependency issues** third (usually Gemfile or gemspec)

---

## Phase 5: Commit and Push

```bash
git add <specific_files>
git commit -m "$(cat <<'EOF'
fix(ci): <brief description of what was fixed>

- Fix 1 description
- Fix 2 description
EOF
)"
git push
```

---

## Phase 6: Verify

After pushing, check if CI has been re-triggered:

```bash
gh pr checks <PR_NUMBER>
```

If there are still pending checks, report which checks are running and what was fixed. Do NOT poll in a loop -- report the status and let the user know.

If you can identify that certain failures will persist for environmental reasons (e.g., a runner outage or a RubyGems network hiccup during bundle install), flag that explicitly.

---

## Important Notes

- **Read before fixing** -- always read the actual failing code before attempting a fix
- **Fix the root cause** -- don't add `# rubocop:disable` to bypass lint; fix the actual issue (a targeted `# rubocop:disable` is acceptable only when RuboCop is demonstrably wrong)
- **Don't fix unrelated failures** -- if a spec was already failing on main, note it but don't fix it in this PR
- **The Ruby matrix is 3.2 / 3.3 / 3.4** -- a failure on only ONE Ruby version is a version-specific bug, not flakiness. The gem's floor is Ruby 3.2 (`required_ruby_version`, `TargetRubyVersion: 3.2`), so a fix must not use 3.3+/3.4-only syntax; check the failing version's log for `SyntaxError` first.
- **Flaky tests** -- if a test passes locally but fails in CI, note it as potentially flaky rather than adding workarounds
- **Don't retry CI blindly** -- diagnose first, fix, then push. Each push triggers a full CI run across all three Rubies.

Now begin by determining the PR number and fetching the failing checks.
