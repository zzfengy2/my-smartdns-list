# SmartDNS Workflow Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve daily SmartDNS list updates while treating the upstream repository as untrusted data, validating every generated artifact, and documenting a usable installation path.

**Architecture:** Repository-owned shell scripts convert four known upstream data files plus a curated local domain source into exactly five public SmartDNS configuration files. A separate validator enforces file presence, minimum sizes, directive syntax, and uniqueness before the workflow stages only the expected outputs and pushes them.

**Tech Stack:** POSIX shell, awk, sed, grep, GitHub Actions, SmartDNS configuration files

## Global Constraints

- Do not execute scripts, Makefiles, or commands from `felixonmars/dnsmasq-china-list`.
- Pin `actions/checkout` to `34e114876b0b11c390a56381ad16ebd13914f8d5` (`v4.3.1`).
- Publish exactly five generated `.smartdns.conf` files.
- Preserve the existing `cn` and `gw` group names.
- Do not push remote changes without an explicit request.

---

### Task 1: Repository-Owned Builder And Validator

**Files:**
- Create: `sources/proxy-domains.txt`
- Create: `scripts/build.sh`
- Create: `scripts/validate.sh`
- Create: `tests/test_build.sh`
- Create: `tests/test_validate.sh`

**Interfaces:**
- Consumes: `scripts/build.sh <upstream-directory> <output-directory>` and `sources/proxy-domains.txt`.
- Produces: the five documented SmartDNS configuration files in `<output-directory>`.
- Validates: `scripts/validate.sh <output-directory>`, with optional `MIN_ACCELERATED_LINES`, `MIN_APPLE_LINES`, `MIN_GOOGLE_LINES`, and `MIN_BOGUS_LINES` environment overrides for fixtures.

- [ ] **Step 1: Write the failing builder test**

Create fixture input files in a temporary directory, invoke `scripts/build.sh`, and compare all five outputs against exact expected content. Include OpenAI auxiliary domains `oaistatic.com`, `oaiusercontent.com`, and `oaistatsig.com`, plus GitHub domains `githubassets.com` and `github.io`, in the expected proxy output.

- [ ] **Step 2: Run the builder test and verify RED**

Run: `bash tests/test_build.sh`

Expected: FAIL because `scripts/build.sh` and `sources/proxy-domains.txt` do not exist.

- [ ] **Step 3: Implement the minimal builder**

Implement `scripts/build.sh` with `set -eu`, argument validation, explicit input filenames, and repository-owned POSIX `sed` transformations:

```sh
sed -n 's|^server=/\([^/]*\)/114\.114\.114\.114$|nameserver /\1/cn|p'
```

Convert `bogus-nxdomain=` to `bogus-nxdomain ` and convert each non-comment local proxy domain to `domain-rules /DOMAIN/ -n gw`. Write through temporary files and move them into place only after all conversions succeed.

- [ ] **Step 4: Run the builder test and verify GREEN**

Run: `bash tests/test_build.sh`

Expected: PASS with five exact outputs.

- [ ] **Step 5: Write failing validator tests**

Test a valid small fixture, then independently assert failure for a missing output, a malformed directive, a duplicate domain rule, and an output below its configured minimum.

- [ ] **Step 6: Run validator tests and verify RED**

Run: `bash tests/test_validate.sh`

Expected: FAIL because `scripts/validate.sh` does not exist.

- [ ] **Step 7: Implement the minimal validator**

Validate exact filenames, non-empty files, configurable minimum directive counts, accepted line shapes, and duplicate directive keys. Emit the failing filename and reason to stderr and exit non-zero on the first violation.

- [ ] **Step 8: Run both test files and commit**

Run: `bash tests/test_build.sh && bash tests/test_validate.sh`

Expected: PASS.

Commit:

```sh
git add sources/proxy-domains.txt scripts/build.sh scripts/validate.sh tests/test_build.sh tests/test_validate.sh
git commit -m "feat: add safe SmartDNS list builder"
```

### Task 2: Harden The GitHub Actions Workflow

**Files:**
- Modify: `.github/workflows/auto-convert.yml`
- Create: `tests/test_workflow.sh`

**Interfaces:**
- Consumes: `scripts/build.sh`, `scripts/validate.sh`, and the upstream checkout directory `_upstream`.
- Produces: a validated staged diff containing only the five public configuration files.

