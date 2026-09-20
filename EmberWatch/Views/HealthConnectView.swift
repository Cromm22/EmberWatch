import SwiftUI

struct HealthConnectView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    var showsDismissButton: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 80))
                            .foregroundColor(EmberColors.ember)
                            .shadow(color: EmberColors.ember.opacity(0.5), radius: 15)
                        
                        Text("Apple Health")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(EmberColors.cream)
                        
                        Text("Sync Apple Watch workouts, Move calories (Active Energy), and Exercise Minutes")
                            .font(.body)
                            .foregroundColor(EmberColors.muted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    statusCard
                    
                    if healthKitManager.authorizationStatus != .authorized {
                        Button(action: {
                            if healthKitManager.authorizationStatus == .denied {
                                healthKitManager.openHealthSettings()
                            } else {
                                healthKitManager.requestAuthorization()
                            }
                        }) {
                            HStack {
                                Image(systemName: healthKitManager.authorizationStatus == .denied ? "gear" : "lock.shield")
                                Text(healthKitManager.authorizationStatus == .denied ? "Open Health Settings" : "Allow Health Access")
                            }
                            .font(.headline)
                            .foregroundColor(EmberColors.ink)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [EmberColors.ember, EmberColors.gold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            )
                        }
                        .padding(.horizontal, 32)

                        if healthKitManager.authorizationStatus == .denied {
                            Text("Settings → Health → Data Access & Devices → EmberWatch → enable Workouts, Active Energy, and Exercise Minutes")
                                .font(.caption)
                                .foregroundColor(EmberColors.muted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    } else {
                        Button(action: {
                            healthKitManager.fetchTodayWorkouts(markAccessFromResult: true)
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh Watch Data")
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
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if showsDismissButton {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                            .foregroundColor(EmberColors.ember)
                    }
                }
            }
            .onAppear {
                if healthKitManager.authorizationStatus == .authorized {
                    healthKitManager.fetchTodayWorkouts(markAccessFromResult: true)
                }
            }
        }
    }
    
    private var statusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Authorization Status")
                    .font(.subheadline)
                    .foregroundColor(EmberColors.muted)
                
                Spacer()
                
                statusBadge
            }
            
            Divider()
                .background(EmberColors.plum)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workouts")
                        .font(.caption)
                        .foregroundColor(EmberColors.muted)
                    Text(connectedLabel)
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Energy")
                        .font(.caption)
                        .foregroundColor(EmberColors.muted)
                    Text(connectedLabel)
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exercise")
                        .font(.caption)
                        .foregroundColor(EmberColors.muted)
                    Text(connectedLabel)
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream)
                }
            }
            
            if healthKitManager.authorizationStatus == .authorized {
                Divider()
                    .background(EmberColors.plum)
                HStack {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(EmberColors.muted)
                    Spacer()
                    Text("\(Int(healthKitManager.totalCaloriesBurned)) cal · \(Int(healthKitManager.exerciseMinutes)) min · \(healthKitManager.workouts.count) workouts")
                        .font(.caption)
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
    
    private var connectedLabel: String {
        healthKitManager.authorizationStatus == .authorized ? "Connected" : "Not Connected"
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
                .foregroundColor(EmberColors.muted)
                .multilineTextAlignment(.center)
            
            if healthKitManager.authorizationStatus == .denied {
                Text("To enable access, go to Settings > Health > Data Access & Devices")
                    .font(.caption)
                    .foregroundColor(EmberColors.ember.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}
