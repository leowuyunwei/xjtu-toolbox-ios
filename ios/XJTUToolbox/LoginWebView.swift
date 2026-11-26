import SwiftUI
import WebKit

struct CampusLoginSheet: View {
    let initialTarget: LoginTarget
    let onComplete: (LoginTarget, [HTTPCookie], String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var target: LoginTarget
    @State private var isFinishing = false
    @State private var cardPortalReady = false

    init(initialTarget: LoginTarget, onComplete: @escaping (LoginTarget, [HTTPCookie], String?) -> Void) {
        self.initialTarget = initialTarget
        self.onComplete = onComplete
        _target = State(initialValue: initialTarget)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("使用学校统一身份认证")
                        .font(.headline).foregroundStyle(Color.campusInk)
                    Text("请在学校官方登录页完成认证。此 App 不读取或保存你的密码。校园卡内容由学校官方网页提供。")
                        .font(.caption).foregroundStyle(Color.campusMuted)
                        .fixedSize(horizontal: false, vertical: true)
                    Picker("登录目标", selection: $target) {
                        Text("教务系统").tag(LoginTarget.jwxt)
                        Text("校园卡").tag(LoginTarget.campusCard)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(16)

                CampusAuthWebView(target: target) { cookies, ticket in
                    guard !isFinishing else { return }
                    isFinishing = true
                    onComplete(target, cookies, ticket)
                    if target == .campusCard {
                        isFinishing = false
                        cardPortalReady = true
                    }
                }
                .id(target)
                .overlay {
                    if isFinishing {
                        ProgressView("正在同步安全会话…")
                            .padding(18)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    } else if cardPortalReady {
                        VStack(spacing: 7) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.campusGreen)
                            Text("已进入校园卡官方页面").font(.caption.weight(.semibold))
                            Text("余额和流水显示在网页中").font(.caption2).foregroundStyle(Color.campusMuted)
                        }
                        .padding(13).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .allowsHitTesting(false)
                    }
                }
            }
            .background(Color.campusCanvas)
            .navigationTitle(target == .jwxt ? "连接教务系统" : "连接校园卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

private struct CampusAuthWebView: UIViewRepresentable {
    let target: LoginTarget
    let onComplete: ([HTTPCookie], String?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: startURL))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
    }

    private var startURL: URL {
        switch target {
        case .jwxt:
            URL(string: "https://jwxt.xjtu.edu.cn/jwapp/sys/homeapp/index.do")!
        case .campusCard:
            URL(string: "https://ncard.xjtu.edu.cn/berserker-base/redirect?type=login&loginFrom=h5&synAccessSource=h5")!
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: CampusAuthWebView
        private var didComplete = false
        private var didRetryJwxtEntry = false

        init(parent: CampusAuthWebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !didComplete, let url = webView.url else { return }
            let ticket = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "ticket" })?.value
            let isReady: Bool
            switch parent.target {
            case .jwxt:
                isReady = url.host == "jwxt.xjtu.edu.cn"
            case .campusCard:
                isReady = url.host == "ncard.xjtu.edu.cn" && ticket?.isEmpty == false
            }
            guard isReady else { return }

            // CAS may return an auto-submit page between the ticket exchange and the
            // final JWXT page. Revisit the entry once, as the Android client does,
            // so JWXT can consume the CAS ticket and issue its own session cookies.
            if parent.target == .jwxt, !didRetryJwxtEntry {
                didRetryJwxtEntry = true
                webView.load(URLRequest(url: parent.startURL))
                return
            }

            didComplete = true
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                DispatchQueue.main.async { self.parent.onComplete(cookies, ticket) }
            }
        }
    }
}

