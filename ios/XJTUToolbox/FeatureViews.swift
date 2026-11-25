import Foundation
import SwiftUI

struct CourseRow: View {
    let course: Course
    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 3) {
                Text(String(format: "%02d:00", 8 + (course.start - 1) * 2)).font(.caption.weight(.bold).monospacedDigit())
                Text("第\(course.start)-\(course.end)节").font(.caption2).foregroundStyle(Color.campusMuted)
            }.frame(width: 60)
            RoundedRectangle(cornerRadius: 2).fill(course.color).frame(width: 4)
            VStack(alignment: .leading, spacing: 7) {
                Text(course.name).font(.headline).foregroundStyle(Color.campusInk)
                HStack(spacing: 12) {
                    Label(course.room, systemImage: "mappin.and.ellipse")
                    Label(course.teacher, systemImage: "person")
                }.font(.caption).foregroundStyle(Color.campusMuted)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.campusMuted)
        }.padding(15).campusCard()
    }
}

struct GradeView: View {
    @EnvironmentObject private var store: CampusStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("加权平均绩点").font(.subheadline).foregroundStyle(.white.opacity(0.86))
                    Text(String(format: "%.2f", store.gpa)).font(.system(size: 48, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    Text("基于当前显示的 5 门课程 · 演示换算规则").font(.caption).foregroundStyle(.white.opacity(0.80))
                }.frame(maxWidth: .infinity, alignment: .leading).padding(22)
                    .background(LinearGradient(colors: [.campusBlue, .campusPurple], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24))
                SectionTitle(title: "课程成绩", subtitle: "2025—2026 学年 · 第二学期")
                ForEach(store.grades) { grade in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(grade.name).font(.subheadline.weight(.semibold)).foregroundStyle(Color.campusInk)
                            Text("\(grade.credits.formatted()) 学分").font(.caption).foregroundStyle(Color.campusMuted)
                        }
                        Spacer()
                        Text(String(format: "%.1f", grade.points)).font(.caption.weight(.semibold)).foregroundStyle(Color.campusBlue)
                            .padding(.horizontal, 9).padding(.vertical, 6).background(Color.campusBlue.opacity(0.08), in: Capsule())
                        Text("\(grade.score)").font(.title3.bold().monospacedDigit()).foregroundStyle(Color.campusInk).frame(width: 38, alignment: .trailing)
                    }.padding(16).campusCard()
                }
                DemoDataFootnote()
            }.padding(20)
        }.background(Color.campusCanvas.ignoresSafeArea()).navigationTitle("成绩与 GPA").navigationBarTitleDisplayMode(.inline)
    }
}

struct CampusCardView: View {
    @EnvironmentObject private var store: CampusStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack { Label("校园卡", systemImage: "wave.3.right").font(.subheadline.weight(.semibold)); Spacer(); Image(systemName: "creditcard.fill") }
                    Text("¥ 286.50").font(.system(size: 38, weight: .bold, design: .rounded).monospacedDigit())
                    HStack { Text("演示账户 · **** 1024"); Spacer(); Text("余额") }
                        .font(.caption).foregroundStyle(.white.opacity(0.8))
                }.foregroundStyle(.white).padding(22).background(LinearGradient(colors: [Color(red: 0.99, green: 0.61, blue: 0.30), Color(red: 0.94, green: 0.39, blue: 0.35)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24))
                HStack { SectionTitle(title: "最近消费", subtitle: "仅显示演示流水"); Spacer(); Text("全部").font(.caption.weight(.medium)).foregroundStyle(Color.campusBlue) }
                VStack(spacing: 0) {
                    ForEach(Array(store.transactions.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 13) {
                            Image(systemName: item.symbol).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.campusBlue)
                                .frame(width: 42, height: 42).background(Color.campusBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(Color.campusInk)
                                Text("\(item.place) · \(item.date)").font(.caption2).foregroundStyle(Color.campusMuted)
                            }
                            Spacer()
                            Text(String(format: "%@¥%.2f", item.amount > 0 ? "+" : "−", abs(item.amount)))
                                .font(.subheadline.weight(.semibold).monospacedDigit()).foregroundStyle(item.amount > 0 ? Color.campusGreen : Color.campusInk)
                        }.padding(15)
                        if index < store.transactions.count - 1 { Divider().padding(.leading, 70) }
                    }
                }.campusCard()
                DemoDataFootnote()
            }.padding(20)
        }.background(Color.campusCanvas.ignoresSafeArea()).navigationTitle("校园卡").navigationBarTitleDisplayMode(.inline)
    }
}

