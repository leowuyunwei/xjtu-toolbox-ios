import Foundation
import SwiftUI

enum LoginTarget: String, Identifiable, Hashable {
    case jwxt
    case campusCard
    var id: String { rawValue }
}

struct Course: Identifiable {
    var id: String { "\(termCode)-\(weekday)-\(start)-\(end)-\(name)-\(room)-\(teacher)-\(weekBits)-\(weeksText)" }
    let name: String
    let teacher: String
    let room: String
    let start: Int
    let end: Int
    let weekday: Int
    let weekBits: String
    let weeksText: String
    let termCode: String

    func isActive(in week: Int) -> Bool {
        guard week > 0 else { return false }
        let bits = weekBits.trimmingCharacters(in: .whitespacesAndNewlines)
        if !bits.isEmpty, bits.allSatisfy({ $0 == "0" || $0 == "1" }) {
            let index = bits.index(bits.startIndex, offsetBy: week - 1, limitedBy: bits.endIndex)
            guard let index, index < bits.endIndex else { return false }
            return bits[index] == "1"
        }
        return Self.weeks(from: weeksText).contains(week)
    }

    private static func weeks(from text: String) -> Set<Int> {
        guard let regex = try? NSRegularExpression(pattern: #"(\d+)(?:-(\d+))?周(?:\(([单双])\))?"#) else { return [] }
        let compact = text.replacingOccurrences(of: " ", with: "")
        let range = NSRange(compact.startIndex..<compact.endIndex, in: compact)
        var result = Set<Int>()
        for match in regex.matches(in: compact, range: range) {
            guard let startRange = Range(match.range(at: 1), in: compact),
                  let start = Int(compact[startRange]) else { continue }
            let end = Range(match.range(at: 2), in: compact).flatMap { Int(compact[$0]) } ?? start
            let parity = Range(match.range(at: 3), in: compact).map { String(compact[$0]) }
            guard end >= start else { continue }
            for value in start...end {
                if parity == "单" && value.isMultiple(of: 2) { continue }
                if parity == "双" && !value.isMultiple(of: 2) { continue }
                result.insert(value)
            }
        }
        return result
    }

    var color: Color {
        [Color.campusBlue, .campusOrange, .campusPurple, .campusGreen, .campusPink][max(0, (weekday - 1) % 5)]
    }
}

struct Grade: Identifiable {
    var id: String { "\(termCode)-\(name)-\(score)-\(credits)" }
    let name: String
    let termCode: String
    let score: String
    let credits: Double
    let points: Double
}

@MainActor
final class CampusStore: ObservableObject {
    @Published private(set) var courses: [Course] = []
    @Published private(set) var grades: [Grade] = []
    @Published private(set) var termCode: String?
    @Published private(set) var currentWeek: Int?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isCardPortalConnected = false
    @Published private(set) var isLoading = false
    @Published private(set) var lastUpdated: Date?
    @Published var loginRequest: LoginTarget?
    @Published var statusMessage: String?
    private var refreshPending = false

    let api = CampusAPI()

    var gpa: Double {
        let credits = grades.reduce(0) { $0 + $1.credits }
        guard credits > 0 else { return 0 }
        return grades.reduce(0) { $0 + $1.points * $1.credits } / credits
    }

    var todayWeekday: Int {
        (Calendar.current.component(.weekday, from: .now) + 5) % 7 + 1
    }

    var currentWeekLabel: String {
        guard let currentWeek else { return "周次未知" }
        return currentWeek > 0 ? "第 \(currentWeek) 周" : "非授课周"
    }

    init() {
        Task {
            await api.restorePersistedCookies()
            await checkExistingSession()
        }
    }

    func checkExistingSession() async {
        isAuthenticated = await api.hasValidJwxtSession()
        if isAuthenticated { await refresh() }
    }

    func completeLogin(cookies: [HTTPCookie]) async {
        await api.importCookies(cookies)
        do {
            guard await api.hasValidJwxtSession() else { throw CampusAPIError.loginRequired }
            _ = try await api.currentTerm()
            isAuthenticated = true
            statusMessage = nil
            await refresh()
        } catch {
            isAuthenticated = false
            statusMessage = error.localizedDescription
        }
    }

    func completeCardPortal(cookies: [HTTPCookie]) async {
        await api.importCookies(cookies)
        isCardPortalConnected = true
        statusMessage = nil
        isAuthenticated = await api.hasValidJwxtSession()
        if isAuthenticated { await refresh() }
    }

    func refresh() async {
        guard !isLoading else {
            refreshPending = true
            return
        }
        isLoading = true
        defer {
            isLoading = false
            if refreshPending {
                refreshPending = false
                Task { await self.refresh() }
            }
        }
        statusMessage = nil

        let term: String
        do {
            term = try await api.currentTerm()
        } catch CampusAPIError.loginRequired {
            isAuthenticated = false
            statusMessage = "教务当前学期接口要求重新认证，请重新登录教务系统。"
            return
        } catch {
            statusMessage = "无法验证教务会话：\(error.localizedDescription)"
            return
        }

        termCode = term
        isAuthenticated = true
        var failures: [String] = []
        do {
            currentWeek = try await api.currentWeek(term: term)
        } catch {
            currentWeek = nil
            failures.append("当前教学周计算失败：\(error.localizedDescription)")
        }
        await api.persistCookies()
        do {
            courses = try await api.schedule(term: term)
        } catch {
            failures.append("课表获取失败：\(error.localizedDescription)")
        }
        do {
            grades = try await api.grades()
        } catch {
            failures.append("成绩获取失败：\(error.localizedDescription)")
        }
        await api.persistCookies()
        lastUpdated = Date()
        if !failures.isEmpty { statusMessage = failures.joined(separator: "；") }
    }

    func courses(on weekday: Int) -> [Course] {
        guard let currentWeek, currentWeek > 0 else { return [] }
        return courses.filter { $0.weekday == weekday && $0.isActive(in: currentWeek) }
            .sorted { $0.start < $1.start }
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

