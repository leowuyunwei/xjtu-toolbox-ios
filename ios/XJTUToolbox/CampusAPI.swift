import Foundation

enum CampusAPIError: LocalizedError {
    case loginRequired
    case invalidResponse(String)
    case service(String)

    var errorDescription: String? {
        switch self {
        case .loginRequired: "请先登录西安交通大学统一身份认证。"
        case .invalidResponse(let message), .service(let message): message
        }
    }
}

final class CampusAPI {
    private let cookies = HTTPCookieStorage.shared
    private let session: URLSession
    private let jwxtHome = URL(string: "https://jwxt.xjtu.edu.cn/jwapp/sys/homeapp/index.do")!
    private let jwxtBase = URL(string: "https://jwxt.xjtu.edu.cn")!

    init() {
        cookies.cookieAcceptPolicy = .always
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = cookies
        configuration.httpShouldSetCookies = true
        configuration.httpCookieAcceptPolicy = .always
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        session = URLSession(configuration: configuration)
    }

    func importCookies(_ webCookies: [HTTPCookie]) {
        webCookies.forEach(cookies.setCookie)
    }

    func hasValidJwxtSession() async -> Bool {
        do {
            var request = URLRequest(url: jwxtHome)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  http.statusCode < 400,
                  http.url?.host == "jwxt.xjtu.edu.cn" else { return false }
            return true
        } catch {
            return false
        }
    }

    func currentTerm() async throws -> String {
        let url = jwxtBase.appending(path: "/jwapp/sys/wdkb/modules/jshkcb/dqxnxq.do")
        let data = try await send(formRequest(url, fields: [:]))
        let root = try object(data, label: "当前学期")
        let rows = nestedObjects(root, keys: ["datas", "dqxnxq", "rows"])
        guard let code = stringValue(rows.first?["DM"]), !code.isEmpty else {
            throw CampusAPIError.invalidResponse("教务系统没有返回当前学期。")
        }
        return code
    }

    func schedule(term: String) async throws -> [Course] {
        let url = jwxtBase.appending(path: "/jwapp/sys/wdkb/modules/xskcb/xskcb.do")
        let data = try await send(formRequest(url, fields: ["XNXQDM": term]))
        let root = try object(data, label: "课表")
        let rows = nestedObjects(root, keys: ["datas", "xskcb", "rows"])
        return rows.compactMap { row in
            guard let name = stringValue(row["KCM"])?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
                  let day = intValue(row["SKXQ"]), (1...7).contains(day) else { return nil }
            let start = intValue(row["KSJC"]) ?? 1
            let end = intValue(row["JSJC"]) ?? start
            return Course(
                name: name,
                teacher: stringValue(row["SKJS"]) ?? "",
                room: stringValue(row["JASMC"]) ?? "",
                start: start,
                end: end,
                weekday: day,
                weeksText: stringValue(row["ZCMC"])?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
                    ?? Self.weeksLabel(fromBitString: stringValue(row["SKZC"])),
                termCode: term
            )
        }
    }

    func grades() async throws -> [Grade] {
        let url = jwxtBase.appending(path: "/jwapp/sys/cjcx/modules/cjcx/xscjcx.do")
        let sessionURL = jwxtBase.appending(path: "/jwapp/sys/cjcx/*default/index.do")
        do {
            _ = try await send(URLRequest(url: sessionURL))
        } catch CampusAPIError.loginRequired {
            throw CampusAPIError.loginRequired
        } catch {
            // 教务偶尔会让初始化页失败，但成绩查询接口仍可能可用。
        }
        let querySetting = #"[{"name":"SFYX","caption":"是否有效","linkOpt":"AND","builderList":"cbl_m_List","builder":"m_value_equal","value":"1","value_display":"是"}]"#
        var all: [Grade] = []
        var page = 1
        let pageSize = 100

        while page <= 30 {
            let data = try await send(formRequest(url, fields: [
                "querySetting": querySetting,
                "pageSize": String(pageSize),
                "pageNumber": String(page)
            ]))
            let root = try object(data, label: "成绩")
            guard stringValue(root["code"]) == "0" else {
                throw CampusAPIError.service(stringValue(root["msg"]) ?? "教务系统成绩查询失败。")
            }
            guard let report = root["datas"] as? [String: Any],
                  let result = report["xscjcx"] as? [String: Any],
                  let rows = result["rows"] as? [[String: Any]] else {
                throw CampusAPIError.invalidResponse("成绩数据格式发生变化。")
            }

            for row in rows {
                guard let name = stringValue(row["KCM"])?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
                      let term = stringValue(row["XNXQDM"]) else { continue }
                all.append(Grade(
                    name: name,
                    termCode: term,
                    score: stringValue(row["ZCJ"]) ?? stringValue(row["DJCJMC_DISPLAY"]) ?? "—",
                    credits: doubleValue(row["XF"]) ?? 0,
                    points: doubleValue(row["XFJD"]) ?? 0
                ))
            }

            let total = intValue(result["totalSize"]) ?? all.count
            if all.count >= total || rows.count < pageSize { break }
            page += 1
        }
        return all.sorted { $0.termCode > $1.termCode }
    }

