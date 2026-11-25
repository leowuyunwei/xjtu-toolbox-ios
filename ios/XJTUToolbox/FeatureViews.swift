import SwiftUI

struct CourseRow: View {
    let course: Course
    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 3) {
                Text("第 \(course.start)-\(course.end) 节").font(.caption.weight(.bold))
                if !course.weeksText.isEmpty {
                    Text(course.weeksText).font(.caption2).foregroundStyle(Color.campusMuted).lineLimit(2)
                }
            }.frame(width: 62)
            RoundedRectangle(cornerRadius: 2).fill(course.color).frame(width: 4)
            VStack(alignment: .leading, spacing: 7) {
                Text(course.name).font(.headline).foregroundStyle(Color.campusInk)
                if !course.room.isEmpty || !course.teacher.isEmpty {
                    HStack(spacing: 12) {
                        if !course.room.isEmpty { Label(course.room, systemImage: "mappin.and.ellipse") }
                        if !course.teacher.isEmpty { Label(course.teacher, systemImage: "person") }
                    }.font(.caption).foregroundStyle(Color.campusMuted)
                }
            }
            Spacer(minLength: 0)
        }.padding(15).campusCard()
    }
}

struct GradeView: View {
    @EnvironmentObject private var store: CampusStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("按学分加权 · 教务系统成绩").font(.subheadline).foregroundStyle(.white.opacity(0.86))
                    Text(store.grades.isEmpty ? "—" : String(format: "%.2f", store.gpa))
                        .font(.system(size: 48, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    Text("加权平均绩点").font(.caption).foregroundStyle(.white.opacity(0.80))
                }.frame(maxWidth: .infinity, alignment: .leading).padding(22)
                    .background(LinearGradient(colors: [.campusBlue, .campusPurple], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24))

                HStack {
                    SectionTitle(title: "课程成绩", subtitle: "共 \(store.grades.count) 条有效记录")
                    Spacer()
                    Button { Task { await store.refresh() } } label: { Image(systemName: "arrow.clockwise") }
                        .disabled(store.isLoading)
                }
                if !store.isAuthenticated {
                    LoginPrompt(title: "连接教务系统查看成绩", detail: "使用学校统一身份认证登录。", target: .jwxt)
                } else if store.grades.isEmpty && store.isLoading {
                    ProgressView("正在读取成绩…").frame(maxWidth: .infinity).padding(24)
                } else if store.grades.isEmpty {
                    EmptyState(icon: "graduationcap", title: "暂时没有成绩记录", detail: "请稍后刷新，或确认教务系统已发布成绩。")
                } else {
                    ForEach(store.grades) { grade in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(grade.name).font(.subheadline.weight(.semibold)).foregroundStyle(Color.campusInk)
                                Text("学期 \(grade.termCode) · \(grade.credits.formatted()) 学分")
                                    .font(.caption).foregroundStyle(Color.campusMuted)
                            }
                            Spacer(minLength: 8)
                            Text(String(format: "%.2f", grade.points)).font(.caption.weight(.semibold)).foregroundStyle(Color.campusBlue)
                                .padding(.horizontal, 9).padding(.vertical, 6).background(Color.campusBlue.opacity(0.08), in: Capsule())
                            Text(grade.score).font(.title3.bold().monospacedDigit()).foregroundStyle(Color.campusInk).frame(minWidth: 38, alignment: .trailing)
                        }.padding(16).campusCard()
                    }
                }
                if let message = store.statusMessage { InlineMessage(text: message, icon: "exclamationmark.triangle.fill") }
            }.padding(20)
        }
        .refreshable { await store.refresh() }
        .background(Color.campusCanvas.ignoresSafeArea())
        .navigationTitle("成绩与 GPA").navigationBarTitleDisplayMode(.inline)
    }
}

struct CampusCardView: View {
    @EnvironmentObject private var store: CampusStore
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 15) {
                HStack { Label("校园卡", systemImage: "wave.3.right").font(.subheadline.weight(.semibold)); Spacer(); Image(systemName: "creditcard.fill") }
                Text("校园卡余额与流水")
                    .font(.title2.bold())
                Text("由西安交通大学校园卡官方网页展示实时信息。")
                    .font(.caption).foregroundStyle(.white.opacity(0.86))
            }
            .foregroundStyle(.white).padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [Color(red: 0.99, green: 0.61, blue: 0.30), Color(red: 0.94, green: 0.39, blue: 0.35)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24))

            VStack(alignment: .leading, spacing: 12) {
                Text("打开学校官方校园卡页面")
                    .font(.headline).foregroundStyle(Color.campusInk)
                Text("在内置网页中完成学校单点登录，然后查看余额和交易记录。认证过程由学校网页处理；此 App 不读取或保存密码。")
                    .font(.subheadline).foregroundStyle(Color.campusMuted).fixedSize(horizontal: false, vertical: true)
                Button { store.loginRequest = .campusCard } label: {
                    Label(store.isCardPortalConnected ? "继续打开校园卡" : "连接校园卡", systemImage: "arrow.up.right.square")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 11).background(Color.campusBlue, in: Capsule())
                }
                if store.isCardPortalConnected {
                    Text("校园卡官方网页已打开；关闭网页后可从这里再次进入。")
                        .font(.caption).foregroundStyle(Color.campusGreen)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(18).campusCard()
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(Color.campusCanvas.ignoresSafeArea())
        .navigationTitle("校园卡").navigationBarTitleDisplayMode(.inline)
    }
}
