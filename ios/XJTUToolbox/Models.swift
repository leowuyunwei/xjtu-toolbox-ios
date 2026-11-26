import Foundation
import SwiftUI

enum LoginTarget: String, Identifiable, Hashable {
    case jwxt
    case campusCard
    var id: String { rawValue }
}

struct Course: Identifiable {
    var id: String { "\(termCode)-\(weekday)-\(start)-\(end)-\(name)-\(room)-\(teacher)-\(weeksText)" }
    let name: String
    let teacher: String
    let room: String
    let start: Int
    let end: Int
    let weekday: Int
    let weeksText: String
    let termCode: String

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

    init() {
        Task { await checkExistingSession() }
    }

    func checkExistingSession() async {
        isAuthenticated = await api.hasValidJwxtSession()
        if isAuthenticated { await refresh() }
    }

    func completeLogin(cookies: [HTTPCookie]) async {
        api.importCookies(cookies)
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
        api.importCookies(cookies)
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

        do {
            let term = try await api.currentTerm()
            async let newCourses = api.schedule(term: term)
            async let newGrades = api.grades()
            courses = try await newCourses
            grades = try await newGrades
            termCode = term
            isAuthenticated = true
            lastUpdated = Date()
        } catch CampusAPIError.loginRequired {
            isAuthenticated = false
            statusMessage = "统一认证会话已失效，请重新登录。"
        } catch {
            statusMessage = error.localizedDescription
        }

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

