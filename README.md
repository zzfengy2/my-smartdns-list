# SmartDNS Optimized China List

本项目通过 GitHub Actions 每日自动转换 [dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list) 为 SmartDNS 专用格式。

## 📂 生成文件
* `accelerated-domains.china.smartdns.conf`: 国内域名加速
* `apple.china.smartdns.conf`: 苹果中国区加速
* `google.china.smartdns.conf`: 谷歌中国区加速

## 🔧 使用方法
1. 将 `.conf` 文件下载并上传至路由器 `/etc/smartdns/domain-set/`。
2. 在 SmartDNS “自定义设置”中添加：
   `conf-file /etc/smartdns/domain-set/accelerated-domains.china.smartdns.conf`

## 📡 配合 AdGuard Home
* **主 DNS**：NAS 上的 AdGuard Home (负责拦截)。
* **上游 DNS**：路由器上的 SmartDNS (负责分流)。
