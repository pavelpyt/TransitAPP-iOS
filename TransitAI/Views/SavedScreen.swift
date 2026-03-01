import SwiftUI

struct SavedScreen: View {
    @EnvironmentObject var aiEngine: AIEngine
    @StateObject private var persistence = DataPersistence.shared
    @State private var showingAddRoute = false
    @State private var editingRoute: SavedRoute?
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            if persistence.savedRoutes.isEmpty && persistence.routeHistory.isEmpty {
                emptyStateView
            } else {
                routesList
            }
        }
        .background(Color(hex: "F6F6F6")) // Canvas pozadí
        .sheet(isPresented: $showingAddRoute) {
            AddRouteSheet()
        }
        .sheet(item: $editingRoute) { route in
            EditRouteSheet(route: route)
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.current == .czech ? "Cesty" : "Routes")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                Text(L10n.savedRoutes.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(Color(white: 0.56))
            }
            
            Spacer()
            
            Button { showingAddRoute = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black)
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(Rectangle().fill(Color(white: 0.93)).frame(height: 1), alignment: .bottom)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "heart.slash")
                .font(.system(size: 64, weight: .semibold))
                .foregroundColor(Color(white: 0.56).opacity(0.4))
            
            VStack(spacing: 8) {
                Text(L10n.current == .czech ? "Žádné uložené cesty" : "No saved routes")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                Text(L10n.current == .czech ? "Napiš \"ulož\" v chatu pro uložení" : "Type \"save\" in chat to save")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(white: 0.56))
            }
            Spacer()
        }
    }
    
    private var routesList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if !persistence.favoriteRoutes.isEmpty {
                    SectionHeader(title: L10n.current == .czech ? "OBLÍBENÉ" : "FAVORITES", icon: "star.fill")
                    ForEach(persistence.favoriteRoutes) { route in
                        SavedRouteCard(route: route, onTap: { useRoute(route) }, onEdit: { editingRoute = route }, onDelete: { persistence.deleteRoute(route) }, onToggleFavorite: { persistence.toggleFavorite(route) })
                    }
                }
                
                let nonFavorites = persistence.savedRoutes.filter { !$0.isFavorite }
                if !nonFavorites.isEmpty {
                    SectionHeader(title: L10n.savedRoutes.uppercased(), icon: "folder.fill")
                    ForEach(nonFavorites) { route in
                        SavedRouteCard(route: route, onTap: { useRoute(route) }, onEdit: { editingRoute = route }, onDelete: { persistence.deleteRoute(route) }, onToggleFavorite: { persistence.toggleFavorite(route) })
                    }
                }
                
                if !persistence.recentRoutes.isEmpty {
                    SectionHeader(title: L10n.current == .czech ? "POSLEDNÍ" : "RECENT", icon: "clock.fill")
                    ForEach(persistence.recentRoutes) { entry in
                        HistoryRouteCard(entry: entry, onTap: {
                            Task { await aiEngine.sendMessage(entry.toStopName) }
                        }, onSave: { saveFromHistory(entry) }, onReverse: {
                            Task { await aiEngine.sendMessage(entry.fromStopName) }
                        })
                    }
                }
            }
            .padding(20)
        }
    }
    
    private func useRoute(_ route: SavedRoute) {
        persistence.incrementUsage(route)
        Task { await aiEngine.sendMessage(route.toStopName) }
    }
    
    private func saveFromHistory(_ entry: RouteHistoryEntry) {
        guard let from = ALL_STOPS.first(where: { $0.id == entry.fromStopId }),
              let to = ALL_STOPS.first(where: { $0.id == entry.toStopId }) else { return }
        persistence.addRouteFromData(name: entry.toStopName, fromStop: from, toStop: to, lines: entry.lines, duration: entry.duration)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundColor(Color(white: 0.56))
            Text(title).font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(Color(white: 0.56))
            Rectangle().fill(Color(white: 0.93)).frame(height: 1)
        }
        .padding(.top, 12)
    }
}

