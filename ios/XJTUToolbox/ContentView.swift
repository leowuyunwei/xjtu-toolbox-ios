import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var store: CampusStore
    @State private var activeLogin: LoginTarget?

    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("首页", systemImage: "square.grid.2x2.fill") }
            NavigationStack { ScheduleView() }
                .tabItem { Label("课表", systemImage: "calendar") }
            NavigationStack { ToolsView() }
                .tabItem { Label("工具", systemImage: "square.grid.3x3.fill") }
            NavigationStack { ProfileView() }
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
        }
        .background(Color.campusCanvas)
        .sheet(item: $activeLogin) { target in
            CampusLoginSheet(initialTarget: target) { completedTarget, cookies, _ in
                if completedTarget == .jwxt {
                    Task {
                        await store.completeLogin(cookies: cookies)
                        activeLogin = nil
                    }
                } else {
                    Task { await store.completeCardPortal(cookies: cookies) }
                }
            }
            .environmentObject(store)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: store.loginRequest) { _, target in
            guard let target else { return }
            activeLogin = target
            store.loginRequest = nil
        }
        .tint(.campusBlue)
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: CampusStore
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private let weekdayNames = ["一", "二", "三", "四", "五", "六", "日"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(Date.now.formatted(.dateTime.month(.wide).day().weekday(.wide)))
                            .font(.subheadline).foregroundStyle(Color.campusMuted)
                        Text("交大校园助手")
                            .font(.system(size: 27, weight: .bold, design: .rounded)).foregroundStyle(Color.campusInk)
                    }
                    Spacer()
                    Button { Task { await store.refresh() } } label: {
                        Image(systemName: store.isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                            .font(.system(size: 17, weight: .medium)).foregroundStyle(Color.campusInk)
                            .padding(12).background(.white, in: Circle())
                    }
                    .disabled(store.isLoading)
                }

                if !store.isAuthenticated {
                    LoginPrompt(title: "连接校园账号", detail: "登录后同步你的教务课表和成绩。", target: .jwxt)
                } else {
                    VStack(alignment: .leading, spacing: 13) {
                        HStack {
                            Label("今日课表", systemImage: "sun.max.fill")
                                .font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.88))
                            Spacer()
                            Text("星期\(weekdayNames[store.todayWeekday - 1])")
                                .font(.caption.weight(.medium)).padding(.horizontal, 10).padding(.vertical, 6)
                                .background(.white.opacity(0.17), in: Capsule())
                        }
                        if let first = store.courses(on: store.todayWeekday).first {
                            Text("今天共 \(store.courses(on: store.todayWeekday).count) 门课程")
                                .font(.title2.weight(.bold)).foregroundStyle(.white)
                            HStack(spacing: 10) {
                                Image(systemName: "clock.fill")
                                Text("第 \(first.start)-\(first.end) 节 · \(first.name)")
                                Spacer(minLength: 0)
                            }
                            .font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.94))
                            .padding(13).background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 15))
                            if !first.room.isEmpty {
                                Text(first.room).font(.caption).foregroundStyle(.white.opacity(0.8))
                            }
                        } else {
                            Text("今天没有排课")
                                .font(.title2.weight(.bold)).foregroundStyle(.white)
                            Text("课表来自教务系统 · 学期 \(store.termCode ?? "—")")
                                .font(.caption).foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(20)
                    .background(LinearGradient(colors: [.campusBlue, Color(red: 0.34, green: 0.50, blue: 0.98)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 26))
                }

                if let message = store.statusMessage {
                    InlineMessage(text: message, icon: "exclamationmark.triangle.fill")
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    NavigationLink(destination: CampusCardView()) {
                        SummaryTile(title: "校园卡", value: "官方网页", caption: "余额与流水", icon: "creditcard.fill", color: .campusOrange)
                    }
                    NavigationLink(destination: GradeView()) {
                        SummaryTile(title: "加权平均绩点", value: store.grades.isEmpty ? "—" : String(format: "%.2f", store.gpa), caption: store.grades.isEmpty ? "登录教务系统查看" : "\(store.grades.count) 条成绩记录", icon: "chart.bar.fill", color: .campusPurple)
                    }
                }
                .buttonStyle(.plain)

                HStack {
                    SectionTitle(title: "校园服务", subtitle: "已连接的真实数据")
                    Spacer()
                    if store.isLoading { ProgressView().controlSize(.small) }
                }
                LazyVGrid(columns: columns, spacing: 12) {
                    HomeServiceLink(title: "我的课表", subtitle: "教务系统实时查询", icon: "calendar", color: .campusBlue, destination: ScheduleView())
                    HomeServiceLink(title: "成绩与 GPA", subtitle: "教务系统成绩单", icon: "graduationcap.fill", color: .campusPurple, destination: GradeView())
                    HomeServiceLink(title: "校园卡", subtitle: "余额与近期流水", icon: "creditcard.fill", color: .campusOrange, destination: CampusCardView())
                    HomeServiceLink(title: "功能状态", subtitle: "查看尚未接入的服务", icon: "info.circle.fill", color: .campusMuted, destination: PendingFeaturesView())
                }

                if let updated = store.lastUpdated {
                    Text("数据更新时间：\(updated.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2).foregroundStyle(Color.campusMuted)
                }
            }
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 30)
        }
        .refreshable { await store.refresh() }
        .background(Color.campusCanvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct ScheduleView: View {
    @EnvironmentObject private var store: CampusStore
    @State private var weekday = Calendar.current.component(.weekday, from: .now).mapToMondayFirst
    private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("学期代码：\(store.termCode ?? "—")").font(.subheadline).foregroundStyle(Color.campusMuted)
                    Text("我的课表").font(.largeTitle.bold()).foregroundStyle(Color.campusInk)
                }
                HStack(spacing: 0) {
                    ForEach(1...7, id: \.self) { day in
                        Button { weekday = day } label: {
                            VStack(spacing: 8) {
                                Text(weekdays[day - 1]).font(.subheadline.weight(.semibold))
                                Circle().fill(weekday == day ? Color.campusBlue : .clear).frame(width: 5, height: 5)
                            }
                            .foregroundStyle(weekday == day ? Color.campusBlue : Color.campusMuted)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(weekday == day ? Color.campusBlue.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    Text("星期\(weekdays[weekday - 1])").font(.title3.bold())
                    Spacer()
                    Button { Task { await store.refresh() } } label: { Image(systemName: "arrow.clockwise") }
                        .disabled(store.isLoading)
                }
                if !store.isAuthenticated {
                    LoginPrompt(title: "先连接教务账号", detail: "课表将从西安交通大学教务系统读取。", target: .jwxt)
                } else if store.isLoading && store.courses.isEmpty {
                    ProgressView("正在读取教务课表…").frame(maxWidth: .infinity).padding(24)
                } else if store.courses(on: weekday).isEmpty {
                    EmptyState(icon: "calendar", title: "当天没有课表记录", detail: "如果教务系统暂时没有返回数据，请稍后刷新。")
                } else {
                    ForEach(store.courses(on: weekday)) { course in CourseRow(course: course) }
                }
                if let message = store.statusMessage { InlineMessage(text: message, icon: "exclamationmark.triangle.fill") }
            }
            .padding(20)
        }
        .refreshable { await store.refresh() }
        .background(Color.campusCanvas.ignoresSafeArea())
        .navigationTitle("课表")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ToolsView: View {
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("学习与生活").font(.subheadline).foregroundStyle(Color.campusMuted)
                    Text("校园工具箱").font(.largeTitle.bold()).foregroundStyle(Color.campusInk)
                }
                LazyVGrid(columns: columns, spacing: 13) {
                    HomeServiceLink(title: "成绩与 GPA", subtitle: "教务成绩单", icon: "graduationcap.fill", color: .campusPurple, destination: GradeView())
                    HomeServiceLink(title: "校园卡", subtitle: "余额与消费流水", icon: "creditcard.fill", color: .campusOrange, destination: CampusCardView())
                    HomeServiceLink(title: "我的课表", subtitle: "当前学期", icon: "calendar", color: .campusBlue, destination: ScheduleView())
                    HomeServiceLink(title: "其他功能", subtitle: "查看接入状态", icon: "ellipsis.circle.fill", color: .campusMuted, destination: PendingFeaturesView())
                }
            }.padding(20)
        }
        .background(Color.campusCanvas.ignoresSafeArea())
        .navigationTitle("工具").navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileView: View {
    @EnvironmentObject private var store: CampusStore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 66)).symbolRenderingMode(.palette).foregroundStyle(.white, Color.campusBlue)
                    Text(store.isAuthenticated ? "教务账号已连接" : "尚未连接校园账号")
                        .font(.title2.bold()).foregroundStyle(Color.campusInk)
                    Text(store.isAuthenticated ? "会话由学校统一认证管理" : "使用学校官方登录页安全连接")
                        .font(.subheadline).foregroundStyle(Color.campusMuted)
                    Button { store.loginRequest = .jwxt } label: {
                        Label(store.isAuthenticated ? "重新登录教务" : "连接教务账号", systemImage: "person.badge.key.fill")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                            .padding(.horizontal, 18).padding(.vertical, 12).background(Color.campusBlue, in: Capsule())
                    }
                    Button { store.loginRequest = .campusCard } label: {
                        Label(store.isCardPortalConnected ? "重新打开校园卡" : "打开校园卡", systemImage: "creditcard")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Color.campusBlue)
                            .padding(.horizontal, 18).padding(.vertical, 12).background(Color.campusBlue.opacity(0.08), in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity).padding(.vertical, 28).campusCard()

                VStack(spacing: 0) {
                    ProfileRow(icon: "lock.shield.fill", title: "登录方式", detail: "学校统一身份认证网页")
                    Divider().padding(.leading, 56)
                    ProfileRow(icon: "calendar", title: "教务数据", detail: store.isAuthenticated ? "课表与成绩已连接" : "尚未连接")
                    Divider().padding(.leading, 56)
                    ProfileRow(icon: "creditcard.fill", title: "校园卡", detail: store.isCardPortalConnected ? "官方网页已连接" : "通过学校官方网页访问")
                    Divider().padding(.leading, 56)
                    NavigationLink(destination: AboutView()) {
                        ProfileRow(icon: "info.circle.fill", title: "关于岱宗盒子", detail: "开源校园工具箱", showsChevron: true)
                    }
                }.campusCard()
                if let message = store.statusMessage { InlineMessage(text: message, icon: "exclamationmark.triangle.fill") }
            }.padding(20)
        }
        .background(Color.campusCanvas.ignoresSafeArea())
        .navigationTitle("我的").navigationBarTitleDisplayMode(.inline)
    }
}

