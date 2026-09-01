import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.darkPlum
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        caloriesSummaryCard

                        if healthKitManager.authorizationStatus == .authorized {
                            Button(action: sendToEmber) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Send calories to Ember")
                                        .fontWeight(.semibold)
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
                        }
                        
                        if healthKitManager.workouts.isEmpty && !healthKitManager.isLoading {
                            emptyStateView
                        } else {
                            workoutsList
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.darkPlum, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                healthKitManager.fetchTodayWorkouts(markAccessFromResult: true)
            }
            .refreshable {
                healthKitManager.fetchTodayWorkouts(markAccessFromResult: true)
            }
        }
    }
    
    private var caloriesSummaryCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundColor(EmberColors.flame)
            
            if healthKitManager.isLoading {
                ProgressView()
                    .tint(EmberColors.cream)
            } else {
                Text("\(Int(healthKitManager.totalCaloriesBurned))")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(EmberColors.cream)
                
                Text("calories burned today")
                    .font(.subheadline)
                    .foregroundColor(EmberColors.cream.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(EmberColors.lightPlum)
        )
    }
    
    private var workoutsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workouts")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(EmberColors.cream)
                .padding(.horizontal, 4)
            
            ForEach(healthKitManager.workouts) { workout in
                WorkoutRow(workout: workout)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 60))
                .foregroundColor(EmberColors.cream.opacity(0.5))
            
            Text("No workouts today")
                .font(.title3)
                .foregroundColor(EmberColors.cream.opacity(0.7))
            
            Text("Your workouts will appear here")
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.5))
        }
        .padding(.top, 40)
    }

    private func sendToEmber() {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        let day = formatter.string(from: Date())

        let list = healthKitManager.workouts
        var workouts: [[String: Any]] = []
        for w in list {
            workouts.append([
                "id": w.id.uuidString,
                "name": w.displayName,
                "minutes": max(1, Int((w.duration / 60.0).rounded())),
                "kcal": Int(w.caloriesBurned.rounded()),
                "at": Int(w.startDate.timeIntervalSince1970 * 1000),
            ])
        }

        let payload: [String: Any] = [
            "day": day,
            "workouts": workouts,
        ]

        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else { return }

        let encoded = Data(json.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        var comps = URLComponents(string: "https://ember-teal-six.vercel.app/health")!
        comps.queryItems = [URLQueryItem(name: "watch", value: encoded)]
        guard let url = comps.url else { return }
        UIApplication.shared.open(url)
    }
}


struct WorkoutRow: View {
    let workout: WorkoutData
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: workout.iconName)
                .font(.title2)
                .foregroundColor(EmberColors.flame)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(EmberColors.lightPlum)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.displayName)
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                
                HStack(spacing: 16) {
                    Label(workout.formattedDuration, systemImage: "clock")
                    Label("\(Int(workout.caloriesBurned)) cal", systemImage: "flame.fill")
                }
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.7))
            }
            
            Spacer()
            
            Text(workout.formattedStartTime)
                .font(.caption)
                .foregroundColor(EmberColors.cream.opacity(0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
    }
}
