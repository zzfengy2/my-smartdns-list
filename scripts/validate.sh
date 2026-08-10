#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <output-directory>" >&2
  exit 2
fi

output_dir=$1
min_accelerated=${MIN_ACCELERATED_LINES:-100000}
min_apple=${MIN_APPLE_LINES:-100}
min_google=${MIN_GOOGLE_LINES:-80}
min_bogus=${MIN_BOGUS_LINES:-150}
min_proxy=${MIN_PROXY_LINES:-30}

fail() {
  echo "validation failed: $*" >&2
  exit 1
}

require_file() {
  file=$1
  [ -s "$file" ] || fail "missing or empty file: $file"
}

require_minimum() {
  file=$1
  pattern=$2
  minimum=$3
  count=$(grep -c "$pattern" "$file" || true)
  [ "$count" -ge "$minimum" ] || \
    fail "$file has $count matching directives; expected at least $minimum"
}

validate_nameserver_file() {
  file=$1
  awk '
    !/^nameserver \/[^\/[:space:]]+\/cn$/ {
      print FILENAME ":" FNR ": invalid nameserver directive: " $0 > "/dev/stderr"
      invalid = 1
    }
    seen[$0]++ {
      print FILENAME ":" FNR ": duplicate directive: " $0 > "/dev/stderr"
      invalid = 1
    }
    END { exit invalid }
  ' "$file" || fail "invalid nameserver list: $file"
}

validate_bogus_file() {
  file=$1
  awk '
    function valid_ipv4(address, octets, count, i) {
      count = split(address, octets, ".")
      if (count != 4) return 0
      for (i = 1; i <= 4; i++) {
        if (octets[i] !~ /^[0-9]+$/ || length(octets[i]) > 3 || octets[i] > 255) {
          return 0
        }
      }
      return 1
    }
    function valid_ipv6(address, copy, colon_count) {
      if (address !~ /^[0-9A-Fa-f:]+$/ || address ~ /:::/) return 0
      if (address ~ /^:[^:]/ || address ~ /[^:]:$/) return 0
      copy = address
      colon_count = gsub(/:/, "", copy)
      if (colon_count < 2 || colon_count > 8) return 0
      copy = address
      sub(/::/, "", copy)
      if (copy ~ /::/) return 0
      return 1
    }
    /^#|^$/ { next }
    $1 != "bogus-nxdomain" || NF != 2 || \
      (!valid_ipv4($2) && !valid_ipv6($2)) {
      print FILENAME ":" FNR ": invalid bogus-nxdomain directive: " $0 > "/dev/stderr"
      invalid = 1
      next
    }
    seen[$0]++ {
      print FILENAME ":" FNR ": duplicate directive: " $0 > "/dev/stderr"
      invalid = 1
    }
    END { exit invalid }
  ' "$file" || fail "invalid bogus-nxdomain list: $file"
}

validate_proxy_file() {
  file=$1
  awk '
    /^#|^$/ { next }
    !/^domain-rules \/[A-Za-z0-9._-]+\/ -n gw$/ {
      print FILENAME ":" FNR ": invalid proxy directive: " $0 > "/dev/stderr"
      invalid = 1
    }
    seen[$0]++ {
      print FILENAME ":" FNR ": duplicate directive: " $0 > "/dev/stderr"
      invalid = 1
    }
    END { exit invalid }
  ' "$file" || fail "invalid proxy list: $file"
}

accelerated="$output_dir/accelerated-domains.china.smartdns.conf"
apple="$output_dir/apple.china.smartdns.conf"
google="$output_dir/google.china.smartdns.conf"
bogus="$output_dir/bogus-nxdomain.china.smartdns.conf"
proxy="$output_dir/proxy-domains.smartdns.conf"

for file in "$accelerated" "$apple" "$google" "$bogus" "$proxy"; do
  require_file "$file"
done

require_minimum "$accelerated" '^nameserver ' "$min_accelerated"
require_minimum "$apple" '^nameserver ' "$min_apple"
require_minimum "$google" '^nameserver ' "$min_google"
require_minimum "$bogus" '^bogus-nxdomain ' "$min_bogus"
require_minimum "$proxy" '^domain-rules ' "$min_proxy"

validate_nameserver_file "$accelerated"
validate_nameserver_file "$apple"
validate_nameserver_file "$google"
validate_bogus_file "$bogus"
validate_proxy_file "$proxy"

echo "validation passed"
