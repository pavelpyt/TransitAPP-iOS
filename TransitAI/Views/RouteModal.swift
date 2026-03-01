import SwiftUI

struct RouteModal: View {
    let routeData: EnhancedRouteData
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Summary card
                    RouteSummaryCard(route: routeData.route)
                    
                    // Navigation section
                    NavigationSection(navigation: routeData.navigation)
                    
                    // Steps
                    StepsSection(steps: routeData.displaySteps)
                    
                    // Destination info
                    if let destInfo = routeData.destinationInfo {
                        DestinationSection(info: destInfo)
                    }
                }
            }
            .background(Color.black)
            .navigationTitle("Detail trasy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zavřít") {
                        isPresented = false
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct RouteSummaryCard: View {
    let route: PIDRoute
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                StatItem(value: formatDuration(route.totalDuration), label: "CELKEM")
                StatItem(value: formatTime(route.arrivalTime), label: "PŘÍJEZD")
                StatItem(value: "\(route.transfers)", label: "PŘESTUPY")
            }
            
            if let fare = route.fare {
                HStack {
                    Image(systemName: "creditcard")
                        .foregroundColor(.gray)
                    Text("Jízdné: \(fare) Kč")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(20)
        .background(Color(white: 0.1))
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.cyan)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundColor(.gray)
        }
    }
}

struct NavigationSection: View {
    let navigation: Navigation
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "location.north.fill")
                    .foregroundColor(.cyan)
                Text("NAVIGACE K ZASTÁVCE")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.cyan)
                Spacer()
            }
            .padding(16)
            .background(Color.cyan.opacity(0.1))
            
            // Content
            HStack(spacing: 20) {
                // Arrow
                Image(systemName: "arrow.up")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.cyan)
                    .rotationEffect(.degrees(navigation.bearing))
                    .frame(width: 60, height: 60)
                    .background(Color(white: 0.15))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Jděte na \(navigation.direction)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("k zastávce \(navigation.fromStop.name)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 12) {
                        Label("\(navigation.distance)m", systemImage: "arrow.left.and.right")
                        Label("~\(formatDuration(navigation.walkingTime))", systemImage: "figure.walk")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.cyan)
                    .padding(.top, 4)
                }
                
                Spacer()
            }
            .padding(16)
        }
        .background(Color(white: 0.1))
    }
}

struct StepsSection: View {
    let steps: [DisplayRouteStep]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TRASA")
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                DetailedStepRow(step: step, isLast: index == steps.count - 1)
            }
        }
        .background(Color(white: 0.1))
    }
}

struct DetailedStepRow: View {
    let step: DisplayRouteStep
    let isLast: Bool
    
    var lineColor: Color {
        switch step.line {
        case "A": return .green
        case "B": return .yellow
        case "C": return .red
        default: return step.type == .walk ? Color(white: 0.3) : .cyan
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(lineColor)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Group {
                            if step.type == .walk {
                                Image(systemName: "figure.walk")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            } else {
                                Text(step.line ?? "")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: 2)
                        .frame(minHeight: 50)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // From
                HStack(spacing: 8) {
                    Text(step.departureTime)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.cyan)
                    Text(step.fromName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Details
                if step.type == .walk {
                    if let distance = step.distance {
                        Text("Pěšky \(distance)m • \(step.durationFormatted)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                } else if let headsign = step.headsign {
                    Text("Směr: \(headsign)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    if step.stopCount > 1 {
                        Text("\(step.stopCount) zastávek • \(step.durationFormatted)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
                
                // To (only for last step)
                if isLast {
                    HStack(spacing: 8) {
                        Text(step.arrivalTime)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.cyan)
                        Text(step.toName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.bottom, isLast ? 0 : 16)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

struct DestinationSection: View {
    let info: DestinationInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.cyan)
                Text("CÍL")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.cyan)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(info.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(info.address)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                
                if info.walkTime > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.walk")
                        Text("\(info.walkDistance)m • ~\(formatDuration(info.walkTime)) chůze od zastávky")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.cyan)
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.1))
    }
}

#Preview {
    RouteModal(
        routeData: EnhancedRouteData(
            route: PIDRoute(
                id: "test",
                totalDuration: 28,
                totalDistance: 350,
                transfers: 1,
                departureTime: Date(),
                arrivalTime: Date().addingTimeInterval(28 * 60),
                steps: [],
                fare: 40,
                co2Saved: 150
            ),
            navigation: Navigation(
                distance: 350,
                walkingTime: 4,
                direction: "severovýchod",
                directionShort: "SV",
                bearing: 45,
                fromStop: METRO_STATIONS[0],
                userLocation: GPSCoordinates(lat: 50.08, lng: 14.42)
            ),
            destinationInfo: DestinationInfo(
                name: "Pražský hrad",
                address: "Hradčany, Praha 1",
                walkTime: 8,
                walkDistance: 600
            ),
            displaySteps: [
                DisplayRouteStep(
                    id: "1",
                    type: .metro,
                    fromName: "Chodov",
                    toName: "Muzeum",
                    line: "C",
                    lineColor: "#E51E25",
                    headsign: "Letňany",
                    departureTime: "14:05",
                    arrivalTime: "14:18",
                    duration: 13,
                    durationFormatted: "13 min",
                    distance: nil,
                    intermediateStops: ["Roztyly", "Kačerov", "Budějovická"],
                    stopCount: 4,
                    polyline: nil
                )
            ]
        ),
        isPresented: .constant(true)
    )
}
