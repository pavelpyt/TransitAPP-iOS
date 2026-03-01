import Foundation
import Combine

/// Manages persistent storage for saved routes, history, and preferences
class DataPersistence: ObservableObject {
    static let shared = DataPersistence()
    
    // MARK: - Published Properties
    
    @Published var savedRoutes: [SavedRoute] = []
    @Published var routeHistory: [RouteHistoryEntry] = []
    @Published var preferences: UserPreferences = UserPreferences()
    
    // MARK: - Keys
    
    private enum Keys {
        static let savedRoutes = "savedRoutes"
        static let routeHistory = "routeHistory"
        static let preferences = "userPreferences"
    }
    
    // MARK: - Initialization
    
    private init() {
        loadAll()
    }
    
    // MARK: - Load Data
    
    func loadAll() {
        loadSavedRoutes()
        loadRouteHistory()
        loadPreferences()
    }
    
    private func loadSavedRoutes() {
        if let data = UserDefaults.standard.data(forKey: Keys.savedRoutes),
           let routes = try? JSONDecoder().decode([SavedRoute].self, from: data) {
            savedRoutes = routes
        }
    }
    
    private func loadRouteHistory() {
        if let data = UserDefaults.standard.data(forKey: Keys.routeHistory),
           let history = try? JSONDecoder().decode([RouteHistoryEntry].self, from: data) {
            routeHistory = history
        }
    }
    
    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: Keys.preferences),
           let prefs = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            preferences = prefs
            L10n.current = prefs.language
        }
    }
    
    // MARK: - Save Data
    
    private func saveSavedRoutes() {
        if let data = try? JSONEncoder().encode(savedRoutes) {
            UserDefaults.standard.set(data, forKey: Keys.savedRoutes)
        }
    }
    
    private func saveRouteHistory() {
        if let data = try? JSONEncoder().encode(routeHistory) {
            UserDefaults.standard.set(data, forKey: Keys.routeHistory)
        }
    }
    
    func savePreferences() {
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: Keys.preferences)
        }
        L10n.current = preferences.language
    }
    
    // MARK: - Saved Routes Management
    
    func addRoute(_ route: SavedRoute) {
        // Check for duplicates
        if !savedRoutes.contains(where: { $0.fromStopId == route.fromStopId && $0.toStopId == route.toStopId }) {
            savedRoutes.append(route)
            saveSavedRoutes()
        }
    }
    
    func addRouteFromData(name: String, fromStop: PIDStop, toStop: PIDStop, lines: [String], duration: Int, icon: String = "arrow.right.circle.fill") {
        let route = SavedRoute(
            name: name,
            fromStopId: fromStop.id,
            fromStopName: fromStop.name,
            toStopId: toStop.id,
            toStopName: toStop.name,
            lines: lines,
            estimatedDuration: duration,
            icon: icon
        )
        addRoute(route)
    }
    
    func updateRoute(_ route: SavedRoute) {
        if let index = savedRoutes.firstIndex(where: { $0.id == route.id }) {
            savedRoutes[index] = route
            saveSavedRoutes()
        }
    }
    
    func deleteRoute(_ route: SavedRoute) {
        savedRoutes.removeAll { $0.id == route.id }
        saveSavedRoutes()
    }
    
    func deleteRoute(at offsets: IndexSet) {
        savedRoutes.remove(atOffsets: offsets)
        saveSavedRoutes()
    }
    
    func toggleFavorite(_ route: SavedRoute) {
        if var updated = savedRoutes.first(where: { $0.id == route.id }) {
            updated.isFavorite.toggle()
            updateRoute(updated)
        }
    }
    
    func incrementUsage(_ route: SavedRoute) {
        if var updated = savedRoutes.first(where: { $0.id == route.id }) {
            updated.usageCount += 1
            updated.lastUsed = Date()
            updateRoute(updated)
        }
    }
    
    // Sorted routes (favorites first, then by usage)
    var sortedRoutes: [SavedRoute] {
        savedRoutes.sorted { a, b in
            if a.isFavorite != b.isFavorite {
                return a.isFavorite
            }
            return a.usageCount > b.usageCount
        }
    }
    
    var favoriteRoutes: [SavedRoute] {
        savedRoutes.filter { $0.isFavorite }
    }
    
    var frequentRoutes: [SavedRoute] {
        savedRoutes.filter { $0.usageCount >= 3 }.sorted { $0.usageCount > $1.usageCount }
    }
    
    // MARK: - Route History Management
    
    func addToHistory(fromStop: PIDStop, toStop: PIDStop, lines: [String], duration: Int) {
        let entry = RouteHistoryEntry(
            fromStopId: fromStop.id,
            fromStopName: fromStop.name,
            toStopId: toStop.id,
            toStopName: toStop.name,
            lines: lines,
            duration: duration
        )
        
        // Keep only last 50 entries
        routeHistory.insert(entry, at: 0)
        if routeHistory.count > 50 {
            routeHistory = Array(routeHistory.prefix(50))
        }
        
        saveRouteHistory()
    }
    
    func clearHistory() {
        routeHistory.removeAll()
        saveRouteHistory()
    }
    
    var recentRoutes: [RouteHistoryEntry] {
        Array(routeHistory.prefix(10))
    }
    
    // MARK: - Preferences
    
    func updatePreferences(_ newPrefs: UserPreferences) {
        preferences = newPrefs
        savePreferences()
    }
    
    func setLanguage(_ language: AppLanguage) {
        preferences.language = language
        L10n.current = language
        savePreferences()
    }
    
    func setHomeStop(_ stop: PIDStop) {
        preferences.homeStopId = stop.id
        preferences.homeStopName = stop.name
        savePreferences()
    }
    
    func setWorkStop(_ stop: PIDStop) {
        preferences.workStopId = stop.id
        preferences.workStopName = stop.name
        savePreferences()
    }
    
    // MARK: - Export/Import
    
    func exportData() -> Data? {
        struct ExportData: Codable {
            let savedRoutes: [SavedRoute]
            let preferences: UserPreferences
            let exportDate: Date
        }
        
        let export = ExportData(
            savedRoutes: savedRoutes,
            preferences: preferences,
            exportDate: Date()
        )
        
        return try? JSONEncoder().encode(export)
    }
    
    func importData(_ data: Data) -> Bool {
        struct ExportData: Codable {
            let savedRoutes: [SavedRoute]
            let preferences: UserPreferences
            let exportDate: Date
        }
        
        guard let imported = try? JSONDecoder().decode(ExportData.self, from: data) else {
            return false
        }
        
        savedRoutes = imported.savedRoutes
        preferences = imported.preferences
        saveSavedRoutes()
        savePreferences()
        
        return true
    }
    
    // MARK: - Reset
    
    func resetAll() {
        savedRoutes = []
        routeHistory = []
        preferences = UserPreferences()
        
        saveSavedRoutes()
        saveRouteHistory()
        savePreferences()
    }
}
