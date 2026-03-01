import SwiftUI
import MapKit

struct NearbyStopsScreen: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var aiEngine: AIEngine
    
    @State private var nearbyStops: [PIDStop] = []
    @State private var departures: [String: [PIDDeparture]] = [:]
    @State private var isLoading: Bool = true
    @State private var lastUpdate: Date?
    @State private var expandedStopId: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Loading bar
            if isLoading {
                ProgressView()
                    .progressViewStyle(LinearProgressViewStyle(tint: .black))
                    .frame(height: 2)
            }
            
            // Map
            mapView
            
            // Last update
            if let lastUpdate = lastUpdate {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(white: 0.56))
                    Text("Aktualizováno: \(formatTime(lastUpdate))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(white: 0.56))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(white: 0.97))
            }
            
            // Stops list
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(nearbyStops) { stop in
                        StopCard(
                            stop: stop,
                            departures: departures[stop.id] ?? [],
                            isExpanded: expandedStopId == stop.id,
                            isLoading: isLoading
                        ) {
                            withAnimation {
                                if expandedStopId == stop.id {
                                    expandedStopId = nil
                                } else {
                                    expandedStopId = stop.id
                                }
                            }
                        } onRefresh: {
                            loadDepartures(for: stop)
                        }
                    }
                    
                    if nearbyStops.isEmpty && !isLoading {
                        emptyStateView
                    }
                }
                .padding(20)
            }
        }
        .background(Color(hex: "F6F6F6")) // Canvas pozadí
        .onAppear {
            loadData()
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "location.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Okolí")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                Text("NEJBLIŽŠÍ ZASTÁVKY")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(Color(white: 0.56))
            }
            
            Spacer()
            
            Button {
                loadData()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Obnovit")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
            }
            .disabled(isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(white: 0.93))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var mapView: some View {
        ZStack {
            if let location = locationManager.coordinates {
                Map {
                    // User location
                    Annotation("", coordinate: location.clLocation) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 8)
                    }
                    
                    // Nearby stops
                    ForEach(nearbyStops) { stop in
                        Annotation(stop.name, coordinate: stop.coordinates.clLocation) {
                            StopMarker(stop: stop)
                        }
                    }
                }
                .mapStyle(.standard)
                .preferredColorScheme(.dark)
            } else {
                Color(white: 0.97)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "location.slash")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(Color(white: 0.56))
                            Text("Čekám na GPS...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(white: 0.56))
                        }
                    )
            }
        }
        .frame(height: 200)
        .overlay(
            Rectangle()
                .fill(Color(white: 0.93))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(Color(white: 0.56).opacity(0.5))
            Text("Žádné zastávky v okolí")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(white: 0.56))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
    
    private func loadData() {
        isLoading = true
        
        let location = locationManager.coordinates ?? LocationManager.defaultLocation
        nearbyStops = aiEngine.findNearestStops(to: location, count: 5)
        
        // Load departures for each stop
        for stop in nearbyStops {
            loadDepartures(for: stop)
        }
        
        lastUpdate = Date()
        isLoading = false
    }
    
    private func loadDepartures(for stop: PIDStop) {
        // Generate mock departures
        var deps: [PIDDeparture] = []
        let now = Date()
        
        for (idx, line) in stop.lines.prefix(4).enumerated() {
            let minutesUntil = 2 + idx * 3 + Int.random(in: 0...2)
            deps.append(PIDDeparture(
                line: line,
                headsign: getHeadsign(for: line, stop: stop),
                departureTime: now.addingTimeInterval(Double(minutesUntil * 60)),
                delayMinutes: Int.random(in: 0...2),
                platform: nil,
                vehicleType: stop.type,
                isLowFloor: true,
                tripId: UUID().uuidString
            ))
        }
        
        departures[stop.id] = deps.sorted { $0.minutesUntil < $1.minutesUntil }
    }
    
    private func getHeadsign(for line: String, stop: PIDStop) -> String {
        switch line {
        case "A": return ["Depo Hostivař", "Nemocnice Motol"].randomElement()!
        case "B": return ["Černý Most", "Zličín"].randomElement()!
        case "C": return ["Háje", "Letňany"].randomElement()!
        default: return "Centrum"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "< 1 min"
        }
        let minutes = seconds / 60
        return "\(minutes) min"
    }
}

struct StopMarker: View {
    let stop: PIDStop
    
    var backgroundColor: Color {
        if stop.lines.contains("A") { return .green }
        if stop.lines.contains("B") { return .yellow }
        if stop.lines.contains("C") { return .red }
        return .black
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
            .frame(width: 28, height: 28)
            .overlay(
                Text(stop.lines.filter { ["A", "B", "C"].contains($0) }.joined())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(stop.lines.contains("B") ? .black : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.2), radius: 6)
    }
}

struct StopCard: View {
    let stop: PIDStop
    let departures: [PIDDeparture]
    let isExpanded: Bool
    let isLoading: Bool
    let onToggle: () -> Void
    let onRefresh: () -> Void
    
    var lineColor: Color {
        if stop.lines.contains("A") { return .green }
        if stop.lines.contains("B") { return .yellow }
        if stop.lines.contains("C") { return .red }
        return .black
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(lineColor)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Group {
                                if stop.type == .metro {
                                    Text(stop.lines.filter { ["A", "B", "C"].contains($0) }.joined())
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(stop.lines.contains("B") ? .black : .white)
                                } else {
                                    Image(systemName: "tram.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stop.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                        Text("\(stop.distanceFromUser ?? 0)m • \(formatDuration((stop.distanceFromUser ?? 0) / 80)) chůze")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(white: 0.56))
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(Color(white: 0.56))
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(18)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded departures
            if isExpanded {
                VStack(spacing: 0) {
                    // Refresh header
                    HStack {
                        Text("ŽIVÉ ODJEZDY")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(Color(white: 0.56))
                        
                        Spacer()
                        
                        Button(action: onRefresh) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color(white: 0.97))
                    
                    // Departures list
                    ForEach(departures.prefix(6)) { dep in
                        DepartureRow(departure: dep, lineColor: lineColor)
                    }
                }
                .overlay(
                    Rectangle()
                        .fill(Color(white: 0.93))
                        .frame(height: 1),
                    alignment: .top
                )
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 3)
    }
}

struct DepartureRow: View {
    let departure: PIDDeparture
    let lineColor: Color
    
    var isImminent: Bool {
        departure.minutesUntil <= 2
    }
    
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(lineColor)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(departure.line)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(lineColor == .yellow ? .black : .white)
                )
            
            Text(departure.headsign)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(departure.minutesUntil) min")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isImminent ? .red : .black)
                
                if departure.delayMinutes > 0 {
                    Text("+\(departure.delayMinutes) min")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .overlay(
            Rectangle()
                .fill(Color(white: 0.93))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

#Preview {
    NearbyStopsScreen()
        .environmentObject(LocationManager())
        .environmentObject(AIEngine())
}
