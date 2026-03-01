import SwiftUI

@main
struct TransitAIApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var aiEngine = AIEngine()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(aiEngine)
        }
    }
}
#Preview("Celá Aplikace") {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(AIEngine())
}

#Preview("Chat Screen") {
    ChatScreen()
        .environmentObject(LocationManager())
        .environmentObject(AIEngine())
}

#Preview("Nastavení") {
    SettingsScreen()
        .environmentObject(AIEngine())
        .environmentObject(LocationManager())
}

#Preview("Okolí") {
    NearbyStopsScreen()
        .environmentObject(LocationManager())
        .environmentObject(AIEngine())
}

#Preview("Cesty") {
    SavedScreen()
        .environmentObject(AIEngine())
}

