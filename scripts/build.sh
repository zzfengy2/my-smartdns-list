#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <upstream-directory> <output-directory>" >&2
  exit 2
fi

upstream_dir=$1
output_dir=$2
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
proxy_source=${PROXY_SOURCE:-"$repo_root/sources/proxy-domains.txt"}

required_inputs="
accelerated-domains.china.conf
apple.china.conf
google.china.conf
bogus-nxdomain.china.conf
"

for name in $required_inputs; do
  if [ ! -f "$upstream_dir/$name" ]; then
    echo "missing upstream input: $upstream_dir/$name" >&2
    exit 1
  fi
done

if [ ! -f "$proxy_source" ]; then
  echo "missing proxy domain source: $proxy_source" >&2
  exit 1
fi

mkdir -p "$output_dir"
tmp_dir=$(mktemp -d "$output_dir/.smartdns-build.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

convert_domains() {
  input=$1
  output=$2
  sed -n 's|^server=/\([^/]*\)/114\.114\.114\.114$|nameserver /\1/cn|p' \
    "$input" > "$output"
}

convert_domains \
  "$upstream_dir/accelerated-domains.china.conf" \
  "$tmp_dir/accelerated-domains.china.smartdns.conf"
convert_domains \
  "$upstream_dir/apple.china.conf" \
  "$tmp_dir/apple.china.smartdns.conf"
convert_domains \
  "$upstream_dir/google.china.conf" \
  "$tmp_dir/google.china.smartdns.conf"

sed 's/^bogus-nxdomain=/bogus-nxdomain /' \
  "$upstream_dir/bogus-nxdomain.china.conf" \
  > "$tmp_dir/bogus-nxdomain.china.smartdns.conf"

awk '
  { sub(/\r$/, "") }
  /^$/ { print; next }
  /^#/ { print; next }
  /^[A-Za-z0-9._-]+$/ {
    print "domain-rules /" $0 "/ -n gw"
    next
  }
  {
    print "invalid proxy domain: " $0 > "/dev/stderr"
    invalid = 1
  }
  END { exit invalid }
' "$proxy_source" > "$tmp_dir/proxy-domains.smartdns.conf"

for name in \
  accelerated-domains.china.smartdns.conf \
  apple.china.smartdns.conf \
  google.china.smartdns.conf \
  bogus-nxdomain.china.smartdns.conf \
  proxy-domains.smartdns.conf; do
  mv "$tmp_dir/$name" "$output_dir/$name"
done
