import SwiftUI
import _MapKit_SwiftUI
import SwiftUI

struct ChatScreen: View {
    @EnvironmentObject var aiEngine: AIEngine
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var persistence = DataPersistence.shared
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Loading bar
                if aiEngine.isProcessing {
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle(tint: .black))
                        .frame(height: 2)
                }
                
                // Messages
                ScrollViewReader { proxy in
                    ZStack(alignment: .bottom) {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(aiEngine.messages) { message in
                                    MessageBubble(message: message, onStopTap: { index in
                                        Task {
                                            await aiEngine.sendMessage("\(index + 1)")
                                        }
                                    })
                                    .id(message.id)
                                }
                                
                                if aiEngine.isProcessing {
                                    LoadingBubble()
                                }
                            }
                            .padding()
                            .padding(.bottom, 200) // Větší prostor pro quick actions + chatbox
                        }
                        .onChange(of: aiEngine.messages.count) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                        
                        // Gradient na konec obsahu
                        VStack {
                            Spacer()
                            LinearGradient(
                                colors: [
                                    Color(hex: "F6F6F6").opacity(0),
                                    Color(hex: "F6F6F6").opacity(0.4),
                                    Color(hex: "F6F6F6")
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 250)
                            .allowsHitTesting(false) // Neblokuje interakce
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            .background(Color(hex: "F6F6F6"))
        }
        .onAppear {
            aiEngine.userLocation = locationManager.coordinates
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = aiEngine.messages.last {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "message.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("TransitAI")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                Text(L10n.current == .czech ? "NAVIGÁTOR" : "NAVIGATOR")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(Color(white: 0.56))
            }
            
            Spacer()
            
            // GPS status
            HStack(spacing: 6) {
                Circle()
                    .fill(locationManager.location != nil ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(locationManager.location != nil ? "GPS OK" : "GPS...")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(white: 0.56))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(white: 0.97))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    var onStopTap: ((Int) -> Void)?
    
    var body: some View {
        HStack {
            if message.type == .user { Spacer() }
            
            VStack(alignment: message.type == .user ? .trailing : .leading, spacing: 12) {
                // Text content
                Text(parseMarkdown(message.content))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(message.type == .user ? .white : .black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(message.type == .user ? Color.black : Color(white: 0.97))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                
                // Suggested stops for disambiguation
                if let stops = message.suggestedStops, !stops.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(Array(stops.prefix(5).enumerated()), id: \.element.id) { index, stop in
                            Button {
                                onStopTap?(index)
                            } label: {
                                HStack(spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(Color.black)
                                        .cornerRadius(16)
                                    
                                    Text(stop.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Text(stop.lines.joined(separator: ", "))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color(white: 0.56))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                            }
                        }
                    }
                }
                
                // Route data
                if let routeData = message.routeData {
                    RouteCard(routeData: routeData)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.85, alignment: message.type == .user ? .trailing : .leading)
            
            if message.type != .user { Spacer() }
        }
    }
    
    private func parseMarkdown(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }
}

// MARK: - Loading Bubble

struct LoadingBubble: View {
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.black)
                    .font(.system(size: 14))
                Text(L10n.calculating)
                    .font(.system(size: 15))
                    .foregroundColor(Color(white: 0.56))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color(white: 0.97))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            Spacer()
        }
    }
}

// MARK: - Route Card with Map

struct RouteCard: View {
    let routeData: EnhancedRouteData
    @State private var expandedSteps: Set<String> = []
    @State private var showMap: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation header
            NavigationHeader(navigation: routeData.navigation)
            
            // Mini Map Toggle
            Button {
                withAnimation { showMap.toggle() }
            } label: {
                HStack {
                    Image(systemName: "map")
                        .foregroundColor(.black)
                        .font(.system(size: 14, weight: .semibold))
                    Text(L10n.current == .czech ? "Zobrazit mapu" : "Show Map")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: showMap ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color(white: 0.56))
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(16)
                .background(Color.white)
            }
            
            // Route Map
            if showMap {
                RouteMapView(routeData: routeData)
                    .frame(height: 200)
            }
            
