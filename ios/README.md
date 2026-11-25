# 岱宗盒子 iOS

SwiftUI 原生客户端工程，最低支持 iOS 17。当前接入学校 CAS、教务课表/成绩和校园卡余额/流水；图书馆选座、空闲教室、通知与社区暂不实现。数据直接访问西安交通大学服务，不经过第三方后端。

登录在学校官方网页完成，App 不收集密码。教务课表和成绩由原生界面展示；校园卡页面使用学校官方网页。更多真机签名和 GitHub Actions IPA 构建步骤见仓库根目录 README。

推送到 `main` 后，GitHub Actions 自动生成未签名模拟器 `.app`。真机 `.ipa` 需要 Apple Distribution 证书、Ad Hoc profile 以及登记过的 iPhone UDID。
