import SwiftUI

@main
struct XJTUToolboxApp: App {
    @StateObject private var store = CampusStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .tint(.campusBlue)
        }
    }
}