            // Route steps
            VStack(spacing: 0) {
                ForEach(Array(routeData.displaySteps.enumerated()), id: \.element.id) { index, step in
                    RouteStepRow(
                        step: step,
                        isExpanded: expandedSteps.contains(step.id),
                        isLast: index == routeData.displaySteps.count - 1
                    ) {
                        withAnimation {
                            if expandedSteps.contains(step.id) {
                                expandedSteps.remove(step.id)
                            } else {
                                expandedSteps.insert(step.id)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(white: 0.97))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Route Map View

struct RouteMapView: View {
    let routeData: EnhancedRouteData
    
    var body: some View {
        Map {
            // User location
            Annotation("", coordinate: routeData.navigation.userLocation.clLocation) {
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
            
            // Route polyline
            let coordinates = routeData.route.allPolylineCoordinates.map { $0.clLocation }
            if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .stroke(Color.cyan, lineWidth: 4)
            }
            
            // Stop markers
            ForEach(routeData.displaySteps) { step in
                Annotation(step.fromName, coordinate: CLLocationCoordinate2D(
                    latitude: METRO_STATIONS.first { $0.name == step.fromName }?.lat ?? 0,
                    longitude: METRO_STATIONS.first { $0.name == step.fromName }?.lng ?? 0
                )) {
                    StopMarkerView(line: step.line)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .colorScheme(.dark)
    }
}

struct StopMarkerView: View {
    let line: String?
    
    var color: Color {
        switch line {
        case "A": return .green
        case "B": return .yellow
        case "C": return .red
        default: return .cyan
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: 20, height: 20)
            .overlay(
                Text(line ?? "●")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
            )
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 1))
    }
}

// MARK: - Navigation Header

struct NavigationHeader: View {
    let navigation: Navigation
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "location.north.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    )
                
                Text(L10n.current == .czech ? "NAVIGACE K ZASTÁVCE" : "NAVIGATION TO STOP")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("\(navigation.distance)m")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black)
                    .cornerRadius(12)
            }
            .padding(16)
            .background(Color.white)
            
            // Direction arrow
            VStack(spacing: 12) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.black)
                    .rotationEffect(.degrees(navigation.bearing))
                    .frame(width: 70, height: 70)
                    .background(Color.white)
                    .cornerRadius(35)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                
                Text("\(L10n.walkTo) \(navigation.direction)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                Text("\(L10n.current == .czech ? "k zastávce" : "to stop") \(navigation.fromStop.name)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(white: 0.56))
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.97))
        }
    }
}

// MARK: - Route Step Row

struct RouteStepRow: View {
    let step: DisplayRouteStep
    let isExpanded: Bool
    let isLast: Bool
    let onToggle: () -> Void
    
    var lineColor: Color {
        switch step.line {
        case "A": return .green
        case "B": return .yellow
        case "C": return .red
        default: return step.type == .walk ? Color(white: 0.56) : .black
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(lineColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Group {
                            if step.type == .walk {
                                Image(systemName: "figure.walk")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .semibold))
                            } else {
                                Text(step.line ?? "")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(step.line == "B" ? .black : .white)
                            }
                        }
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(lineColor.opacity(0.3))
                        .frame(width: 3)
                        .frame(minHeight: 50)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Button(action: onToggle) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 10) {
                                Text(step.departureTime)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black)
                                Text(step.fromName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            
                            if step.type != .walk, let headsign = step.headsign {
                                Text("\(L10n.current == .czech ? "Směr" : "Direction"): \(headsign)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(white: 0.56))
                            }
                        }
                        
                        Spacer()
                        
                        if step.stopCount > 1 {
                            HStack(spacing: 6) {
                                Text(L10n.stopsAway(step.stopCount))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(white: 0.56))
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(white: 0.56))
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if isExpanded && !step.intermediateStops.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(step.intermediateStops, id: \.self) { stopName in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(Color(white: 0.56).opacity(0.5))
                                    .frame(width: 6, height: 6)
                                Text(stopName)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color(white: 0.56))
                            }
                        }
                    }
                    .padding(.leading, 10)
                    .padding(.top, 8)
                }
                
                if isLast {
                    HStack(spacing: 10) {
                        Text(step.arrivalTime)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                        Text(step.toName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 10)
                }
            }
            .padding(.bottom, isLast ? 0 : 20)
        }
    }
}

#Preview {
    ChatScreen()
        .environmentObject(AIEngine())
        .environmentObject(LocationManager())
}
