#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
readme="$repo_root/README.md"

fail() {
  echo "test_readme: $*" >&2
  exit 1
}

fence_count=$(grep -c '^```' "$readme" || true)
[ $((fence_count % 2)) -eq 0 ] || fail "Markdown code fences are unbalanced"

grep -q 'curl -fsSL' "$readme" || fail "download command is missing"
grep -q 'raw.githubusercontent.com/zzfengy2/my-smartdns-list' "$readme" || \
  fail "raw download URL is missing"
grep -q '`cn`' "$readme" || fail "cn group prerequisite is missing"
grep -q '`gw`' "$readme" || fail "gw group prerequisite is missing"
grep -q '自动覆盖' "$readme" || fail "generated-file warning is missing"

echo "test_readme: PASS"
