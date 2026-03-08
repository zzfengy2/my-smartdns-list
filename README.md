SmartDNS Optimized China List (Auto-Convert)
本仓库通过 GitHub Actions 自动同步 dnsmasq-china-list 源码，并将其转换为 SmartDNS 原生支持的 domain-rules 格式。

🚀 项目特色
全自动同步：每日凌晨自动拉取上游更新并完成转换。

精准分流：所有生成规则均带 -n cn 标签，完美适配国内组加速。

格式纯净：直接使用 SmartDNS 语法，无需 Dnsmasq 中转，解析更高效。

📂 生成文件说明
转换后的文件存放于仓库根目录，主要包括：

accelerated-domains.china.smartdns.conf: 国内主流域名加速列表。

apple.china.smartdns.conf: 苹果中国区服务加速。

google.china.smartdns.conf: 谷歌中国区服务（如翻译、地图、DL 等）加速。

🛠️ 部署与使用
1. 上传文件
将生成的 .conf 文件上传至路由器的指定目录，建议路径为：
/etc/smartdns/domain-set/

2. SmartDNS 配置
在 SmartDNS 的“自定义设置”框中引用这些文件：

Bash

# 引用自动转换的国内加速列表
conf-file /etc/smartdns/domain-set/accelerated-domains.china.smartdns.conf
conf-file /etc/smartdns/domain-set/apple.china.smartdns.conf
conf-file /etc/smartdns/domain-set/google.china.smartdns.conf
3. 配合 AdGuard Home
确保您的 AdGuard Home (NAS) 上游 DNS 指向路由器的 SmartDNS 端口（如 192.168.x.x:6053）。

AdGuard Home：负责广告拦截（如 AWAvenue、anti-AD 规则）。

SmartDNS：负责通过本项目提供的列表实现国内 CDN 加速及国内外分流。

🔄 自动更新脚本
在 OpenWrt 的“计划任务” (Crontab) 中添加以下脚本，实现每周自动更新规则并重启 SmartDNS：

Bash

# 每周一凌晨 5 点自动更新规则
0 5 * * 1 wget -O /etc/smartdns/domain-set/china.conf https://raw.githubusercontent.com/您的用户名/您的仓库名/main/accelerated-domains.china.smartdns.conf && /etc/init.d/smartdns restart
⚖️ 声明
本项目规则源码归 dnsmasq-china-list 及其贡献者所有。本仓库仅负责格式转换。

💡 小贴士
如果您在 SmartDNS 设置中启用了“高级设置”里的 “TCP服务器” 和 “乐观缓存”，配合本列表效果最佳。
