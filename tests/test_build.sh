#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

source_dir="$tmp_dir/source"
output_dir="$tmp_dir/output"
mkdir -p "$source_dir" "$output_dir"

cat > "$source_dir/accelerated-domains.china.conf" <<'EOF'
# comment
server=/alpha.example/114.114.114.114
server=/beta.example/114.114.114.114
EOF

cat > "$source_dir/apple.china.conf" <<'EOF'
server=/apple.example/114.114.114.114
EOF

cat > "$source_dir/google.china.conf" <<'EOF'
server=/google.example/114.114.114.114
EOF

cat > "$source_dir/bogus-nxdomain.china.conf" <<'EOF'
## Provider
bogus-nxdomain=192.0.2.1
EOF

cat > "$tmp_dir/proxy-domains.txt" <<'EOF'
# Proxy
openai.com
oaistatic.com
oaiusercontent.com
oaistatsig.com
githubassets.com
github.io
EOF

PROXY_SOURCE="$tmp_dir/proxy-domains.txt" \
  "$repo_root/scripts/build.sh" "$source_dir" "$output_dir"

cat > "$tmp_dir/expected-accelerated" <<'EOF'
nameserver /alpha.example/cn
nameserver /beta.example/cn
EOF

cat > "$tmp_dir/expected-apple" <<'EOF'
nameserver /apple.example/cn
EOF

cat > "$tmp_dir/expected-google" <<'EOF'
nameserver /google.example/cn
EOF

cat > "$tmp_dir/expected-bogus" <<'EOF'
## Provider
bogus-nxdomain 192.0.2.1
EOF

cat > "$tmp_dir/expected-proxy" <<'EOF'
# Proxy
domain-rules /openai.com/ -n gw
domain-rules /oaistatic.com/ -n gw
domain-rules /oaiusercontent.com/ -n gw
domain-rules /oaistatsig.com/ -n gw
domain-rules /githubassets.com/ -n gw
domain-rules /github.io/ -n gw
EOF

diff -u "$tmp_dir/expected-accelerated" "$output_dir/accelerated-domains.china.smartdns.conf"
diff -u "$tmp_dir/expected-apple" "$output_dir/apple.china.smartdns.conf"
diff -u "$tmp_dir/expected-google" "$output_dir/google.china.smartdns.conf"
diff -u "$tmp_dir/expected-bogus" "$output_dir/bogus-nxdomain.china.smartdns.conf"
diff -u "$tmp_dir/expected-proxy" "$output_dir/proxy-domains.smartdns.conf"

echo "test_build: PASS"
