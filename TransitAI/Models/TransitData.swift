import Foundation
import CoreLocation

// MARK: - Localization

enum AppLanguage: String, CaseIterable, Codable {
    case czech = "cs"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .czech: return "Čeština"
        case .english: return "English"
        }
    }
}

// MARK: - Localized Strings
struct L10n {
    static var current: AppLanguage = .czech
    
    static var welcomeMessage: String {
        current == .czech
            ? "👋 Ahoj! Jsem **TransitAI**, tvůj chytrý navigátor po Praze.\n\nKam chceš jet? Napiš cíl třeba:\n• \"Chodov\"\n• \"chci jet na dejvickou\"\n• \"václavák\""
            : "👋 Hi! I'm **TransitAI**, your smart Prague transit navigator.\n\nWhere do you want to go? Type a destination like:\n• \"Chodov\"\n• \"take me to Dejvická\"\n• \"Wenceslas Square\""
    }
    
    static var notUnderstood: String {
        current == .czech
            ? "Promiň, nerozuměl jsem kam chceš jet. Zkus napsat název zastávky nebo místa."
            : "Sorry, I didn't understand. Try typing a stop name or place."
    }
    
    static var nearbyStops: String { current == .czech ? "Nejbližší zastávky" : "Nearby Stops" }
    static var routeTo: String { current == .czech ? "Trasa do" : "Route to" }
    static var walkTo: String { current == .czech ? "Jdi na" : "Walk to" }
    static var transfers: String { current == .czech ? "Přestupy" : "Transfers" }
    static var arrival: String { current == .czech ? "Příjezd" : "Arrival" }
    static var total: String { current == .czech ? "Celkem" : "Total" }
    static var minutes: String { current == .czech ? "min" : "min" }
    static var walking: String { current == .czech ? "chůze" : "walking" }
    static var calculating: String { current == .czech ? "Počítám trasu..." : "Calculating route..." }
    static var departures: String { current == .czech ? "Odjezdy" : "Departures" }
    static var savedRoutes: String { current == .czech ? "Uložené cesty" : "Saved Routes" }
    static var settings: String { current == .czech ? "Nastavení" : "Settings" }
    static var chat: String { current == .czech ? "Chat" : "Chat" }
    static var nearby: String { current == .czech ? "Okolí" : "Nearby" }
    static var home: String { current == .czech ? "Domů" : "Home" }
    static var work: String { current == .czech ? "Práce" : "Work" }
    static var save: String { current == .czech ? "Uložit" : "Save" }
    static var delete: String { current == .czech ? "Smazat" : "Delete" }
    static var cancel: String { current == .czech ? "Zrušit" : "Cancel" }
    static var didYouMean: String { current == .czech ? "Myslel jsi?" : "Did you mean?" }
    static var selectStop: String { current == .czech ? "Vyber zastávku:" : "Select a stop:" }
    
    static func stopsAway(_ count: Int) -> String {
        current == .czech ? "\(count) zastávek" : "\(count) stops"
    }
}

// MARK: - Core Types

struct GPSCoordinates: Codable, Equatable, Hashable {
    let lat: Double
    let lng: Double
    
    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    var clLocationObject: CLLocation {
        CLLocation(latitude: lat, longitude: lng)
    }
    
    func distance(to other: GPSCoordinates) -> Double {
        clLocationObject.distance(from: other.clLocationObject)
    }
    
    func bearing(to other: GPSCoordinates) -> Double {
        let lat1 = lat * .pi / 180
        let lat2 = other.lat * .pi / 180
        let dLng = (other.lng - lng) * .pi / 180
        
        let y = sin(dLng) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng)
        
        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}

enum TransportType: String, Codable, CaseIterable {
    case metro, tram, bus, train, ferry, walk, transfer
    
    var icon: String {
        switch self {
        case .metro: return "tram.fill"
        case .tram: return "tram"
        case .bus: return "bus.fill"
        case .train: return "train.side.front.car"
        case .ferry: return "ferry.fill"
        case .walk: return "figure.walk"
        case .transfer: return "arrow.triangle.2.circlepath"
        }
    }
}

enum MetroLine: String, CaseIterable, Codable {
    case A = "A", B = "B", C = "C"
    
    var color: String {
        switch self {
        case .A: return "#00A651"
        case .B: return "#FFD700"
        case .C: return "#E51E25"
        }
    }
    
    var terminals: (String, String) {
        switch self {
        case .A: return ("Nemocnice Motol", "Depo Hostivař")
        case .B: return ("Zličín", "Černý Most")
        case .C: return ("Letňany", "Háje")
        }
    }
}

