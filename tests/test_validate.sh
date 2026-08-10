#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

create_valid_fixture() {
  target=$1
  rm -rf "$target"
  mkdir -p "$target"
  printf '%s\n' 'nameserver /alpha.example/cn' > "$target/accelerated-domains.china.smartdns.conf"
  printf '%s\n' 'nameserver /apple.example/cn' > "$target/apple.china.smartdns.conf"
  printf '%s\n' 'nameserver /google.example/cn' > "$target/google.china.smartdns.conf"
  printf '%s\n' 'bogus-nxdomain 192.0.2.1' > "$target/bogus-nxdomain.china.smartdns.conf"
  printf '%s\n' 'domain-rules /openai.com/ -n gw' > "$target/proxy-domains.smartdns.conf"
}

validate_fixture() {
  MIN_ACCELERATED_LINES=${MIN_ACCELERATED_LINES:-1} \
  MIN_APPLE_LINES=${MIN_APPLE_LINES:-1} \
  MIN_GOOGLE_LINES=${MIN_GOOGLE_LINES:-1} \
  MIN_BOGUS_LINES=${MIN_BOGUS_LINES:-1} \
  MIN_PROXY_LINES=${MIN_PROXY_LINES:-1} \
    "$repo_root/scripts/validate.sh" "$1"
}

expect_failure() {
  name=$1
  shift
  if "$@" >/dev/null 2>&1; then
    echo "$name unexpectedly passed" >&2
    exit 1
  fi
}

fixture="$tmp_dir/fixture"
create_valid_fixture "$fixture"
validate_fixture "$fixture"

rm "$fixture/apple.china.smartdns.conf"
expect_failure "missing output" validate_fixture "$fixture"

create_valid_fixture "$fixture"
printf '%s\n' 'server=/wrong.example/1.1.1.1' >> "$fixture/google.china.smartdns.conf"
expect_failure "malformed directive" validate_fixture "$fixture"

create_valid_fixture "$fixture"
printf '%s\n' 'domain-rules /openai.com/ -n gw' >> "$fixture/proxy-domains.smartdns.conf"
expect_failure "duplicate directive" validate_fixture "$fixture"

create_valid_fixture "$fixture"
MIN_ACCELERATED_LINES=2 expect_failure "minimum line count" validate_fixture "$fixture"

echo "test_validate: PASS"
