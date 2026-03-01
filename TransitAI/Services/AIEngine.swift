import Foundation
import Combine

/// Main AI engine for parsing queries and calculating routes
class AIEngine: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing: Bool = false
    @Published var userLocation: GPSCoordinates?
    @Published var pendingDisambiguation: DisambiguationResult?
    @Published var lastRouteData: EnhancedRouteData?
    
    private let persistence = DataPersistence.shared
    
    // MARK: - Intent Phrases (Czech + English)
    
    private let routePhrasesCZ = [
        "chci jet", "jedu", "pojedu", "potrebuju jet", "potrebuji jet",
        "vezmi me", "vezmi mě", "naviguj", "trasa", "jak se dostanu",
        "dostan me", "dostaň mě", "chci na", "chci do", "chci k",
        "musim jet", "musím jet", "potrebuju na", "kudy na", "kudy do",
        "kde je", "kde najdu", "na", "do", "k", "ke"
    ]
    
    private let routePhrasesEN = [
        "i want to go", "take me to", "go to", "navigate to", "route to",
        "how do i get to", "how to get to", "directions to", "get me to",
        "i need to go", "to", "heading to"
    ]
    
    private let departurePhrasesCZ = [
        "kdy jede", "odjezdy", "dalsi spoj", "další spoj",
        "kdy prijede", "kdy přijede", "za kolik minut",
        "jaký spoj", "nejbližší spoj"
    ]
    
    private let departurePhrasesEN = [
        "when does", "departures", "next train", "next metro",
        "how long until", "when is the next"
    ]
    
    private let nearbyPhrasesCZ = [
        "nejblizsi", "nejbližší", "okolo", "pobliz", "poblíž",
        "v okoli", "v okolí", "kde je zastavka", "kam dojdu", "co je tady"
    ]
    
    private let nearbyPhrasesEN = [
        "nearby", "closest", "nearest", "around here", "what's here",
        "stops near me", "stations nearby"
    ]
    
    // MARK: - Initialization
    
    init() {
        messages.append(ChatMessage(
            id: "welcome",
            type: .ai,
            content: L10n.welcomeMessage
        ))
    }
    
    // MARK: - Intent Parsing
    
    enum IntentType {
        case route
        case nearby
        case departure
        case selectStop(Int) // User selected disambiguation option
        case saveRoute
        case unknown
    }
    
    struct ParsedIntent {
        let type: IntentType
        let destination: String?
        let confidence: Double
    }
    
    private func parseUserIntent(_ query: String) -> ParsedIntent {
        let normalized = StringMatcher.normalize(query)
        let original = query.lowercased().trimmingCharacters(in: .whitespaces)
        
        guard normalized.count >= 1 else {
            return ParsedIntent(type: .unknown, destination: nil, confidence: 0)
        }
        
        // Check for number selection (disambiguation)
        if let num = Int(normalized), num >= 1 && num <= 5 {
            return ParsedIntent(type: .selectStop(num - 1), destination: nil, confidence: 1.0)
        }
        
        // Check for save intent
        if normalized.contains("uloz") || normalized.contains("save") {
            return ParsedIntent(type: .saveRoute, destination: nil, confidence: 0.9)
        }
        
        // Check departure phrases
        let allDeparturePhrases = departurePhrasesCZ + departurePhrasesEN
        for phrase in allDeparturePhrases {
            if normalized.contains(StringMatcher.normalize(phrase)) {
                return ParsedIntent(type: .departure, destination: nil, confidence: 0.9)
            }
        }
        
        // Check nearby phrases
        let allNearbyPhrases = nearbyPhrasesCZ + nearbyPhrasesEN
        for phrase in allNearbyPhrases {
            if normalized.contains(StringMatcher.normalize(phrase)) {
                return ParsedIntent(type: .nearby, destination: nil, confidence: 0.9)
            }
        }
        
        // Extract destination from route phrases
        var destination = original
        var confidence = 0.6
        
        let allRoutePhrases = (routePhrasesCZ + routePhrasesEN).sorted { $0.count > $1.count }
        
        for phrase in allRoutePhrases {
            let normalizedPhrase = StringMatcher.normalize(phrase)
            if let range = normalized.range(of: normalizedPhrase) {
                let idx = normalized.distance(from: normalized.startIndex, to: range.upperBound)
                destination = String(original.dropFirst(idx)).trimmingCharacters(in: .whitespaces)
                confidence = 0.95
                break
            }
        }
        
        // Remove prepositions
        let prepositions = ["na ", "do ", "k ", "ke ", "to ", "the "]
        for prep in prepositions {
            if destination.lowercased().hasPrefix(prep) {
                destination = String(destination.dropFirst(prep.count))
            }
        }
        
        destination = destination.trimmingCharacters(in: .whitespaces)
        
        if destination.isEmpty || destination.count < 2 {
            destination = original
            confidence = 0.5
        }
        
        return ParsedIntent(type: .route, destination: destination, confidence: confidence)
    }
    
    // MARK: - Stop Resolution with Disambiguation
    
    func resolveDestination(_ query: String, from location: GPSCoordinates) -> (stop: PIDStop?, place: KnownPlace?, disambiguation: DisambiguationResult?) {
        
        // Try typo correction first
        let correctedQuery = StringMatcher.correctTypo(query) ?? query
        
        // Check known places
        let placeMatches = StringMatcher.findBestPlaceMatches(query: correctedQuery, in: KNOWN_PLACES)
        if let bestPlace = placeMatches.first, bestPlace.score > 0.7 {
            if let stop = ALL_STOPS.first(where: { StringMatcher.matchScore(bestPlace.place.nearestStop, $0.name) > 0.8 }) {
                return (stop, bestPlace.place, nil)
            }
        }
        
        // Find matching stops with disambiguation
        let disambiguation = StringMatcher.disambiguate(query: correctedQuery, stops: ALL_STOPS)
        
        if disambiguation.needsUserInput {
            return (nil, nil, disambiguation)
        }
        
        if let bestMatch = disambiguation.bestMatch, disambiguation.confidence > 0.5 {
            return (bestMatch, nil, nil)
        }
        
        return (nil, nil, disambiguation.matches.isEmpty ? nil : disambiguation)
    }
    
    // MARK: - Find Nearest Stops
    
    func findNearestStops(to location: GPSCoordinates, count: Int = 5) -> [PIDStop] {
        var stops = ALL_STOPS.map { stop -> PIDStop in
            var mutableStop = stop
            mutableStop.distanceFromUser = Int(location.distance(to: stop.coordinates))
            return mutableStop
        }
        stops.sort { ($0.distanceFromUser ?? Int.max) < ($1.distanceFromUser ?? Int.max) }
        return Array(stops.prefix(count))
    }
    
    // MARK: - Route Calculation
    
    private func getStationsOnLine(_ line: String) -> [PIDStop] {
        METRO_STATIONS.filter { $0.lines.contains(line) }
    }
    
    private func getStationIndex(_ stop: PIDStop, on line: String) -> Int? {
        getStationsOnLine(line).firstIndex(where: { $0.id == stop.id })
    }
    
    private func getDirection(from: PIDStop, to: PIDStop, on line: String) -> String {
        guard let fromIdx = getStationIndex(from, on: line),
              let toIdx = getStationIndex(to, on: line) else { return "Centrum" }
        
        if let metroLine = MetroLine(rawValue: line) {
            let terminals = metroLine.terminals
            return toIdx > fromIdx ? terminals.1 : terminals.0
        }
        return "Centrum"
    }
    
    private func getIntermediateStops(from: PIDStop, to: PIDStop, on line: String) -> [PIDStop] {
        let lineStations = getStationsOnLine(line)
        guard let fromIdx = lineStations.firstIndex(where: { $0.id == from.id }),
              let toIdx = lineStations.firstIndex(where: { $0.id == to.id }) else { return [] }
        
        let start = min(fromIdx, toIdx)
        let end = max(fromIdx, toIdx)
        return Array(lineStations[(start + 1)..<end])
    }
    
    private func findTransferStation(_ fromLine: String, _ toLine: String) -> PIDStop? {
        METRO_STATIONS.first { $0.lines.contains(fromLine) && $0.lines.contains(toLine) }
    }
    
    private func calculateMetroRoute(from: PIDStop, to: PIDStop) -> [PIDRouteStep] {
        var steps: [PIDRouteStep] = []
        var currentTime = Date()
        
        let fromLines = from.lines.filter { ["A", "B", "C"].contains($0) }
        let toLines = to.lines.filter { ["A", "B", "C"].contains($0) }
        
        // Check for direct route
        if let commonLine = fromLines.first(where: { toLines.contains($0) }) {
            let intermediates = getIntermediateStops(from: from, to: to, on: commonLine)
            let duration = (intermediates.count + 1) * 2
            
            let polyline = ([from] + intermediates + [to]).map { $0.coordinates }
            
            steps.append(PIDRouteStep(
                type: .metro,
                from: from,
                to: to,
                line: commonLine,
                headsign: getDirection(from: from, to: to, on: commonLine),
                departureTime: currentTime,
                arrivalTime: currentTime.addingTimeInterval(Double(duration * 60)),
                duration: duration,
                distance: nil,
                intermediateStops: intermediates,
                polyline: polyline
            ))
        } else if let fromLine = fromLines.first, let toLine = toLines.first,
                  let transfer = findTransferStation(fromLine, toLine) {
            // Need transfer
            let intermediates1 = getIntermediateStops(from: from, to: transfer, on: fromLine)
            let duration1 = (intermediates1.count + 1) * 2
            let polyline1 = ([from] + intermediates1 + [transfer]).map { $0.coordinates }
            
            steps.append(PIDRouteStep(
                type: .metro,
                from: from,
                to: transfer,
                line: fromLine,
                headsign: getDirection(from: from, to: transfer, on: fromLine),
                departureTime: currentTime,
                arrivalTime: currentTime.addingTimeInterval(Double(duration1 * 60)),
                duration: duration1,
                distance: nil,
                intermediateStops: intermediates1,
                polyline: polyline1
            ))
            
            currentTime = currentTime.addingTimeInterval(Double((duration1 + 3) * 60))
            
            let intermediates2 = getIntermediateStops(from: transfer, to: to, on: toLine)
            let duration2 = (intermediates2.count + 1) * 2
            let polyline2 = ([transfer] + intermediates2 + [to]).map { $0.coordinates }
            
            steps.append(PIDRouteStep(
                type: .metro,
                from: transfer,
                to: to,
                line: toLine,
                headsign: getDirection(from: transfer, to: to, on: toLine),
                departureTime: currentTime,
                arrivalTime: currentTime.addingTimeInterval(Double(duration2 * 60)),
                duration: duration2,
                distance: nil,
                intermediateStops: intermediates2,
                polyline: polyline2
            ))
        }
        
        return steps
    }
    
    // MARK: - Main Message Processing
    
    @MainActor
    func sendMessage(_ query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // Add user message
        messages.append(ChatMessage(type: .user, content: query))
        isProcessing = true
        
        let location = userLocation ?? LocationManager.defaultLocation
        let intent = parseUserIntent(query)
        
        switch intent.type {
        case .selectStop(let index):
            await handleStopSelection(index: index, location: location)
            
        case .saveRoute:
            handleSaveRoute()
            
        case .unknown:
            messages.append(ChatMessage(type: .ai, content: L10n.notUnderstood))
            
        case .nearby:
            await handleNearbyRequest(location: location)
            
        case .departure:
            await handleDepartureRequest(location: location)
            
        case .route:
            await handleRouteRequest(destination: intent.destination ?? "", location: location)
        }
        
        isProcessing = false
    }
    
    // MARK: - Intent Handlers
    
    @MainActor
    private func handleStopSelection(index: Int, location: GPSCoordinates) async {
        guard let disambiguation = pendingDisambiguation,
              index < disambiguation.matches.count else {
            messages.append(ChatMessage(type: .ai, content: L10n.notUnderstood))
            return
        }
        
        let selectedStop = disambiguation.matches[index]
        pendingDisambiguation = nil
        
        await calculateAndDisplayRoute(to: selectedStop, place: nil, from: location)
    }
    
    private func handleSaveRoute() {
        guard let routeData = lastRouteData else {
            let msg = L10n.current == .czech
                ? "Nemám žádnou trasu k uložení. Nejdřív vyhledej cestu."
                : "No route to save. Search for a route first."
            messages.append(ChatMessage(type: .ai, content: msg))
            return
        }
        
        let fromStop = routeData.navigation.fromStop
        let toName = routeData.destinationInfo?.name ?? routeData.route.steps.last?.to.name ?? "Cíl"
        
        if let toStop = ALL_STOPS.first(where: { $0.name == toName }) {
            persistence.addRouteFromData(
                name: toName,
                fromStop: fromStop,
                toStop: toStop,
                lines: routeData.route.mainLines,
                duration: routeData.route.totalDuration
            )
            
            let msg = L10n.current == .czech
                ? "✅ Trasa do **\(toName)** byla uložena!"
                : "✅ Route to **\(toName)** saved!"
            messages.append(ChatMessage(type: .ai, content: msg))
        }
    }
    
    @MainActor
    private func handleNearbyRequest(location: GPSCoordinates) async {
        let nearbyStops = findNearestStops(to: location, count: 3)
        var responseText = "📍 **\(L10n.nearbyStops):**\n\n"
        
        for (idx, stop) in nearbyStops.enumerated() {
            let walkTime = (stop.distanceFromUser ?? 0) / (persistence.preferences.walkingSpeed.metersPerMinute)
            responseText += "\(idx + 1). **\(stop.name)** - \(stop.distanceFromUser ?? 0)m (\(walkTime) min \(L10n.walking))\n"
            responseText += "   \(L10n.current == .czech ? "Linky" : "Lines"): \(stop.lines.joined(separator: ", "))\n\n"
        }
        
        messages.append(ChatMessage(type: .ai, content: responseText))
    }
    
    @MainActor
    private func handleDepartureRequest(location: GPSCoordinates) async {
        let nearbyStops = findNearestStops(to: location, count: 1)
        guard let stop = nearbyStops.first else { return }
        
        let departures = generateDepartures(for: stop)
        var responseText = "🚇 **\(L10n.departures) - \(stop.name):**\n\n"
        
        for dep in departures.prefix(6) {
            responseText += "**\(dep.line)** → \(dep.headsign) - \(L10n.current == .czech ? "za" : "in") **\(dep.minutesUntil) min**\n"
        }
        
        messages.append(ChatMessage(type: .ai, content: responseText))
    }
    
    @MainActor
    private func handleRouteRequest(destination: String, location: GPSCoordinates) async {
        let resolution = resolveDestination(destination, from: location)
        
        // Handle disambiguation
        if let disambiguation = resolution.disambiguation, disambiguation.needsUserInput {
            pendingDisambiguation = disambiguation
            
            var msg = "🤔 **\(L10n.didYouMean)**\n\n"
            for (idx, stop) in disambiguation.matches.prefix(5).enumerated() {
                let distance = stop.distanceFromUser ?? Int(location.distance(to: stop.coordinates))
                msg += "\(idx + 1). **\(stop.name)** (\(stop.lines.joined(separator: ", "))) - \(distance)m\n"
            }
            msg += "\n\(L10n.current == .czech ? "Napiš číslo (1-5)" : "Type a number (1-5)")"
            
            messages.append(ChatMessage(type: .ai, content: msg, suggestedStops: disambiguation.matches))
            return
        }
        
        // No match found
        guard let toStop = resolution.stop else {
            let msg = L10n.current == .czech
                ? "❌ Nepodařilo se najít \"\(destination)\". Zkus jiný název."
                : "❌ Couldn't find \"\(destination)\". Try another name."
            messages.append(ChatMessage(type: .ai, content: msg))
            return
        }
        
        await calculateAndDisplayRoute(to: toStop, place: resolution.place, from: location)
    }
    
    @MainActor
    private func calculateAndDisplayRoute(to toStop: PIDStop, place: KnownPlace?, from location: GPSCoordinates) async {
        let nearbyStops = findNearestStops(to: location, count: 1)
        guard let fromStop = nearbyStops.first else { return }
        
        let steps = calculateMetroRoute(from: fromStop, to: toStop)
        
        let distanceToStop = Int(location.distance(to: fromStop.coordinates))
        let walkingTime = distanceToStop / persistence.preferences.walkingSpeed.metersPerMinute
        let bearing = location.bearing(to: fromStop.coordinates)
        
        let navigation = Navigation(
            distance: distanceToStop,
            walkingTime: walkingTime,
            direction: bearingToDirection(bearing),
            directionShort: String(bearingToDirection(bearing).prefix(2)).uppercased(),
            bearing: bearing,
            fromStop: fromStop,
            userLocation: location
        )
        
        let totalDuration = steps.reduce(0) { $0 + $1.duration } + walkingTime
        
        let route = PIDRoute(
            id: UUID().uuidString,
            totalDuration: totalDuration,
            totalDistance: distanceToStop,
            transfers: max(0, steps.count - 1),
            departureTime: Date().addingTimeInterval(Double(walkingTime * 60)),
            arrivalTime: Date().addingTimeInterval(Double(totalDuration * 60)),
            steps: steps,
            fare: totalDuration <= 30 ? 30 : 40,
            co2Saved: Int(Double(distanceToStop + 5000) * 0.12)
        )
        
        var destinationInfo: DestinationInfo?
        if let place = place {
            destinationInfo = DestinationInfo(
                name: place.localizedName,
                address: place.address,
                walkTime: place.walkTime,
                walkDistance: place.walkDistance
            )
        }
        
        let displaySteps = steps.map { step in
            DisplayRouteStep(
                id: step.id.uuidString,
                type: step.type,
                fromName: step.from.name,
                toName: step.to.name,
                line: step.line,
                lineColor: step.line.flatMap { MetroLine(rawValue: $0)?.color } ?? "#06b6d4",
                headsign: step.headsign,
                departureTime: formatTime(step.departureTime),
                arrivalTime: formatTime(step.arrivalTime),
                duration: step.duration,
                durationFormatted: formatDuration(step.duration),
                distance: step.distance,
                intermediateStops: step.intermediateStops.map { $0.name },
                stopCount: step.intermediateStops.count + 1,
                polyline: step.polyline
            )
        }
        
        let routeData = EnhancedRouteData(
            route: route,
            navigation: navigation,
            destinationInfo: destinationInfo,
            displaySteps: displaySteps
        )
        
        lastRouteData = routeData
        
        // Add to history
        persistence.addToHistory(
            fromStop: fromStop,
            toStop: toStop,
            lines: route.mainLines,
            duration: route.totalDuration
        )
        
        let destName = destinationInfo?.name ?? toStop.name
        let responseText = L10n.current == .czech
            ? "🚇 **\(L10n.routeTo) \(destName)**\n\n\(L10n.walkTo) **\(navigation.direction)** k zastávce **\(fromStop.name)** (\(distanceToStop)m, ~\(formatDuration(walkingTime))).\n\n📊 \(L10n.total): **\(formatDuration(totalDuration))** • \(L10n.arrival): **\(formatTime(route.arrivalTime))** • \(L10n.transfers): **\(route.transfers)**\n\n💡 *Napiš \"ulož\" pro uložení trasy*"
            : "🚇 **\(L10n.routeTo) \(destName)**\n\n\(L10n.walkTo) **\(navigation.direction)** to **\(fromStop.name)** stop (\(distanceToStop)m, ~\(formatDuration(walkingTime))).\n\n📊 \(L10n.total): **\(formatDuration(totalDuration))** • \(L10n.arrival): **\(formatTime(route.arrivalTime))** • \(L10n.transfers): **\(route.transfers)**\n\n💡 *Type \"save\" to save this route*"
        
        messages.append(ChatMessage(type: .ai, content: responseText, routeData: routeData))
    }
    
    // MARK: - Mock Departures
    
    private func generateDepartures(for stop: PIDStop) -> [PIDDeparture] {
        var departures: [PIDDeparture] = []
        let now = Date()
        
        for (idx, line) in stop.lines.prefix(4).enumerated() {
            let minutesUntil = 2 + idx * 3 + Int.random(in: 0...2)
            
            var headsign = "Centrum"
            if let metroLine = MetroLine(rawValue: line) {
                headsign = [metroLine.terminals.0, metroLine.terminals.1].randomElement()!
            }
            
            departures.append(PIDDeparture(
                line: line,
                headsign: headsign,
                departureTime: now.addingTimeInterval(Double(minutesUntil * 60)),
                vehicleType: stop.type
            ))
        }
        
        return departures.sorted { $0.minutesUntil < $1.minutesUntil }
    }
    
    // MARK: - Clear
    
    func clearMessages() {
        messages = [ChatMessage(id: "welcome", type: .ai, content: L10n.welcomeMessage)]
        pendingDisambiguation = nil
        lastRouteData = nil
    }
    
    func refreshWelcomeMessage() {
        if let idx = messages.firstIndex(where: { $0.id == "welcome" }) {
            messages[idx] = ChatMessage(id: "welcome", type: .ai, content: L10n.welcomeMessage)
        }
    }
}
