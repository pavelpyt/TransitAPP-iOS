import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .chat
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var aiEngine: AIEngine
    
    enum Tab: String, CaseIterable {
        case chat = "Chat"
        case nearby = "Okolí"
        case saved = "Cesty"
        case settings = "Nastavení"
        
        var icon: String {
            switch self {
            case .chat: return "message.fill"
            case .nearby: return "mappin.and.ellipse"
            case .saved: return "heart.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Pozadí přes celou obrazovku včetně safe area
                Color(hex: "F6F6F6")
                    .ignoresSafeArea()
                
                // Main Content
                VStack(spacing: 0) {
                    Group {
                        switch selectedTab {
                        case .chat:
                            ChatScreen()
                        case .nearby:
                            NearbyStopsScreen()
                        case .saved:
                            SavedScreen()
                        case .settings:
                            SettingsScreen()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Quick Actions - Pouze pro Chat tab
                if selectedTab == .chat {
                    VStack {
                        Spacer()
                        quickActionsView
                            .padding(.bottom, 160) // Výš nad searchbarem
                    }
                    .zIndex(50) // Pod searchbarem, ale nad obsahem
                }
                
                // Chat Input Box (pouze pro Chat tab) - OVERLAY
                if selectedTab == .chat {
                    VStack {
                        Spacer()
                        chatInputBox
                            .offset(y: keyboardHeight > 0 ? -(keyboardHeight + geometry.safeAreaInsets.bottom - 7) : -(90 + geometry.safeAreaInsets.bottom - 20))
                            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
                    }
                    .zIndex(100) // Nad obsahem, ale pod quick actions
                }
                
                // Bottom Navigation (Floating Tab Bar) - VŽDY NAHOŘE
                VStack {
                    Spacer()
                    bottomNavigation
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 14)
                }
                .zIndex(999) // Nejvyšší z-index!
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            locationManager.requestPermission()
            setupKeyboardObservers()
        }
        .onChange(of: speechRecognizer.transcript) { _, newValue in
            if !newValue.isEmpty && !speechRecognizer.isRecording {
                inputText = newValue
                sendChatMessage()
            }
        }
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }
    
    private var bottomNavigation: some View {
        VStack(spacing: 0) {
            // Samotný tab bar
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        // Haptic feedback
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    } label: {
                        Image(systemName: tab.icon)
                            .font(.system(size: 24, weight: selectedTab == tab ? .semibold : .regular))
                            .symbolRenderingMode(.monochrome)
                            .foregroundColor(selectedTab == tab ? .black : Color(hex: "86868B"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 35, x: 0, y: -8)
            .padding(.horizontal, 16)
            // Gradient fade pod tab barem (skutečný přechod do pozadí)
            .background(
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [
                            Color(hex: "F6F6F6").opacity(0),
                            Color(hex: "F6F6F6").opacity(0.5),
                            Color(hex: "F6F6F6").opacity(0.85),
                            Color(hex: "F6F6F6")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                    .offset(y: 56) // Posune gradient pod tab bar
                    
                    Color(hex: "F6F6F6")
                        .frame(height: 50)
                        .offset(y: 56)
                }
                , alignment: .top
            )
        }
    }
    
    // MARK: - Chat Input Box (Hero Element - 56px high)
    
    private var chatInputBox: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Hlavní vyhledávací pole
                HStack(spacing: 14) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(hex: "86868B"))
                        .font(.system(size: 20, weight: .semibold))
                    
                    TextField(
                        L10n.current == .czech ? "Kam jedeme?" : "Where to?",
                        text: $inputText,
                        axis: .vertical
                    )
                    .foregroundColor(.black)
                    .font(.system(size: 17, weight: .regular))
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit { sendChatMessage() }
                    .autocorrectionDisabled()
                    .lineLimit(1...3)
                    
                    if !inputText.isEmpty {
                        Button {
                            inputText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(hex: "86868B"))
                                .font(.system(size: 20))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(minHeight: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                )
                .shadow(
                    color: isInputFocused ? Color.black.opacity(0.1) : Color.black.opacity(0.08), 
                    radius: isInputFocused ? 30 : 25, 
                    x: 0, 
                    y: isInputFocused ? 12 : 10
                )
                
                // Mikrofon tlačítko
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    speechRecognizer.toggleRecording()
                } label: {
                    Image(systemName: speechRecognizer.isRecording ? "mic.slash.fill" : "mic.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(speechRecognizer.isRecording ? .white : .black)
                        .frame(width: 56, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(speechRecognizer.isRecording ? Color.red : Color.white)
                        )
                        .shadow(
                            color: speechRecognizer.isRecording ? Color.red.opacity(0.25) : Color.black.opacity(0.08), 
                            radius: speechRecognizer.isRecording ? 25 : 25, 
                            x: 0, 
                            y: 10
                        )
                }
                .disabled(!speechRecognizer.isAuthorized)
                .buttonStyle(ScaleButtonStyle())
                
                // Send tlačítko (Primární akce - černé)
                Button { 
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    sendChatMessage() 
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(inputText.isEmpty ? Color(hex: "86868B") : .white)
                        .frame(width: 56, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(inputText.isEmpty ? Color(hex: "E5E5EA") : Color.black)
                        )
                        .shadow(
                            color: inputText.isEmpty ? Color.black.opacity(0.05) : Color.black.opacity(0.18), 
                            radius: inputText.isEmpty ? 20 : 30, 
                            x: 0, 
                            y: inputText.isEmpty ? 8 : 12
                        )
                }
                .disabled(inputText.isEmpty || aiEngine.isProcessing)
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(hex: "F6F6F6"))
        }
    }
    
    private func sendChatMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let message = inputText
        inputText = ""
        isInputFocused = false
        
        Task {
            await aiEngine.sendMessage(message)
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Home button
                QuickActionButton(icon: "house.fill", label: L10n.home) {
                    Task {
                        let homeName = DataPersistence.shared.preferences.homeStopName ?? "Chodov"
                        await aiEngine.sendMessage(homeName)
                        if selectedTab != .chat {
                            selectedTab = .chat
                        }
                    }
                }
                
                // Work button
                QuickActionButton(icon: "briefcase.fill", label: L10n.work) {
                    Task {
                        let workName = DataPersistence.shared.preferences.workStopName ?? "Dejvická"
                        await aiEngine.sendMessage(workName)
                        if selectedTab != .chat {
                            selectedTab = .chat
                        }
                    }
                }
                
                // Recent routes
                ForEach(DataPersistence.shared.recentRoutes.prefix(2)) { entry in
                    QuickActionButton(icon: "clock.fill", label: entry.toStopName) {
                        Task {
                            await aiEngine.sendMessage(entry.toStopName)
                            if selectedTab != .chat {
                                selectedTab = .chat
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Design System Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Scale Button Style (95% scale on press)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(.black)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(AIEngine())
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(AIEngine())
}