struct PendingFeaturesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "wrench.and.screwdriver.fill").font(.system(size: 34)).foregroundStyle(Color.campusBlue)
            Text("其他服务正在接入").font(.title2.bold()).foregroundStyle(Color.campusInk)
            Text("课表、成绩和校园卡已连接学校接口。图书馆选座、空闲教室和通知暂未接入可验证的安全数据源，因此当前不显示模拟信息。")
                .font(.subheadline).foregroundStyle(Color.campusMuted).fixedSize(horizontal: false, vertical: true)
            Text("社区功能按需求暂不实现。")
                .font(.caption).foregroundStyle(Color.campusMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(22).campusCard()
        .padding(20).background(Color.campusCanvas.ignoresSafeArea())
        .navigationTitle("功能状态").navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(spacing: 12) {
                    Image(systemName: "mountain.2.fill").font(.system(size: 38)).foregroundStyle(.white).frame(width: 82, height: 82).background(Color.campusBlue.gradient, in: RoundedRectangle(cornerRadius: 25))
                    Text("岱宗盒子 iOS").font(.title2.bold()).foregroundStyle(Color.campusInk)
                    Text("西安交通大学校园工具箱 · iOS 首版").font(.caption).foregroundStyle(Color.campusMuted)
                    Text("0.1.0 · 实际接口版").font(.caption2.weight(.medium)).foregroundStyle(Color.campusBlue).padding(.horizontal, 10).padding(.vertical, 6).background(Color.campusBlue.opacity(0.08), in: Capsule())
                }.frame(maxWidth: .infinity).padding(.vertical, 26).campusCard()
                VStack(alignment: .leading, spacing: 10) {
                    Text("已实现").font(.headline).foregroundStyle(Color.campusInk)
                    Text("学校统一身份认证、教务课表、成绩与加权绩点。校园卡通过内置网页打开学校官方服务；图书馆选座、空闲教室和通知暂未接入安全数据源。")
                        .font(.subheadline).foregroundStyle(Color.campusMuted).fixedSize(horizontal: false, vertical: true)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(18).campusCard()
                Text("此应用为非官方客户端。账号认证由学校网页处理，数据请求直接发送至学校服务。")
                    .font(.caption).foregroundStyle(Color.campusMuted).padding(.horizontal, 4)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Copyright © 2026 XJTU Toolbox iOS contributors")
                        .font(.caption2).foregroundStyle(Color.campusMuted)
                    Text("本软件按 GNU GPL v3 条款发布，可依该许可复制和修改；软件不提供任何担保。")
                        .font(.caption2).foregroundStyle(Color.campusMuted).fixedSize(horizontal: false, vertical: true)
                    Link("查看 GPL-3.0 许可证", destination: URL(string: "https://github.com/leowuyunwei/xjtu-toolbox-ios/blob/main/LICENSE")!)
                        .font(.caption.weight(.medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(16).campusCard()
            }.padding(20)
        }.background(Color.campusCanvas.ignoresSafeArea()).navigationTitle("关于").navigationBarTitleDisplayMode(.inline)
    }
}