// MARK: - Stop Model

struct PIDStop: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let lat: Double
    let lng: Double
    let type: TransportType
    let lines: [String]
    let zone: String
    let wheelchair: Bool
    var distanceFromUser: Int?
    
    var coordinates: GPSCoordinates { GPSCoordinates(lat: lat, lng: lng) }
    var metroLines: [MetroLine] { lines.compactMap { MetroLine(rawValue: $0) } }
    var primaryLineColor: String { metroLines.first?.color ?? "#06b6d4" }
    var isTransferStation: Bool { metroLines.count > 1 }
    
    static func == (lhs: PIDStop, rhs: PIDStop) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Departure Model

struct PIDDeparture: Identifiable, Codable {
    let id: UUID
    let line: String
    let headsign: String
    let departureTime: Date
    let delayMinutes: Int
    let platform: String?
    let vehicleType: TransportType
    let isLowFloor: Bool
    let tripId: String
    
    init(line: String, headsign: String, departureTime: Date, delayMinutes: Int = 0, platform: String? = nil, vehicleType: TransportType, isLowFloor: Bool = true, tripId: String = UUID().uuidString) {
        self.id = UUID()
        self.line = line
        self.headsign = headsign
        self.departureTime = departureTime
        self.delayMinutes = delayMinutes
        self.platform = platform
        self.vehicleType = vehicleType
        self.isLowFloor = isLowFloor
        self.tripId = tripId
    }
    
    var minutesUntil: Int { max(0, Int(departureTime.timeIntervalSinceNow / 60)) }
    var isDelayed: Bool { delayMinutes > 0 }
}

// MARK: - Route Models

struct PIDRouteStep: Identifiable, Codable {
    let id: UUID
    let type: TransportType
    let from: PIDStop
    let to: PIDStop
    let line: String?
    let headsign: String?
    let departureTime: Date
    let arrivalTime: Date
    let duration: Int
    let distance: Int?
    let intermediateStops: [PIDStop]
    let polyline: [GPSCoordinates]?
    
    init(type: TransportType, from: PIDStop, to: PIDStop, line: String?, headsign: String?, departureTime: Date, arrivalTime: Date, duration: Int, distance: Int?, intermediateStops: [PIDStop], polyline: [GPSCoordinates]? = nil) {
        self.id = UUID()
        self.type = type
        self.from = from
        self.to = to
        self.line = line
        self.headsign = headsign
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.duration = duration
        self.distance = distance
        self.intermediateStops = intermediateStops
        self.polyline = polyline
    }
    
    var allStops: [PIDStop] { [from] + intermediateStops + [to] }
}

struct PIDRoute: Identifiable, Codable {
    let id: String
    let totalDuration: Int
    let totalDistance: Int
    let transfers: Int
    let departureTime: Date
    let arrivalTime: Date
    let steps: [PIDRouteStep]
    let fare: Int?
    let co2Saved: Int?
    
    var mainLines: [String] { steps.compactMap { $0.line }.filter { !$0.isEmpty } }
    
    var allPolylineCoordinates: [GPSCoordinates] {
        steps.flatMap { step -> [GPSCoordinates] in
            step.polyline ?? step.allStops.map { $0.coordinates }
        }
    }
}

struct Navigation: Codable {
    let distance: Int
    let walkingTime: Int
    let direction: String
    let directionShort: String
    let bearing: Double
    let fromStop: PIDStop
    let userLocation: GPSCoordinates
}

struct EnhancedRouteData: Codable {
    let route: PIDRoute
    let navigation: Navigation
    let destinationInfo: DestinationInfo?
    let displaySteps: [DisplayRouteStep]
}

struct DestinationInfo: Codable {
    let name: String
    let address: String
    let walkTime: Int
    let walkDistance: Int
}

struct DisplayRouteStep: Identifiable, Codable {
    let id: String
    let type: TransportType
    let fromName: String
    let toName: String
    let line: String?
    let lineColor: String?
    let headsign: String?
    let departureTime: String
    let arrivalTime: String
    let duration: Int
    let durationFormatted: String
    let distance: Int?
    let intermediateStops: [String]
    let stopCount: Int
    let polyline: [GPSCoordinates]?
}

// MARK: - Chat Message

struct ChatMessage: Identifiable, Codable {
    let id: String
    let type: MessageType
    let content: String
    let timestamp: Date
    var routeData: EnhancedRouteData?
    var isLoading: Bool
    var suggestedStops: [PIDStop]?
    