    private static func weeksLabel(fromBitString bits: String?) -> String {
        guard let bits, !bits.isEmpty else { return "" }
        let weeks = bits.enumerated().compactMap { index, bit in bit == "1" ? index + 1 : nil }
        guard !weeks.isEmpty else { return bits }
        var ranges: [String] = []
        var start = weeks[0]
        var previous = start
        for week in weeks.dropFirst() {
            if week == previous + 1 {
                previous = week
            } else {
                ranges.append(start == previous ? "\(start)" : "\(start)-\(previous)")
                start = week
                previous = week
            }
        }
        ranges.append(start == previous ? "\(start)" : "\(start)-\(previous)")
        return ranges.joined(separator: ", ") + "周"
    }

    private func formRequest(_ url: URL, fields: [String: String]) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = formEncoded(fields).data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json, text/javascript, */*; q=0.01", forHTTPHeaderField: "Accept")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue(jwxtHome.absoluteString, forHTTPHeaderField: "Referer")
        return request
    }

    private func send(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw CampusAPIError.invalidResponse("学校系统返回了无效的 HTTP 响应。")
            }
            if http.url?.host == "login.xjtu.edu.cn" || http.statusCode == 401 || http.statusCode == 403 {
                throw CampusAPIError.loginRequired
            }
            guard (200..<300).contains(http.statusCode) else {
                throw CampusAPIError.service("学校系统暂时不可用（HTTP \(http.statusCode)）。")
            }
            if let text = String(data: data.prefix(500), encoding: .utf8), text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<") {
                throw CampusAPIError.loginRequired
            }
            return data
        } catch let error as CampusAPIError {
            throw error
        } catch {
            throw CampusAPIError.service("连接学校系统失败：\(error.localizedDescription)")
        }
    }

    private func object(_ data: Data, label: String) throws -> [String: Any] {
        guard let value = try? JSONSerialization.jsonObject(with: data), let result = value as? [String: Any] else {
            throw CampusAPIError.invalidResponse("\(label)数据格式无法识别。")
        }
        return result
    }

    private func nestedObjects(_ root: [String: Any], keys: [String]) -> [[String: Any]] {
        var value: Any = root
        for key in keys {
            guard let object = value as? [String: Any], let next = object[key] else { return [] }
            value = next
        }
        return value as? [[String: Any]] ?? []
    }

    private func formEncoded(_ fields: [String: String]) -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._*")
        return fields.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
            let encodedValue = (value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value).replacingOccurrences(of: "%20", with: "+")
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
    }
}

private func stringValue(_ value: Any?) -> String? {
    guard let value else { return nil }
    if let string = value as? String { return string }
    if let number = value as? NSNumber { return number.stringValue }
    return nil
}

private func intValue(_ value: Any?) -> Int? {
    guard let value else { return nil }
    return (value as? NSNumber)?.intValue ?? (value as? String).flatMap(Int.init)
}

private func doubleValue(_ value: Any?) -> Double? {
    guard let value else { return nil }
    return (value as? NSNumber)?.doubleValue ?? (value as? String).flatMap(Double.init)
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
