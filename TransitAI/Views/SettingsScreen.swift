import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject var aiEngine: AIEngine
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var persistence = DataPersistence.shared
    
    @State private var showingHomeStopPicker = false
    @State private var showingWorkStopPicker = false
    @State private var showingContactSupport = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Canvas pozadí - off-white
            Color(hex: "F6F6F6")
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header sekce s velkým názvem
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.settings)
                            .font(.system(size: 34, weight: .black))
                            .foregroundColor(.black)
                        
                        Text(L10n.current == .czech ? "Přizpůsobte si aplikaci" : "Customize your experience")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color(hex: "86868B"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Language Section
                    VStack(spacing: 0) {
                        SectionHeaderModern(title: L10n.current == .czech ? "JAZYK" : "LANGUAGE")
                        
                        VStack(spacing: 0) {
                            LanguagePickerModern()
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 20)
                    
                    // Route Preferences Section
                    VStack(spacing: 0) {
                        SectionHeaderModern(title: L10n.current == .czech ? "PREFERENCE TRAS" : "ROUTE PREFERENCES")
                        
                        VStack(spacing: 0) {
                            ToggleRowModern(
                                title: L10n.current == .czech ? "Preferovat metro" : "Prefer metro",
                                subtitle: L10n.current == .czech ? "Upřednostnit metro před tramvajemi" : "Prioritize metro over trams",
                                icon: "tram.fill",
                                isOn: Binding(
                                    get: { persistence.preferences.preferMetro },
                                    set: { persistence.preferences.preferMetro = $0; persistence.savePreferences() }
                                ),
                                isFirst: true
                            )
                            
                            DividerLine()
                            
                            ToggleRowModern(
                                title: L10n.current == .czech ? "Vyhýbat se autobusům" : "Avoid buses",
                                subtitle: L10n.current == .czech ? "Minimalizovat autobusy" : "Minimize bus usage",
                                icon: "bus.fill",
                                isOn: Binding(
                                    get: { persistence.preferences.avoidBus },
                                    set: { persistence.preferences.avoidBus = $0; persistence.savePreferences() }
                                )
                            )
                            
                            DividerLine()
                            
                            ToggleRowModern(
                                title: L10n.current == .czech ? "Bezbariérový přístup" : "Wheelchair accessible",
                                subtitle: L10n.current == .czech ? "Pouze bezbariérové trasy" : "Only accessible routes",
                                icon: "figure.roll",
                                isOn: Binding(
                                    get: { persistence.preferences.wheelchairAccessible },
                                    set: { persistence.preferences.wheelchairAccessible = $0; persistence.savePreferences() }
                                ),
                                isLast: true
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 20)
                    
                    // Favorite Places Section
                    VStack(spacing: 0) {
                        SectionHeaderModern(title: L10n.current == .czech ? "OBLÍBENÁ MÍSTA" : "FAVORITE PLACES")
                        
                        VStack(spacing: 0) {
                            LocationRowModern(
                                title: L10n.home,
                                icon: "house.fill",
                                location: persistence.preferences.homeStopName ?? (L10n.current == .czech ? "Nenastaveno" : "Not set"),
                                isFirst: true
                            ) {
                                showingHomeStopPicker = true
                            }
                            
                            DividerLine()
                            
                            LocationRowModern(
                                title: L10n.work,
                                icon: "briefcase.fill",
                                location: persistence.preferences.workStopName ?? (L10n.current == .czech ? "Nenastaveno" : "Not set"),
                                isLast: true
                            ) {
                                showingWorkStopPicker = true
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 20)
                    
                    // About Section
                    VStack(spacing: 0) {
                        SectionHeaderModern(title: L10n.current == .czech ? "O APLIKACI" : "ABOUT")
                        
                        VStack(spacing: 0) {
                            InfoRowModern(
                                title: L10n.current == .czech ? "Verze" : "Version",
                                value: "1.0.0 MVP",
                                icon: "app.badge",
                                isFirst: true
                            )
                            
                            DividerLine()
                            
                            InfoRowModern(
                                title: L10n.current == .czech ? "Data PID" : "PID Data",
                                value: "2024/2025",
                                icon: "calendar",
                                isLast: true
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 20)
                    
                    // Actions Section
                    VStack(spacing: 0) {
                        SectionHeaderModern(title: L10n.current == .czech ? "AKCE" : "ACTIONS")
                        
                        VStack(spacing: 0) {
                            ButtonRowModern(
                                title: L10n.current == .czech ? "Vymazat historii" : "Clear history",
                                icon: "trash",
                                isDestructive: true,
                                isFirst: true,
                                isLast: true
                            ) {
                                persistence.clearHistory()
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 20)
                    
                    // Footer padding
                    Color.clear.frame(height: 40)
                }
                .padding(.bottom, 100) // Místo pro tab bar
            }
        }
        .sheet(isPresented: $showingHomeStopPicker) {
            StopPickerSheet(title: L10n.home) { stop in
                persistence.setHomeStop(stop)
            }
        }
        .sheet(isPresented: $showingWorkStopPicker) {
            StopPickerSheet(title: L10n.work) { stop in
                persistence.setWorkStop(stop)
            }
        }
        .alert(L10n.current == .czech ? "Kontakt" : "Contact", isPresented: $showingContactSupport) {
            Button("OK") {}
        } message: {
            Text("support@transitai.cz")
        }
    }
}

// MARK: - Language Picker

struct LanguagePicker: View {
    @StateObject private var persistence = DataPersistence.shared
    @EnvironmentObject var aiEngine: AIEngine
    
    var body: some View {
        HStack {
            ForEach(AppLanguage.allCases, id: \.self) { lang in
                Button {
                    persistence.setLanguage(lang)
                    aiEngine.refreshWelcomeMessage()
                } label: {
                    HStack {
                        Text(lang == .czech ? "🇨🇿" : "🇬🇧")
                            .font(.system(size: 24))
                        Text(lang.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(persistence.preferences.language == lang ? .cyan : .gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(persistence.preferences.language == lang ? Color.cyan.opacity(0.15) : Color(white: 0.12))
                    .overlay(
                        Rectangle().stroke(persistence.preferences.language == lang ? Color.cyan : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Walking Speed Picker

struct WalkingSpeedPicker: View {
    @StateObject private var persistence = DataPersistence.shared
    
    var body: some View {
        HStack {
            Text(L10n.current == .czech ? "Rychlost chůze" : "Walking speed")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            
            Picker("", selection: Binding<UserPreferences.WalkingSpeed>(
                get: { persistence.preferences.walkingSpeed },
                set: { newValue in
                    persistence.preferences.walkingSpeed = newValue
                    persistence.savePreferences()
                }
            )) {
                ForEach(UserPreferences.WalkingSpeed.allCases, id: \.self) { speed in
                    Text(speed.localizedName).tag(speed)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
        .padding(16)
        .overlay(Rectangle().fill(Color.gray.opacity(0.1)).frame(height: 1), alignment: .bottom)
    }
}

// MARK: - Components

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 11)).foregroundColor(.cyan)
                Text(title).font(.system(size: 11, weight: .bold)).tracking(1).foregroundColor(.cyan)
            }
            .padding(.bottom, 12)
            
            VStack(spacing: 0) { content }
                .background(Color(white: 0.1))
                .overlay(Rectangle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
        }
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                Text(subtitle).font(.system(size: 11)).foregroundColor(.gray)
            }
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(.cyan)
        }
        .padding(16)
        .overlay(Rectangle().fill(Color.gray.opacity(0.1)).frame(height: 1), alignment: .bottom)
    }
}

struct StepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        HStack {
            Text(title).font(.system(size: 14, weight: .medium)).foregroundColor(.white)
            Spacer()
            HStack(spacing: 16) {
                Button { if value > range.lowerBound { value -= 1 } } label: {
                    Image(systemName: "minus").font(.system(size: 12, weight: .bold)).foregroundColor(value > range.lowerBound ? .cyan : .gray).frame(width: 32, height: 32).background(Color(white: 0.15))
                }
                Text("\(value)").font(.system(size: 14, weight: .bold)).foregroundColor(.cyan).frame(minWidth: 24)
                Button { if value < range.upperBound { value += 1 } } label: {
                    Image(systemName: "plus").font(.system(size: 12, weight: .bold)).foregroundColor(value < range.upperBound ? .cyan : .gray).frame(width: 32, height: 32).background(Color(white: 0.15))
                }
            }
        }
        .padding(16)
        .overlay(Rectangle().fill(Color.gray.opacity(0.1)).frame(height: 1), alignment: .bottom)
    }
}

struct LocationRow: View {
    let title: String
    let icon: String
    let location: String
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(.cyan).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                    Text(location).font(.system(size: 12)).foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(.gray)
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(Rectangle().fill(Color.gray.opacity(0.1)).frame(height: 1), alignment: .bottom)
    }
}

// MARK: - Modern Components (Premium Design)

struct SectionHeaderModern: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color(hex: "86868B"))
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
    }
}

struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color(hex: "E5E5EA"))
            .frame(height: 0.5)
            .padding(.leading, 60) // Odsazeno od ikony
    }
}

struct LanguagePickerModern: View {
    @StateObject private var persistence = DataPersistence.shared
    @EnvironmentObject var aiEngine: AIEngine
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppLanguage.allCases, id: \.self) { lang in
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    persistence.setLanguage(lang)
                    aiEngine.refreshWelcomeMessage()
                } label: {
                    HStack(spacing: 10) {
                        Text(lang == .czech ? "🇨🇿" : "🇬🇧")
                            .font(.system(size: 28))
                        Text(lang.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(persistence.preferences.language == lang ? .white : .black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(persistence.preferences.language == lang ? Color.black : Color.white)
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(16)
    }
}

struct ToggleRowModern: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    var isFirst: Bool = false
    var isLast: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Ikona vlevo
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 28, height: 28)
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: "86868B"))
            }
            
            Spacer()
            
            // Toggle s černou barvou
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.black)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct LocationRowModern: View {
    let title: String
    let icon: String
    let location: String
    var isFirst: Bool = false
    var isLast: Bool = false
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onEdit()
        }) {
            HStack(spacing: 16) {
                // Ikona vlevo
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 28, height: 28)
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.black)
                    Text(location)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: "86868B"))
                }
                
                Spacer()
                
                // Šipka vpravo
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "C7C7CC"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoRowModern: View {
    let title: String
    let value: String
    let icon: String
    var isFirst: Bool = false
    var isLast: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Ikona vlevo
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 28, height: 28)
            
            // Text
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.black)
            
            Spacer()
            
            // Hodnota vpravo
            Text(value)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color(hex: "86868B"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct ButtonRowModern: View {
    let title: String
    let icon: String
    var isDestructive: Bool = false
    var isFirst: Bool = false
    var isLast: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                // Ikona vlevo
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .black)
                    .frame(width: 28, height: 28)
                
                // Text
                Text(title)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(isDestructive ? .red : .black)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}


