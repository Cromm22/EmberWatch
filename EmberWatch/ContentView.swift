import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "flame.fill")
                }
                .tag(0)
            
            HealthConnectView()
                .tabItem {
                    Label("Health", systemImage: "heart.fill")
                }
                .tag(1)
        }
        .accentColor(EmberColors.flame)
    }
}

struct EmberColors {
    static let darkPlum = Color(red: 0.3, green: 0.2, blue: 0.35)
    static let cream = Color(red: 0.98, green: 0.95, blue: 0.9)
    static let flame = Color(red: 1.0, green: 0.45, blue: 0.2)
    static let lightPlum = Color(red: 0.4, green: 0.3, blue: 0.45)
}