struct SectionTitle: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title3.bold()).foregroundStyle(Color.campusInk)
            Text(subtitle).font(.caption).foregroundStyle(Color.campusMuted)
        }
    }
}

struct SummaryTile: View {
    let title: String
    let value: String
    let caption: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack { Image(systemName: icon).foregroundStyle(color).padding(9).background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12)); Spacer(); Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(Color.campusMuted) }
            Text(title).font(.caption).foregroundStyle(Color.campusMuted)
            Text(value).font(.title2.bold().monospacedDigit()).foregroundStyle(Color.campusInk)
            Text(caption).font(.caption2).foregroundStyle(Color.campusMuted)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(16).campusCard()
    }
}

struct HomeServiceLink<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let destination: Destination
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundStyle(color)
                    .frame(width: 42, height: 42).background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Color.campusInk)
                    Text(subtitle).font(.caption2).foregroundStyle(Color.campusMuted).lineLimit(1)
                }
                Spacer(minLength: 0)
            }.frame(maxWidth: .infinity, minHeight: 68, alignment: .leading).padding(14).campusCard()
        }.buttonStyle(.plain)
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let detail: String
    var showsChevron = false
    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.campusBlue).frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Color.campusInk)
                Text(detail).font(.caption).foregroundStyle(Color.campusMuted)
            }
            Spacer()
            if showsChevron { Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Color.campusMuted.opacity(0.65)) }
        }.padding(16)
    }
}

struct LoginPrompt: View {
    let title: String
    let detail: String
    let target: LoginTarget
    @EnvironmentObject private var store: CampusStore
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "person.badge.key.fill").font(.headline).foregroundStyle(Color.campusInk)
            Text(detail).font(.subheadline).foregroundStyle(Color.campusMuted)
            Button { store.loginRequest = target } label: {
                Text("打开学校登录页").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10).background(Color.campusBlue, in: Capsule())
            }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18).campusCard()
    }
}

struct InlineMessage: View {
    let text: String
    let icon: String
    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon).foregroundStyle(Color.campusOrange)
            Text(text).font(.caption).foregroundStyle(Color.campusMuted).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(13)
            .background(Color.campusOrange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let detail: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 28)).foregroundStyle(Color.campusBlue.opacity(0.75))
            Text(title).font(.headline).foregroundStyle(Color.campusInk)
            Text(detail).font(.caption).foregroundStyle(Color.campusMuted).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.vertical, 32).campusCard()
    }
}

extension Int {
    var mapToMondayFirst: Int { (self + 5) % 7 + 1 }
}

extension View {
    func campusCard() -> some View {
        self.background(.white, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.025), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.035), radius: 12, y: 4)
    }
}