    enum MessageType: String, Codable { case user, ai, system }
    
    init(id: String = UUID().uuidString, type: MessageType, content: String, timestamp: Date = Date(), routeData: EnhancedRouteData? = nil, isLoading: Bool = false, suggestedStops: [PIDStop]? = nil) {
        self.id = id
        self.type = type
        self.content = content
        self.timestamp = timestamp
        self.routeData = routeData
        self.isLoading = isLoading
        self.suggestedStops = suggestedStops
    }
}

// MARK: - Saved Route

struct SavedRoute: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    let fromStopId: String
    let fromStopName: String
    let toStopId: String
    let toStopName: String
    let lines: [String]
    let estimatedDuration: Int
    var icon: String
    var isFavorite: Bool
    var usageCount: Int
    var lastUsed: Date?
    let createdAt: Date
    
    init(id: UUID = UUID(), name: String, fromStopId: String, fromStopName: String, toStopId: String, toStopName: String, lines: [String], estimatedDuration: Int, icon: String = "arrow.right.circle.fill", isFavorite: Bool = false, usageCount: Int = 0, lastUsed: Date? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.fromStopId = fromStopId
        self.fromStopName = fromStopName
        self.toStopId = toStopId
        self.toStopName = toStopName
        self.lines = lines
        self.estimatedDuration = estimatedDuration
        self.icon = icon
        self.isFavorite = isFavorite
        self.usageCount = usageCount
        self.lastUsed = lastUsed
        self.createdAt = createdAt
    }
    
    var durationFormatted: String { formatDuration(estimatedDuration) }
    
    func reversed() -> SavedRoute {
        SavedRoute(name: "\(name) ↩", fromStopId: toStopId, fromStopName: toStopName, toStopId: fromStopId, toStopName: fromStopName, lines: lines.reversed(), estimatedDuration: estimatedDuration, icon: icon)
    }
}

// MARK: - Route History

struct RouteHistoryEntry: Identifiable, Codable {
    let id: UUID
    let fromStopId: String
    let fromStopName: String
    let toStopId: String
    let toStopName: String
    let lines: [String]
    let duration: Int
    let timestamp: Date
    
    init(fromStopId: String, fromStopName: String, toStopId: String, toStopName: String, lines: [String], duration: Int) {
        self.id = UUID()
        self.fromStopId = fromStopId
        self.fromStopName = fromStopName
        self.toStopId = toStopId
        self.toStopName = toStopName
        self.lines = lines
        self.duration = duration
        self.timestamp = Date()
    }
}

// MARK: - Known Places

struct KnownPlace: Codable {
    let name: String
    let nameEn: String
    let aliases: [String]
    let lat: Double
    let lng: Double
    let nearestStop: String
    let address: String
    let walkTime: Int
    let walkDistance: Int
    
    var localizedName: String { L10n.current == .czech ? name : nameEn }
}

// MARK: - User Preferences

struct UserPreferences: Codable {
    var maxTransfers: Int = 2
    var arrivalBuffer: Int = 5
    var preferMetro: Bool = true
    var avoidBus: Bool = false
    var wheelchairAccessible: Bool = false
    var language: AppLanguage = .czech
    var homeStopId: String?
    var homeStopName: String?
    var workStopId: String?
    var workStopName: String?
    var walkingSpeed: WalkingSpeed = .normal
    
    enum WalkingSpeed: String, Codable, CaseIterable {
        case slow, normal, fast
        var metersPerMinute: Int {
            switch self { case .slow: return 60; case .normal: return 80; case .fast: return 100 }
        }
        var localizedName: String {
            switch self {
            case .slow: return L10n.current == .czech ? "Pomalá" : "Slow"
            case .normal: return L10n.current == .czech ? "Normální" : "Normal"
            case .fast: return L10n.current == .czech ? "Rychlá" : "Fast"
            }
        }
    }
}

// MARK: - Disambiguation Result

struct DisambiguationResult {
    let matches: [PIDStop]
    let confidence: Double
    let needsUserInput: Bool
    var bestMatch: PIDStop? { matches.first }
}

// MARK: - Helper Functions

func formatDuration(_ minutes: Int) -> String {
    if minutes < 60 { return "\(minutes) \(L10n.minutes)" }
    let hours = minutes / 60
    let mins = minutes % 60
    return mins == 0 ? "\(hours) h" : "\(hours) h \(mins) min"
}

func formatMinutesUntil(_ date: Date) -> Int {
    max(0, Int(date.timeIntervalSinceNow / 60))
}