- [ ] **Step 1: Write the failing workflow policy test**

Assert that the workflow uses only the pinned checkout SHA, sets `persist-credentials: false` for the upstream checkout, calls both repository scripts, contains no `make`, stages the five explicit output paths, uses `git diff --cached --quiet`, and defines a concurrency group.

- [ ] **Step 2: Run the workflow test and verify RED**

Run: `bash tests/test_workflow.sh`

Expected: FAIL on the existing `actions/checkout@v4`, `make smartdns`, `git add .`, and masked commit failure.

- [ ] **Step 3: Implement the hardened workflow**

Add workflow concurrency with `cancel-in-progress: false`. Pin both checkout steps. Keep credentials for the main checkout, disable them for `_upstream`, run the builder and validator, remove `_upstream`, stage only the five outputs, exit successfully only when `git diff --cached --quiet` reports no change, and otherwise commit and push normally.

- [ ] **Step 4: Run workflow and repository tests**

Run: `bash tests/test_workflow.sh && bash tests/test_build.sh && bash tests/test_validate.sh`

Expected: PASS.

- [ ] **Step 5: Commit**

```sh
git add .github/workflows/auto-convert.yml tests/test_workflow.sh
git commit -m "ci: harden SmartDNS list updates"
```

### Task 3: Regenerate Outputs And Complete Documentation

**Files:**
- Modify: `README.md`
- Modify: `accelerated-domains.china.smartdns.conf`
- Modify: `apple.china.smartdns.conf`
- Modify: `google.china.smartdns.conf`
- Modify: `bogus-nxdomain.china.smartdns.conf`
- Modify: `proxy-domains.smartdns.conf`
- Create: `tests/test_readme.sh`

**Interfaces:**
- Consumes: a fresh checkout of `felixonmars/dnsmasq-china-list` and the builder from Task 1.
- Produces: documented, validated public artifacts ready for the scheduled workflow.

- [ ] **Step 1: Write the failing README test**

Assert that fenced code blocks are balanced and that the README contains a concrete `curl` installation/update command, explains required `cn` and `gw` groups, and warns that generated `.conf` files are overwritten automatically.

- [ ] **Step 2: Run the README test and verify RED**

Run: `bash tests/test_readme.sh`

Expected: FAIL because the current fence is unclosed and installation/update instructions are absent.

- [ ] **Step 3: Update the README**

Close the existing code fence, add a shell loop that downloads the five raw files into `/etc/smartdns/domain-set`, explain group prerequisites, and state that local edits to generated outputs are overwritten.

- [ ] **Step 4: Run README test and verify GREEN**

Run: `bash tests/test_readme.sh`

Expected: PASS.

- [ ] **Step 5: Regenerate and validate current outputs**

Run:

```sh
./scripts/build.sh _upstream .
./scripts/validate.sh .
```

Expected: validation succeeds and `proxy-domains.smartdns.conf` includes the newly curated auxiliary domains.

- [ ] **Step 6: Run the full verification suite**

Run:

```sh
bash tests/test_build.sh
bash tests/test_validate.sh
bash tests/test_workflow.sh
bash tests/test_readme.sh
git diff --check
```

Expected: every command exits zero with no warnings or whitespace errors.

- [ ] **Step 7: Commit**

```sh
git add README.md accelerated-domains.china.smartdns.conf apple.china.smartdns.conf google.china.smartdns.conf bogus-nxdomain.china.smartdns.conf proxy-domains.smartdns.conf tests/test_readme.sh
git commit -m "docs: complete SmartDNS installation guidance"
```

### Task 4: Final Audit

**Files:**
- Verify all changed files.

**Interfaces:**
- Consumes: completed Tasks 1-3.
- Produces: evidence that the repository matches the approved design.

- [ ] **Step 1: Confirm changed scope**

Run: `git status --short && git diff HEAD~3 --stat`

Expected: only planned source, script, test, workflow, documentation, and generated output files are present.

- [ ] **Step 2: Re-run fresh verification**

Run: `bash tests/test_build.sh && bash tests/test_validate.sh && bash tests/test_workflow.sh && bash tests/test_readme.sh && git diff --check`

Expected: all checks pass.

- [ ] **Step 3: Inspect recent commits**

Run: `git log -4 --oneline`

Expected: design, builder, workflow, and documentation commits are visible, with no remote push performed.
