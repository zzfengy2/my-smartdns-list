#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
workflow="$repo_root/.github/workflows/auto-convert.yml"
checkout_sha=34e114876b0b11c390a56381ad16ebd13914f8d5

fail() {
  echo "test_workflow: $*" >&2
  exit 1
}

[ "$(grep -c "uses: actions/checkout@$checkout_sha" "$workflow" || true)" -eq 2 ] || \
  fail "both checkout steps must use the pinned v4.3.1 SHA"

if grep -q 'uses: actions/checkout@v' "$workflow"; then
  fail "mutable checkout tags are not allowed"
fi

grep -q 'persist-credentials: false' "$workflow" || \
  fail "upstream checkout must disable persisted credentials"
grep -q 'scripts/build.sh' "$workflow" || fail "builder is not invoked"
grep -q 'scripts/validate.sh' "$workflow" || fail "validator is not invoked"
grep -q '^concurrency:' "$workflow" || fail "workflow concurrency is missing"
grep -q 'git diff --cached --quiet' "$workflow" || \
  fail "no-change handling must inspect the staged diff"

if grep -qE '(^|[[:space:]])make([[:space:]]|$)' "$workflow"; then
  fail "upstream make commands must not be executed"
fi

if grep -q 'git add \.' "$workflow"; then
  fail "git add must stage only known outputs"
fi

if grep -q '|| exit 0' "$workflow"; then
  fail "commit failures must not be masked"
fi

for output in \
  accelerated-domains.china.smartdns.conf \
  apple.china.smartdns.conf \
  google.china.smartdns.conf \
  bogus-nxdomain.china.smartdns.conf \
  proxy-domains.smartdns.conf; do
  grep -q "$output" "$workflow" || fail "workflow does not stage $output"
done

echo "test_workflow: PASS"
