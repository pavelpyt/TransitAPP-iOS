import SwiftUI
import MapKit

// MARK: - MapView (for future detailed map feature)

struct MapView: View {
    let stops: [PIDStop]
    let userLocation: GPSCoordinates?
    var selectedStop: PIDStop?
    
    @State private var region: MKCoordinateRegion
    
    init(stops: [PIDStop], userLocation: GPSCoordinates?, selectedStop: PIDStop? = nil) {
        self.stops = stops
        self.userLocation = userLocation
        self.selectedStop = selectedStop
        
        // Initialize region centered on user location or Prague center
        let center = userLocation?.clLocation ?? CLLocationCoordinate2D(latitude: 50.0810, longitude: 14.4280)
        _region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        ZStack {
            // Map background
            Map(coordinateRegion: $region, annotationItems: annotationItems) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    if item.isUser {
                        // User location marker
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                    } else if let stop = item.stop {
                        // Stop marker
                        StopMapMarker(stop: stop, isSelected: stop.id == selectedStop?.id)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
        .preferredColorScheme(.dark)
    }
    
    private var annotationItems: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = []
        
        // Add user location
        if let location = userLocation {
            items.append(MapAnnotationItem(
                id: "user",
                coordinate: location.clLocation,
                isUser: true,
                stop: nil
            ))
        }
        
        // Add stops
        items.append(contentsOf: stops.map { stop in
            MapAnnotationItem(
                id: stop.id,
                coordinate: stop.coordinates.clLocation,
                isUser: false,
                stop: stop
            )
        })
        
        return items
    }
}

// Helper struct for map annotations
struct MapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let isUser: Bool
    let stop: PIDStop?
}

struct StopMapMarker: View {
    let stop: PIDStop
    let isSelected: Bool
    
    var lineColor: Color {
        if stop.lines.contains("A") { return .green }
        if stop.lines.contains("B") { return .yellow }
        if stop.lines.contains("C") { return .red }
        return .cyan
    }
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(lineColor)
                .frame(width: isSelected ? 32 : 24, height: isSelected ? 32 : 24)
                .overlay(
                    Text(stop.lines.filter { ["A", "B", "C"].contains($0) }.joined())
                        .font(.system(size: isSelected ? 11 : 9, weight: .bold))
                        .foregroundColor(.black)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 2)
                )
                .shadow(color: lineColor.opacity(isSelected ? 0.6 : 0.3), radius: isSelected ? 8 : 4)
            
            if isSelected {
                Text(stop.name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(4)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview("MapView") {
    MapView(
        stops: Array(METRO_STATIONS.prefix(5)),
        userLocation: GPSCoordinates(lat: 50.0810, lng: 14.4280),
        selectedStop: METRO_STATIONS.first
    )
}
