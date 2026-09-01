import SwiftUI

struct HealthConnectView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.darkPlum
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(EmberColors.flame)
                        
                        Text("Apple Health")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(EmberColors.cream)
                        
                        Text("Connect to sync your workouts and active energy")
                            .font(.body)
                            .foregroundColor(EmberColors.cream.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    statusCard
                    
                    if healthKitManager.authorizationStatus != .authorized {
                        Button(action: {
                            healthKitManager.requestAuthorization()
                        }) {
                            HStack {
                                Image(systemName: "lock.shield")
                                Text("Request Health Access")
                            }
                            .font(.headline)
                            .foregroundColor(EmberColors.darkPlum)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(EmberColors.flame)
                            )
                        }
                        .padding(.horizontal, 32)
                    }
                    
                    Spacer()
                    
                    infoText
                }
                .padding()
            }
            .navigationTitle("Health Connect")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.darkPlum, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var statusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Authorization Status")
                    .font(.subheadline)
                    .foregroundColor(EmberColors.cream.opacity(0.7))
                
                Spacer()
                
                statusBadge
            }
            
            Divider()
                .background(EmberColors.cream.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workouts")
                        .font(.caption)
                        .foregroundColor(EmberColors.cream.opacity(0.6))
                    Text(healthKitManager.authorizationStatus == .authorized ? "Connected" : "Not Connected")
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Energy")
                        .font(.caption)
                        .foregroundColor(EmberColors.cream.opacity(0.6))
                    Text(healthKitManager.authorizationStatus == .authorized ? "Connected" : "Not Connected")
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
        .padding(.horizontal, 32)
    }
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(EmberColors.cream)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.2))
        )
    }
    
    private var statusColor: Color {
        switch healthKitManager.authorizationStatus {
        case .authorized:
            return Color.green
        case .denied:
            return Color.red
        case .notDetermined:
            return Color.orange
        }
    }
    
    private var statusText: String {
        switch healthKitManager.authorizationStatus {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Determined"
        }
    }
    
    private var infoText: some View {
        VStack(spacing: 8) {
            Text("Your health data stays on your device")
                .font(.caption)
                .foregroundColor(EmberColors.cream.opacity(0.6))
                .multilineTextAlignment(.center)
            
            if healthKitManager.authorizationStatus == .denied {
                Text("To enable access, go to Settings > Health > Data Access & Devices")
                    .font(.caption)
                    .foregroundColor(EmberColors.flame.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}