func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

func bearingToDirection(_ bearing: Double) -> String {
    let directions = L10n.current == .czech
        ? ["sever", "severovýchod", "východ", "jihovýchod", "jih", "jihozápad", "západ", "severozápad"]
        : ["north", "northeast", "east", "southeast", "south", "southwest", "west", "northwest"]
    return directions[Int((bearing + 22.5) / 45) % 8]
}

// MARK: - Prague Metro Data (Complete 2024)

let METRO_STATIONS: [PIDStop] = [
    // LINKA A
    PIDStop(id: "U1040", name: "Nemocnice Motol", lat: 50.0725, lng: 14.3269, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    PIDStop(id: "U1039", name: "Petřiny", lat: 50.0808, lng: 14.3347, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    PIDStop(id: "U1038", name: "Nádraží Veleslavín", lat: 50.0847, lng: 14.3528, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    PIDStop(id: "U1037", name: "Bořislavka", lat: 50.0917, lng: 14.3603, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    PIDStop(id: "U1036", name: "Dejvická", lat: 50.1003, lng: 14.3939, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    PIDStop(id: "U1035", name: "Hradčanská", lat: 50.0961, lng: 14.4039, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    PIDStop(id: "U1034", name: "Malostranská", lat: 50.0906, lng: 14.4111, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    PIDStop(id: "U1033", name: "Staroměstská", lat: 50.0886, lng: 14.4172, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    PIDStop(id: "U1032", name: "Můstek", lat: 50.0833, lng: 14.4244, type: .metro, lines: ["A", "B"], zone: "P", wheelchair: true),
    PIDStop(id: "U1031", name: "Muzeum", lat: 50.0794, lng: 14.4306, type: .metro, lines: ["A", "C"], zone: "P", wheelchair: true),
    PIDStop(id: "U1030", name: "Náměstí Míru", lat: 50.0756, lng: 14.4369, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    PIDStop(id: "U1029", name: "Jiřího z Poděbrad", lat: 50.0778, lng: 14.4500, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    PIDStop(id: "U1028", name: "Flora", lat: 50.0753, lng: 14.4611, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    PIDStop(id: "U1027", name: "Želivského", lat: 50.0772, lng: 14.4744, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    PIDStop(id: "U1026", name: "Strašnická", lat: 50.0772, lng: 14.4903, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    PIDStop(id: "U1025", name: "Skalka", lat: 50.0778, lng: 14.5072, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    PIDStop(id: "U1024", name: "Depo Hostivař", lat: 50.0811, lng: 14.5247, type: .metro, lines: ["A"], zone: "P", wheelchair: true),
    // LINKA B
    PIDStop(id: "U2040", name: "Zličín", lat: 50.0531, lng: 14.2931, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2039", name: "Stodůlky", lat: 50.0472, lng: 14.3125, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2038", name: "Luka", lat: 50.0450, lng: 14.3283, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2037", name: "Lužiny", lat: 50.0439, lng: 14.3431, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2036", name: "Hůrka", lat: 50.0442, lng: 14.3578, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2035", name: "Nové Butovice", lat: 50.0478, lng: 14.3636, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2034", name: "Jinonice", lat: 50.0522, lng: 14.3808, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2033", name: "Radlická", lat: 50.0558, lng: 14.3958, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2032", name: "Smíchovské nádraží", lat: 50.0619, lng: 14.4056, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2031", name: "Anděl", lat: 50.0694, lng: 14.4028, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2030", name: "Karlovo náměstí", lat: 50.0750, lng: 14.4178, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2029", name: "Národní třída", lat: 50.0808, lng: 14.4197, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2027", name: "Náměstí Republiky", lat: 50.0869, lng: 14.4306, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2026", name: "Florenc", lat: 50.0889, lng: 14.4389, type: .metro, lines: ["B", "C"], zone: "P", wheelchair: true),
    PIDStop(id: "U2025", name: "Křižíkova", lat: 50.0928, lng: 14.4508, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2024", name: "Invalidovna", lat: 50.0944, lng: 14.4656, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2023", name: "Palmovka", lat: 50.1000, lng: 14.4750, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2022", name: "Českomoravská", lat: 50.1064, lng: 14.4878, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2021", name: "Vysočanská", lat: 50.1083, lng: 14.5003, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2020", name: "Kolbenova", lat: 50.1083, lng: 14.5147, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2019", name: "Hloubětín", lat: 50.1069, lng: 14.5283, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2018", name: "Rajská zahrada", lat: 50.1072, lng: 14.5444, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    PIDStop(id: "U2017", name: "Černý Most", lat: 50.1083, lng: 14.5614, type: .metro, lines: ["B"], zone: "P", wheelchair: true),
    // LINKA C
    PIDStop(id: "U3040", name: "Letňany", lat: 50.1275, lng: 14.5161, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3039", name: "Prosek", lat: 50.1175, lng: 14.4978, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3038", name: "Střížkov", lat: 50.1128, lng: 14.4833, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3037", name: "Ládví", lat: 50.1053, lng: 14.4719, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3036", name: "Kobylisy", lat: 50.1006, lng: 14.4575, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3035", name: "Nádraží Holešovice", lat: 50.1094, lng: 14.4383, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3034", name: "Vltavská", lat: 50.0978, lng: 14.4389, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3032", name: "Hlavní nádraží", lat: 50.0833, lng: 14.4347, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3030", name: "I. P. Pavlova", lat: 50.0750, lng: 14.4306, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3029", name: "Vyšehrad", lat: 50.0639, lng: 14.4264, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3028", name: "Pražského povstání", lat: 50.0572, lng: 14.4367, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3027", name: "Pankrác", lat: 50.0483, lng: 14.4386, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3026", name: "Budějovická", lat: 50.0442, lng: 14.4492, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3025", name: "Kačerov", lat: 50.0350, lng: 14.4572, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3024", name: "Roztyly", lat: 50.0247, lng: 14.4825, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3023", name: "Chodov", lat: 50.0306, lng: 14.4917, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3022", name: "Opatov", lat: 50.0350, lng: 14.5044, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
    PIDStop(id: "U3021", name: "Háje", lat: 50.0383, lng: 14.5197, type: .metro, lines: ["C"], zone: "P", wheelchair: true),
]

let TRAM_STOPS: [PIDStop] = [
    PIDStop(id: "T001", name: "Václavské náměstí", lat: 50.0810, lng: 14.4280, type: .tram, lines: ["3", "9", "14", "24"], zone: "P", wheelchair: true),
    PIDStop(id: "T002", name: "Národní divadlo", lat: 50.0817, lng: 14.4139, type: .tram, lines: ["2", "9", "17", "18", "22"], zone: "P", wheelchair: true),
    PIDStop(id: "T003", name: "Malostranské náměstí", lat: 50.0883, lng: 14.4042, type: .tram, lines: ["12", "15", "20", "22"], zone: "P", wheelchair: true),
    PIDStop(id: "T004", name: "Pražský hrad", lat: 50.0906, lng: 14.3894, type: .tram, lines: ["22", "23"], zone: "P", wheelchair: true),
]

let KNOWN_PLACES: [KnownPlace] = [
    KnownPlace(name: "Václavské náměstí", nameEn: "Wenceslas Square", aliases: ["vaclavak", "wenceslas", "vaclavske namesti"], lat: 50.0810, lng: 14.4280, nearestStop: "Můstek", address: "Praha 1", walkTime: 2, walkDistance: 150),
    KnownPlace(name: "Pražský hrad", nameEn: "Prague Castle", aliases: ["hrad", "castle", "hradcany"], lat: 50.0906, lng: 14.3894, nearestStop: "Hradčanská", address: "Hradčany", walkTime: 8, walkDistance: 600),
    KnownPlace(name: "Karlův most", nameEn: "Charles Bridge", aliases: ["karluv most", "charles bridge"], lat: 50.0867, lng: 14.4111, nearestStop: "Staroměstská", address: "Praha 1", walkTime: 5, walkDistance: 350),
    KnownPlace(name: "Staroměstské náměstí", nameEn: "Old Town Square", aliases: ["staromak", "old town"], lat: 50.0875, lng: 14.4214, nearestStop: "Staroměstská", address: "Praha 1", walkTime: 4, walkDistance: 300),
    KnownPlace(name: "Letiště Praha", nameEn: "Prague Airport", aliases: ["letiste", "airport", "ruzyne"], lat: 50.1008, lng: 14.2600, nearestStop: "Nádraží Veleslavín", address: "Terminal 1/2", walkTime: 0, walkDistance: 0),
    KnownPlace(name: "Hlavní nádraží", nameEn: "Main Station", aliases: ["hlavak", "main station"], lat: 50.0833, lng: 14.4347, nearestStop: "Hlavní nádraží", address: "Praha 1", walkTime: 1, walkDistance: 50),
]

var ALL_STOPS: [PIDStop] { METRO_STATIONS + TRAM_STOPS }
