# My SmartDNS List

这是一个通过 GitHub Actions 自动生成的 SmartDNS 规则仓库。工作流每天北京时间凌晨 4 点同步 [`felixonmars/dnsmasq-china-list`](https://github.com/felixonmars/dnsmasq-china-list)，并转换为 SmartDNS 配置。

## 文件清单

1. `accelerated-domains.china.smartdns.conf`：国内域名使用 `cn` 上游组。
2. `apple.china.smartdns.conf`：Apple 中国服务使用 `cn` 上游组。
3. `google.china.smartdns.conf`：Google 中国服务使用 `cn` 上游组。
4. `bogus-nxdomain.china.smartdns.conf`：运营商 DNS 劫持地址列表。
5. `proxy-domains.smartdns.conf`：指定服务使用 `gw` 上游组。

这些 `.conf` 文件是生成产物，会被 GitHub Actions 自动覆盖。需要调整代理域名时，请修改 `sources/proxy-domains.txt`，不要直接修改 `proxy-domains.smartdns.conf`。

## 前置配置

SmartDNS 中必须预先存在以下两个上游服务器组：

| 组名 | 用途 | 建议设置 |
| :--- | :--- | :--- |
| `cn` | 国内域名解析 | 配置国内 DNS，并保留在默认组中 |
| `gw` | 境外服务解析 | 配置可信的境外 DNS，并排除在默认组外 |

`gw` 只是 SmartDNS 上游服务器组。这里的规则只选择 DNS 上游，不会自动建立代理或改变设备的网络路由。

## 下载或更新

在路由器上执行以下命令，将五个文件下载到 SmartDNS 配置目录：

```sh
install_dir=/etc/smartdns/domain-set
base_url=https://raw.githubusercontent.com/zzfengy2/my-smartdns-list/main

mkdir -p "$install_dir"
for file in \
  accelerated-domains.china.smartdns.conf \
  apple.china.smartdns.conf \
  google.china.smartdns.conf \
  bogus-nxdomain.china.smartdns.conf \
  proxy-domains.smartdns.conf; do
  curl -fsSL "$base_url/$file" -o "$install_dir/$file"
done
```

下载完成后，在 SmartDNS 自定义设置中引用这些文件：

```text
conf-file /etc/smartdns/domain-set/accelerated-domains.china.smartdns.conf
conf-file /etc/smartdns/domain-set/apple.china.smartdns.conf
conf-file /etc/smartdns/domain-set/google.china.smartdns.conf
conf-file /etc/smartdns/domain-set/bogus-nxdomain.china.smartdns.conf
conf-file /etc/smartdns/domain-set/proxy-domains.smartdns.conf
```

最后通过 Web UI 或系统服务重启 SmartDNS，使新规则生效。

## 自动构建

仓库使用自己的转换和校验脚本，不执行上游仓库中的构建代码。发布前会检查五个产物是否存在、行数是否异常、指令格式是否合法以及是否包含重复规则；验证失败时不会提交更新。