struct SavedRouteCard: View {
    let route: SavedRoute
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
                    .frame(width: 52, height: 52)
                    .overlay(Image(systemName: route.icon).foregroundColor(.white).font(.system(size: 22, weight: .semibold)))
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(route.name).font(.system(size: 16, weight: .bold)).foregroundColor(.black)
                        if route.isFavorite {
                            Image(systemName: "star.fill").font(.system(size: 11)).foregroundColor(.yellow)
                        }
                    }
                    HStack(spacing: 6) {
                        Text(route.fromStopName).font(.system(size: 13, weight: .medium)).foregroundColor(Color(white: 0.56))
                        Image(systemName: "arrow.right").font(.system(size: 10, weight: .semibold)).foregroundColor(Color(white: 0.56).opacity(0.6))
                        Text(route.toStopName).font(.system(size: 13, weight: .medium)).foregroundColor(Color(white: 0.56))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text(route.durationFormatted).font(.system(size: 15, weight: .bold)).foregroundColor(.black)
                    HStack(spacing: 4) {
                        ForEach(route.lines.prefix(3), id: \.self) { line in
                            LineTag(line: line)
                        }
                    }
                }
            }
            .padding(18)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button { onToggleFavorite() } label: { Label(route.isFavorite ? "Odebrat" : "Oblíbené", systemImage: route.isFavorite ? "star.slash" : "star") }
            Button { onEdit() } label: { Label("Upravit", systemImage: "pencil") }
            Button(role: .destructive) { onDelete() } label: { Label("Smazat", systemImage: "trash") }
        }
    }
}

struct HistoryRouteCard: View {
    let entry: RouteHistoryEntry
    let onTap: () -> Void
    let onSave: () -> Void
    let onReverse: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.97))
                    .frame(width: 52, height: 52)
                    .overlay(Image(systemName: "clock.arrow.circlepath").foregroundColor(Color(white: 0.56)).font(.system(size: 20, weight: .semibold)))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.toStopName).font(.system(size: 15, weight: .semibold)).foregroundColor(.black)
                    Text(formatDate(entry.timestamp)).font(.system(size: 12, weight: .medium)).foregroundColor(Color(white: 0.56))
                }
                Spacer()
                Text(formatDuration(entry.duration)).font(.system(size: 14, weight: .bold)).foregroundColor(Color(white: 0.56))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button { onSave() } label: { Label("Uložit", systemImage: "heart") }
            Button { onReverse() } label: { Label("Opačně", systemImage: "arrow.left.arrow.right") }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: L10n.current == .czech ? "cs" : "en")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct AddRouteSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var persistence = DataPersistence.shared
    @State private var name = ""
    @State private var fromQuery = ""
    @State private var toQuery = ""
    @State private var selectedFromStop: PIDStop?
    @State private var selectedToStop: PIDStop?
    
    var body: some View {
        NavigationView {
            Form {
                Section(L10n.current == .czech ? "Název" : "Name") {
                    TextField("Např. Práce", text: $name)
                }
                Section(L10n.current == .czech ? "Odkud" : "From") {
                    TextField("Hledat...", text: $fromQuery)
                    if !fromQuery.isEmpty {
                        ForEach(StringMatcher.findBestMatches(query: fromQuery, in: ALL_STOPS).map { $0.stop }) { stop in
                            Button { selectedFromStop = stop; fromQuery = stop.name } label: {
                                HStack { Text(stop.name); Spacer(); Text(stop.lines.joined(separator: ", ")).foregroundColor(.secondary).font(.caption) }
                            }
                        }
                    }
                }
                Section(L10n.current == .czech ? "Kam" : "To") {
                    TextField("Hledat...", text: $toQuery)
                    if !toQuery.isEmpty {
                        ForEach(StringMatcher.findBestMatches(query: toQuery, in: ALL_STOPS).map { $0.stop }) { stop in
                            Button { selectedToStop = stop; toQuery = stop.name } label: {
                                HStack { Text(stop.name); Spacer(); Text(stop.lines.joined(separator: ", ")).foregroundColor(.secondary).font(.caption) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nová cesta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zrušit") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uložit") {
                        if let from = selectedFromStop, let to = selectedToStop {
                            persistence.addRouteFromData(name: name, fromStop: from, toStop: to, lines: from.lines + to.lines, duration: 20)
                        }
                        dismiss()
                    }.disabled(name.isEmpty || selectedFromStop == nil || selectedToStop == nil)
                }
            }
        }
    }
}

struct EditRouteSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var persistence = DataPersistence.shared
    let route: SavedRoute
    @State private var name = ""
    @State private var icon = "arrow.right.circle.fill"
    let icons = ["arrow.right.circle.fill", "house.fill", "briefcase.fill", "heart.fill", "star.fill", "building.2.fill", "cart.fill", "tram.fill"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Název") { TextField("", text: $name) }
                Section("Ikona") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(icons, id: \.self) { iconName in
                            Button { icon = iconName } label: {
                                Image(systemName: iconName).font(.system(size: 24)).foregroundColor(icon == iconName ? .cyan : .gray).frame(width: 44, height: 44).background(icon == iconName ? Color.cyan.opacity(0.2) : Color.clear).cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Upravit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zrušit") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uložit") {
                        var updated = route; updated.name = name; updated.icon = icon
                        persistence.updateRoute(updated)
                        dismiss()
                    }
                }
            }
            .onAppear { name = route.name; icon = route.icon }
        }
    }
}

#Preview { SavedScreen().environmentObject(AIEngine()) }