struct LibraryView: View {
    @EnvironmentObject private var store: CampusStore
    private let seats = (1...32).map { $0 }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 9), count: 4)
    private let occupied: Set<Int> = [2, 5, 6, 11, 14, 17, 21, 23, 28]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("兴庆校区 · 主馆二层").font(.title3.bold()).foregroundStyle(Color.campusInk)
                    Text("自习区 A · 28 个空位").font(.subheadline).foregroundStyle(Color.campusMuted)
                }
                HStack(spacing: 14) {
                    LegendDot(color: .campusGreen, text: "空闲")
                    LegendDot(color: .campusBlue, text: "已选择")
                    LegendDot(color: Color.gray.opacity(0.3), text: "有人")
                }
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(seats, id: \.self) { number in
                        let name = "A-\(String(format: "%02d", number))"
                        let isOccupied = occupied.contains(number)
                        let isSelected = store.selectedSeat == name
                        let isReserved = store.reservedSeat == name
                        Button {
                            if !isOccupied { store.selectedSeat = isSelected ? nil : name }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: isOccupied ? "person.fill" : (isReserved ? "checkmark" : "chair.lounge.fill")).font(.system(size: 17))
                                Text(name).font(.caption2.weight(.semibold).monospacedDigit())
                            }.frame(maxWidth: .infinity).padding(.vertical, 14)
                                .foregroundStyle((isSelected || isReserved) ? .white : (isOccupied ? Color.campusMuted : Color.campusGreen))
                                .background((isSelected || isReserved) ? Color.campusBlue : (isOccupied ? Color.gray.opacity(0.11) : Color.campusGreen.opacity(0.10)), in: RoundedRectangle(cornerRadius: 14))
                        }.buttonStyle(.plain).disabled(isOccupied)
                    }
                }.padding(16).campusCard()
                if let selected = store.selectedSeat {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) { Text("已选座位").font(.caption).foregroundStyle(Color.campusMuted); Text(selected).font(.headline).foregroundStyle(Color.campusInk) }
                        Spacer()
                        Button("预约") { store.reservedSeat = selected; store.selectedSeat = nil }
                            .font(.subheadline.weight(.semibold)).foregroundStyle(.white).padding(.horizontal, 20).padding(.vertical, 11).background(Color.campusBlue, in: Capsule())
                    }.padding(16).campusCard()
                }
                if let reserved = store.reservedSeat {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("本机演示预约").font(.caption).foregroundStyle(Color.campusMuted)
                            Text(reserved).font(.headline).foregroundStyle(Color.campusInk)
                        }
                        Spacer()
                        Button("取消") { store.reservedSeat = nil }
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Color.campusBlue)
                    }.padding(16).campusCard()
                }
                DemoDataFootnote()
            }.padding(20)
        }.background(Color.campusCanvas.ignoresSafeArea()).navigationTitle("图书馆座位").navigationBarTitleDisplayMode(.inline)
    }
}