struct InfoRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack {
            Text(title).font(.system(size: 14, weight: .medium)).foregroundColor(.white)
            Spacer()
            Text(value).font(.system(size: 14)).foregroundColor(.gray)
        }
        .padding(16)
        .overlay(Rectangle().fill(Color.gray.opacity(0.1)).frame(height: 1), alignment: .bottom)
    }
}

struct FareRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack {
            Text(title).font(.system(size: 14, weight: .medium)).foregroundColor(.white)
            Spacer()
            Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(.cyan)
        }
        .padding(16)
        .overlay(Rectangle().fill(Color.gray.opacity(0.1)).frame(height: 1), alignment: .bottom)
    }
}

struct ButtonRow: View {
    let title: String
    let icon: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(isDestructive ? .red : .cyan)
                Text(title).font(.system(size: 14, weight: .medium)).foregroundColor(isDestructive ? .red : .white)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.gray.opacity(0.5))
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(Rectangle().fill(Color.gray.opacity(0.1)).frame(height: 1), alignment: .bottom)
    }
}

// MARK: - Stop Picker Sheet

struct StopPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let onSelect: (PIDStop) -> Void
    @State private var searchText = ""
    
    var filteredStops: [PIDStop] {
        if searchText.isEmpty { return Array(METRO_STATIONS.prefix(20)) }
        let matches = StringMatcher.findBestMatches(query: searchText, in: METRO_STATIONS, maxResults: 15)
        return matches.map { $0.stop }
    }
    
    var body: some View {
        NavigationView {
            List(filteredStops) { stop in
                Button {
                    onSelect(stop)
                    dismiss()
                } label: {
                    HStack {
                        Text(stop.name).foregroundColor(.primary)
                        Spacer()
                        ForEach(stop.lines, id: \.self) { line in
                            LineTag(line: line)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: L10n.current == .czech ? "Hledat zastávku..." : "Search stop...")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(AIEngine())
        .environmentObject(LocationManager())
}
