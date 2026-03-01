# TransitAI - Prague Public Transport for iPhone

> **Proof of Concept** -- A native iOS app that helps you navigate Prague's public transport using an AI chatbot. This is a personal side project I'm building in my free time. Still very much a work in progress!

## What is this?

TransitAI is an iPhone app for Prague public transport (PID) with a conversational AI interface. Instead of clicking through menus, just type or say where you want to go -- in Czech or English -- and the app figures out the best route for you.

**This is a PoC / early MVP.** Things may be rough around the edges. Transit data is currently static (demo data), and live API integration is planned for the future.

## Features

- **AI Chat** -- Ask for routes in natural language, with typo tolerance and Czech diacritics handling
- **Voice Commands** -- Speak in Czech (cs-CZ) to get directions hands-free
- **Route Map** -- Visual route display with polylines and stop markers colored by line type
- **Nearby Stops** -- See stops around your current location with departure info
- **Saved Routes** -- Favorite routes, recent history, reverse direction
- **Bilingual** -- Czech and English UI
- **Settings** -- Route preferences (prefer metro, avoid buses), home/work shortcuts, fare prices

## Tech Stack

- **SwiftUI** (iOS 17+)
- **MapKit** + **CoreLocation**
- **Speech Framework** (Czech voice recognition)
- **Zero external dependencies** -- Apple frameworks only

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Clone this repo
2. Open `TransitAI.xcodeproj` in Xcode
3. Select a simulator or connected device
4. `Cmd + R` to build and run

## Project Structure

```
TransitAI/
├── TransitAIApp.swift          # App entry point
├── ContentView.swift           # Main tab navigation + chat input
├── Views/
│   ├── ChatScreen.swift        # AI chat interface
│   ├── NearbyStopsScreen.swift # Nearby stops & map
│   ├── SavedScreen.swift       # Saved routes & history
│   ├── SettingsScreen.swift    # Preferences
│   ├── MapView.swift           # Reusable map component
│   ├── RouteModal.swift        # Route detail modal
│   └── SharedComponents.swift  # Reusable UI components
├── Models/
│   ├── TransitData.swift       # Core data structures (stops, routes, lines)
│   └── StringMatcher.swift     # Fuzzy text matching (Levenshtein + phonetic)
├── Services/
│   ├── AIEngine.swift          # NLP parsing, route calculation, intent detection
│   ├── LocationManager.swift   # GPS location handling
│   ├── SpeechRecognizer.swift  # Czech voice recognition
│   └── DataPersistence.swift   # Local storage (UserDefaults)
└── Assets.xcassets/
```

## Status

This is a **proof of concept** and a **work in progress**. Current limitations:

- Static transit data (no live departures yet)
- Demo routing (real PID API integration planned)
- Not yet tested extensively on physical devices
- Not submitted to the App Store

## License

This project is for personal/educational use.