struct ClassroomView: View {
    @EnvironmentObject private var store: CampusStore
    private let rooms: [(String, String, Int, String)] = [
        ("主楼 A-203", "兴庆校区", 64, "空闲"), ("主楼 B-106", "兴庆校区", 48, "空闲"),
        ("东 1-204", "兴庆校区", 72, "空闲"), ("西 2-301", "雁塔校区", 56, "课程中"),
        ("中 3-108", "兴庆校区", 40, "空闲"), ("主楼 C-305", "兴庆校区", 80, "课程中")
    ]
    private var filtered: [(String, String, Int, String)] {
        guard !store.roomQuery.isEmpty else { return rooms.filter { $0.3 == "空闲" } }
        return rooms.filter { $0.3 == "空闲" && $0.0.localizedCaseInsensitiveContains(store.roomQuery) }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(Color.campusMuted)
                TextField("搜索楼宇或教室", text: $store.roomQuery).textInputAutocapitalization(.never)
                if !store.roomQuery.isEmpty { Button { store.roomQuery = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Color.campusMuted) } }
            }.padding(13).background(.white, in: RoundedRectangle(cornerRadius: 14)).padding(20)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(filtered.count) 间空闲教室").font(.subheadline.weight(.semibold)).foregroundStyle(Color.campusMuted)
                    ForEach(filtered, id: \.0) { room in
                        HStack(spacing: 13) {
                            Image(systemName: "door.left.hand.open").font(.system(size: 19, weight: .semibold)).foregroundStyle(Color.campusGreen)
                                .frame(width: 46, height: 46).background(Color.campusGreen.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 5) { Text(room.0).font(.headline).foregroundStyle(Color.campusInk); Text("\(room.1) · \(room.2) 个座位").font(.caption).foregroundStyle(Color.campusMuted) }
                            Spacer()
                            Text("空闲").font(.caption2.weight(.semibold)).foregroundStyle(Color.campusGreen).padding(.horizontal, 9).padding(.vertical, 6).background(Color.campusGreen.opacity(0.10), in: Capsule())
                        }.padding(14).campusCard()
                    }
                    if filtered.isEmpty { EmptyState(icon: "magnifyingglass", title: "没有找到空闲教室", detail: "试试其他楼宇或房间号。") }
                    DemoDataFootnote().padding(.top, 6)
                }.padding(.horizontal, 20).padding(.bottom, 24)
            }
        }.background(Color.campusCanvas.ignoresSafeArea()).navigationTitle("空闲教室").navigationBarTitleDisplayMode(.inline)
    }
}

struct NoticesView: View {
    @EnvironmentObject private var store: CampusStore
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(store.notices) { notice in NoticeRow(notice: notice) }
                DemoDataFootnote().padding(.top, 8)
            }.padding(20)
        }.background(Color.campusCanvas.ignoresSafeArea()).navigationTitle("校园通知").navigationBarTitleDisplayMode(.inline)
    }
}

struct NoticeRow: View {
    let notice: CampusNotice
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(notice.category).font(.caption2.weight(.semibold)).foregroundStyle(Color.campusBlue).padding(.horizontal, 9).padding(.vertical, 6).background(Color.campusBlue.opacity(0.08), in: Capsule())
                Spacer()
                Text(notice.date).font(.caption).foregroundStyle(Color.campusMuted)
            }
            Text(notice.title).font(.subheadline.weight(.semibold)).foregroundStyle(Color.campusInk).fixedSize(horizontal: false, vertical: true)
            HStack { Text("查看详情").font(.caption).foregroundStyle(Color.campusMuted); Spacer(); Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(Color.campusMuted) }
        }.padding(16).campusCard()
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
                    Text("0.1.0 · 演示版本").font(.caption2.weight(.medium)).foregroundStyle(Color.campusBlue).padding(.horizontal, 10).padding(.vertical, 6).background(Color.campusBlue.opacity(0.08), in: Capsule())
                }.frame(maxWidth: .infinity).padding(.vertical, 26).campusCard()
                VStack(alignment: .leading, spacing: 10) {
                    Text("首版功能").font(.headline).foregroundStyle(Color.campusInk)
                    Text("首页概览、周课表、成绩与 GPA、校园卡流水、图书馆选座演示、空闲教室搜索和校园通知列表。社区功能暂不实现。")
                        .font(.subheadline).foregroundStyle(Color.campusMuted).fixedSize(horizontal: false, vertical: true)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(18).campusCard()
                Text("当前页面使用本地示例内容。校园账号认证、学校数据接口、数据导入导出及推送通知需要后续接入。此应用为学生项目的非官方 iOS 客户端。")
                    .font(.caption).foregroundStyle(Color.campusMuted).padding(.horizontal, 4)
            }.padding(20)
        }.background(Color.campusCanvas.ignoresSafeArea()).navigationTitle("关于").navigationBarTitleDisplayMode(.inline)
    }
}

struct LegendDot: View {
    let color: Color
    let text: String
    var body: some View { HStack(spacing: 6) { Circle().fill(color).frame(width: 8, height: 8); Text(text).font(.caption).foregroundStyle(Color.campusMuted) } }
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

extension View {
    func campusCard() -> some View {
        self.background(.white, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.025), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.035), radius: 12, y: 4)
    }
}
