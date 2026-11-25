import Foundation
import SwiftUI

struct Course: Identifiable {
    let id = UUID()
    let name: String
    let teacher: String
    let room: String
    let start: Int
    let end: Int
    let weekday: Int
    let color: Color
}

struct Grade: Identifiable {
    let id = UUID()
    let name: String
    let term: String
    let score: Int
    let credits: Double

    var points: Double {
        switch score {
        case 90...: 4.0
        case 85..<90: 3.7
        case 82..<85: 3.3
        case 78..<82: 3.0
        case 75..<78: 2.7
        case 72..<75: 2.3
        case 68..<72: 2.0
        case 64..<68: 1.5
        case 60..<64: 1.0
        default: 0
        }
    }
}

struct CardTransaction: Identifiable {
    let id = UUID()
    let title: String
    let place: String
    let date: String
    let amount: Double
    let symbol: String
}

struct CampusNotice: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let date: String
}

protocol CampusDataSource {
    var courses: [Course] { get }
    var grades: [Grade] { get }
    var transactions: [CardTransaction] { get }
    var notices: [CampusNotice] { get }
}

struct DemoCampusDataSource: CampusDataSource {
    let courses: [Course] = [
        Course(name: "高等数学 II", teacher: "李老师", room: "主楼 A-201", start: 1, end: 2, weekday: 1, color: .campusBlue),
        Course(name: "大学物理", teacher: "王老师", room: "中 2-108", start: 3, end: 4, weekday: 1, color: .campusOrange),
        Course(name: "程序设计基础", teacher: "张老师", room: "东 1-301", start: 1, end: 2, weekday: 2, color: .campusPurple),
        Course(name: "线性代数", teacher: "陈老师", room: "主楼 B-112", start: 5, end: 6, weekday: 2, color: .campusGreen),
        Course(name: "大学英语", teacher: "赵老师", room: "外语楼 204", start: 3, end: 4, weekday: 3, color: .campusPink),
        Course(name: "数据结构", teacher: "周老师", room: "东 2-410", start: 1, end: 2, weekday: 4, color: .campusBlue),
        Course(name: "体育（篮球）", teacher: "刘老师", room: "东区体育馆", start: 7, end: 8, weekday: 4, color: .campusOrange),
        Course(name: "概率论与数理统计", teacher: "杨老师", room: "主楼 C-103", start: 5, end: 6, weekday: 5, color: .campusPurple)
    ]

    let grades: [Grade] = [
        Grade(name: "高等数学 II", term: "2025-2026 第二学期", score: 92, credits: 5),
        Grade(name: "大学物理", term: "2025-2026 第二学期", score: 88, credits: 4),
        Grade(name: "程序设计基础", term: "2025-2026 第二学期", score: 95, credits: 3),
        Grade(name: "大学英语", term: "2025-2026 第二学期", score: 86, credits: 2),
        Grade(name: "线性代数", term: "2025-2026 第二学期", score: 81, credits: 3)
    ]

    let transactions: [CardTransaction] = [
        CardTransaction(title: "午餐", place: "梧桐苑餐厅", date: "今天 12:16", amount: -16.5, symbol: "fork.knife"),
        CardTransaction(title: "咖啡", place: "校园咖啡屋", date: "今天 09:42", amount: -12, symbol: "cup.and.saucer.fill"),
        CardTransaction(title: "校园卡充值", place: "自助充值", date: "昨天 18:20", amount: 100, symbol: "arrow.down.left"),
        CardTransaction(title: "晚餐", place: "康桥苑餐厅", date: "昨天 17:56", amount: -21, symbol: "fork.knife")
    ]

    let notices: [CampusNotice] = [
        CampusNotice(category: "教务通知", title: "关于做好本学期期末考试工作的通知", date: "11月24日"),
        CampusNotice(category: "校园公告", title: "图书馆周末开放时间调整说明", date: "11月22日"),
        CampusNotice(category: "学院通知", title: "本科生创新实践项目申报安排", date: "11月20日")
    ]
}

@MainActor
final class CampusStore: ObservableObject {
    @Published var selectedSeat: String?
    @Published var reservedSeat: String?
    @Published var roomQuery = ""

    private let dataSource: CampusDataSource

    init(dataSource: CampusDataSource = DemoCampusDataSource()) {
        self.dataSource = dataSource
    }

    var courses: [Course] { dataSource.courses }
    var grades: [Grade] { dataSource.grades }
    var transactions: [CardTransaction] { dataSource.transactions }
    var notices: [CampusNotice] { dataSource.notices }

    var gpa: Double {
        let totalCredits = grades.reduce(0) { $0 + $1.credits }
        guard totalCredits > 0 else { return 0 }
        return grades.reduce(0) { $0 + $1.points * $1.credits } / totalCredits
    }

    func courses(on weekday: Int) -> [Course] {
        courses.filter { $0.weekday == weekday }.sorted { $0.start < $1.start }
    }
}

extension Color {
    static let campusBlue = Color(red: 0.20, green: 0.36, blue: 0.91)
    static let campusInk = Color(red: 0.10, green: 0.15, blue: 0.25)
    static let campusMuted = Color(red: 0.46, green: 0.51, blue: 0.61)
    static let campusCanvas = Color(red: 0.96, green: 0.97, blue: 0.99)
    static let campusOrange = Color(red: 0.97, green: 0.56, blue: 0.25)
    static let campusPurple = Color(red: 0.52, green: 0.40, blue: 0.88)
    static let campusGreen = Color(red: 0.20, green: 0.67, blue: 0.50)
    static let campusPink = Color(red: 0.89, green: 0.36, blue: 0.57)
}
