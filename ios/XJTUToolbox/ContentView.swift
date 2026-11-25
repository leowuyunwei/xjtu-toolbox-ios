import SwiftUI

struct RootTabView: View {
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
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: CampusStore
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(Date.now.formatted(.dateTime.month(.wide).day().weekday(.wide)))
                            .font(.subheadline).foregroundStyle(Color.campusMuted)
                        Text("早上好，交大学子")
                            .font(.system(size: 27, weight: .bold, design: .rounded)).foregroundStyle(Color.campusInk)
                    }
                    Spacer()
                    Image(systemName: "bell.badge")
                        .font(.system(size: 19, weight: .medium)).foregroundStyle(Color.campusInk)
                        .padding(12).background(.white, in: Circle())
                }

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Label("今日课表", systemImage: "sun.max.fill")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.88))
                        Spacer()
                        Text("第 12 周").font(.caption.weight(.medium)).padding(.horizontal, 10).padding(.vertical, 6)
                            .background(.white.opacity(0.17), in: Capsule())
                    }
                    Text("2 节课，安排得刚刚好")
                        .font(.title2.weight(.bold)).foregroundStyle(.white)
                    HStack(spacing: 10) {
                        Image(systemName: "clock.fill")
                        Text("08:00  高等数学 II")
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.caption.weight(.bold))
                    }
                    .font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.94))
                    .padding(13).background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 15))
                }
                .padding(20)
                .background(LinearGradient(colors: [Color(red: 0.20, green: 0.36, blue: 0.91), Color(red: 0.34, green: 0.50, blue: 0.98)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 26))

                LazyVGrid(columns: columns, spacing: 12) {
                    NavigationLink(destination: CampusCardView()) {
                        SummaryTile(title: "校园卡余额", value: "¥ 286.50", caption: "查看消费明细", icon: "creditcard.fill", color: .campusOrange)
                    }
                    NavigationLink(destination: GradeView()) {
                        SummaryTile(title: "当前 GPA", value: String(format: "%.2f", store.gpa), caption: "来自 5 门课程", icon: "chart.bar.fill", color: .campusPurple)
                    }
                }
                .buttonStyle(.plain)

                HStack {
                    SectionTitle(title: "常用服务", subtitle: "校园生活一站直达")
                    Spacer()
                    NavigationLink("全部", destination: ToolsView())
                        .font(.subheadline.weight(.medium)).foregroundStyle(Color.campusBlue)
                }
                LazyVGrid(columns: columns, spacing: 12) {
                    HomeServiceLink(title: "图书馆座位", subtitle: "查空位 · 预约", icon: "books.vertical.fill", color: .campusBlue, destination: LibraryView())
                    HomeServiceLink(title: "空闲教室", subtitle: "找个自习好去处", icon: "door.left.hand.open", color: .campusGreen, destination: ClassroomView())
                    HomeServiceLink(title: "成绩与 GPA", subtitle: "成绩单与学分", icon: "graduationcap.fill", color: .campusPurple, destination: GradeView())
                    HomeServiceLink(title: "校园通知", subtitle: "教务与学院公告", icon: "newspaper.fill", color: .campusPink, destination: NoticesView())
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionTitle(title: "校园速递", subtitle: "最近更新")
                    ForEach(store.notices.prefix(2)) { notice in
                        NoticeRow(notice: notice)
                    }
                }

                DemoDataFootnote()
            }
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 30)
        }
        .background(Color.campusCanvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct ScheduleView: View {
    @EnvironmentObject private var store: CampusStore
    @State private var weekday = 1
    private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("2025—2026 学年 · 第二学期").font(.subheadline).foregroundStyle(Color.campusMuted)
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
                        }.buttonStyle(.plain)
                    }
                }
                HStack { Text("星期\(weekdays[weekday - 1])").font(.title3.bold()); Spacer(); Text("第 12 周").font(.caption.weight(.medium)).foregroundStyle(Color.campusMuted) }
                let dayCourses = store.courses(on: weekday)
                if dayCourses.isEmpty {
                    EmptyState(icon: "sun.horizon.fill", title: "今天没有课程", detail: "留一点时间给自己，去图书馆看看吧。")
                } else {
                    ForEach(dayCourses) { course in CourseRow(course: course) }
                }
                DemoDataFootnote()
            }.padding(20)
        }
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
                    HomeServiceLink(title: "成绩与 GPA", subtitle: "查看课程成绩", icon: "graduationcap.fill", color: .campusPurple, destination: GradeView())
                    HomeServiceLink(title: "校园卡", subtitle: "余额与消费记录", icon: "creditcard.fill", color: .campusOrange, destination: CampusCardView())
                    HomeServiceLink(title: "图书馆", subtitle: "空位查询与选座", icon: "books.vertical.fill", color: .campusBlue, destination: LibraryView())
                    HomeServiceLink(title: "空闲教室", subtitle: "自习空间查询", icon: "door.left.hand.open", color: .campusGreen, destination: ClassroomView())
                    HomeServiceLink(title: "校园通知", subtitle: "教务与学院公告", icon: "newspaper.fill", color: .campusPink, destination: NoticesView())
                    HomeServiceLink(title: "关于应用", subtitle: "版本与项目说明", icon: "info.circle.fill", color: .campusMuted, destination: AboutView())
                }
                DemoDataFootnote()
            }.padding(20)
        }
        .background(Color.campusCanvas.ignoresSafeArea())
        .navigationTitle("工具").navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileView: View {
    @State private var showingLoginInfo = false
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 66)).symbolRenderingMode(.palette).foregroundStyle(.white, Color.campusBlue)
                    Text("交大学子").font(.title2.bold()).foregroundStyle(Color.campusInk)
                    Text("尚未连接校园账号").font(.subheadline).foregroundStyle(Color.campusMuted)
                    Button { showingLoginInfo = true } label: {
                        Label("连接校园账号", systemImage: "person.badge.key.fill")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                            .padding(.horizontal, 18).padding(.vertical, 12).background(Color.campusBlue, in: Capsule())
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 28).campusCard()

                VStack(spacing: 0) {
                    ProfileRow(icon: "lock.shield.fill", title: "数据来源", detail: "当前使用本地演示数据")
                    Divider().padding(.leading, 56)
                    ProfileRow(icon: "person.badge.key.fill", title: "校园账号", detail: "CAS 登录与校务接口接入准备中")
                    Divider().padding(.leading, 56)
                    NavigationLink(destination: AboutView()) { ProfileRow(icon: "info.circle.fill", title: "关于岱宗盒子", detail: "开源校园工具箱", showsChevron: true) }
                }.campusCard()
                DemoDataFootnote()
            }.padding(20)
        }
        .background(Color.campusCanvas.ignoresSafeArea())
        .navigationTitle("我的").navigationBarTitleDisplayMode(.inline)
        .alert("校园账号接入准备中", isPresented: $showingLoginInfo) {
            Button("知道了", role: .cancel) { }
        } message: {
            Text("当前版本使用本地演示数据。CAS 登录、多因素认证和学校接口接入会在后续版本实现。请勿在演示页面输入真实密码。")
        }
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

struct DemoDataFootnote: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill").foregroundStyle(Color.campusBlue)
            Text("当前展示的是演示数据，不代表你的实时课表、成绩或账户余额。")
                .font(.caption2).foregroundStyle(Color.campusMuted)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(13)
            .background(Color.campusBlue.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
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
            if showsChevron {
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Color.campusMuted.opacity(0.65))
            }
        }.padding(16)
    }
}
