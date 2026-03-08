# My SmartDNS List 🚀

这是一个基于 GitHub Actions 自动构建的 SmartDNS 优化规则仓库。每天北京时间凌晨 4 点自动同步上游 dnsmasq-china-list 并转换格式。

## 📂 文件清单
本项目自动生成以下 5 个核心配置文件：

1.  **`accelerated-domains.china.smartdns.conf`**：国内主流域名加速列表，强制走 `cn` 组。
2.  **`apple.china.smartdns.conf`**：苹果服务加速，解决 App Store 下载慢、系统更新卡顿。
3.  **`google.china.smartdns.conf`**: 谷歌中国服务加速。
4.  **`bogus-nxdomain.china.smartdns.conf`**: 运营商 DNS 劫持防护黑名单。
5.  **`proxy-domains.smartdns.conf`**: **自定义分流黑名单**，强制 Google、YouTube、ChatGPT、Docker 等走 `gw` 组。

---

## 🛠️ 最佳实践配置

为了发挥本列表的最大效能，请按照以下逻辑配置你的 SmartDNS：

### 1. 上游服务器分组 (Upstream Servers)
在 Web 界面中请确保以下分组逻辑：

| 组名 | 推荐服务器 | 关键设置 |
| :--- | :--- | :--- |
| **cn** | 阿里 (223.5.5.5)、腾讯 (119.29.29.29)、百度等 | **不勾选** “排除在默认组外” |
| **gw** | Google (8.8.8.8)、Cloudflare (DoH) 等 | **必须勾选** “排除在默认组外” |

### 2. 引用规则文件
在 SmartDNS 的 **“自定义设置”** 底部加入以下引用：

```bash
conf-file /etc/smartdns/domain-set/accelerated-domains.china.smartdns.conf
conf-file /etc/smartdns/domain-set/apple.china.smartdns.conf
conf-file /etc/smartdns/domain-set/google.china.smartdns.conf
conf-file /etc/smartdns/domain-set/bogus-nxdomain.china.smartdns.conf
conf-file /etc/smartdns/domain-set/proxy-domains.smartdns.conf
