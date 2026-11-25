# 岱宗盒子 iOS

此项目于 2026-11-25 改编自 [西交工具箱 Android](https://github.com/yeliqin666/xjtu-toolbox-android)，是最低支持 iOS 17 的原生 SwiftUI 客户端。按 GPL-3.0 发布；社区功能暂不实现。

## 已接入

- 学校统一身份认证：在系统内的学校官方网页完成登录，App 不读取或保存密码。
- 教务当前学期、课表和有效成绩：数据直接从 `jwxt.xjtu.edu.cn` 读取。
- 校园卡：在内置网页打开 `ncard.xjtu.edu.cn` 官方服务，登录和余额/流水展示由校方网页处理。
- 图书馆座位、空闲教室、校园通知尚未接入可靠的安全数据源，界面不会显示模拟数据。

登录需要网络可访问学校服务。接口为学校现有服务，返回字段或认证策略变更时可能需要更新客户端。

## 本地打开

使用 Xcode 打开 `ios/XJTUToolbox.xcodeproj`，选择 `XJTUToolbox` scheme。若要安装到实体 iPhone，需要在自己的 Apple Developer Team 下配置签名和设备 provisioning profile。

## GitHub Actions 构建

推送到 `main` 后自动构建未签名的 iOS Simulator `.app`，Actions artifact 保留 7 天。该文件用于模拟器，不可直接安装到 iPhone。

要生成能安装到已注册 iPhone 的 Ad Hoc `.ipa`：

1. 在 Apple Developer 账号中登记 iPhone 的 UDID，并生成包含此设备的 Ad Hoc provisioning profile。用 Apple Distribution 证书及私钥导出 `.p12`。
2. 在仓库 Settings → Secrets and variables → Actions 中添加以下 Repository secrets：
   - `IOS_CERTIFICATE_BASE64`：`.p12` 文件的 Base64 文本
   - `IOS_CERTIFICATE_PASSWORD`：导出 `.p12` 时设置的密码
   - `IOS_PROVISIONING_PROFILE_BASE64`：Ad Hoc `.mobileprovision` 文件的 Base64 文本
   - `IOS_TEAM_ID`：Apple Developer Team ID
3. 在 Actions 手动运行 `iOS Simulator Build`，勾选 `build_ipa`。构建成功后下载 `XJTUToolbox-adhoc-*` artifact，解压得到 `.ipa`。

不要把证书、私钥、密码或 provisioning profile 提交到 Git 仓库，也不要通过聊天发送私钥。Ad Hoc 包只会安装到 profile 中登记的设备。

## 许可

此客户端参考 GPL-3.0 授权的 Android 项目。本仓库按 GPL-3.0 发布并保留上游声明，详见 [`LICENSE`](LICENSE)。
