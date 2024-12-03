//
//  HealthView.swift
//  gAIns
//
//  Created by Ambika Bhargava on 02/12/24.
//


import SwiftUI

struct HealthView: View {
//    @StateObject private var healthKitManager = HealthKitManager()
    @EnvironmentObject var healthKitManager: HealthKitManager // Observe the shared instance

    @State private var weeklySteps: [CGFloat] = Array(repeating: 0, count: 7) // Default values
    

    var body: some View {
        VStack(spacing: 30) {
            // Circular Progress Bar for Steps
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0.0, to: CGFloat(min(Double(healthKitManager.steps) / 10000.0, 1.0)))
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.easeInOut, value: healthKitManager.steps)

                Text("\(healthKitManager.steps)")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.green)
            }

            // Row for Calories and Distance
            HStack(spacing: 40) {
                VStack {
                    Text("Calories")
                        .font(.headline)
                    Text(String(format: "%.2f kcal", healthKitManager.calories))
                        .font(.title3)
                        .bold()
                }

                VStack {
                    Text("Distance")
                        .font(.headline)
                    Text(String(format: "%.2f km", healthKitManager.distance))
                        .font(.title3)
                        .bold()
                }
            }

            // Weekly Steps Bar Chart
            VStack(alignment: .leading) {
                Text("Weekly Steps")
                    .font(.headline)
                    .padding(.bottom, 10)

                GeometryReader { geometry in
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(weeklySteps.indices, id: \.self) { index in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.green)
                                    .frame(height: geometry.size.height * (weeklySteps[index] / 20000)) // Adjust max value
                                Text(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][index])
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 150)
            }
            .padding(.horizontal)

//            Spacer() // comment out
            
            // Additional Metrics
            VStack(spacing: 15) {
//                HStack {
//                    Text("Flights Climbed:")
//                    Spacer()
//                    Text("\(healthKitManager.flightsClimbed)")
//                        .bold()
//                }

//                HStack {
//                    Text("Audio Exposure:")
//                    Spacer()
//                    Text(String(format: "%.2f dB", healthKitManager.audioExposure))
//                        .bold()
//                }
//
                HStack {
                    Text("Walking Speed:")
                    Spacer()
                    Text(String(format: "%.2f m/s", healthKitManager.walkingSpeed))
                        .bold()
                }
                HStack {
                    Text("Flights Climbed:")
                    Spacer()
                    Text(healthKitManager.flightsClimbed > 0 ? "\(healthKitManager.flightsClimbed)" : "No Data")
                        .bold()
                }

                HStack {
                    Text("Environmental Audio Exposure:")
                    Spacer()
                    Text(healthKitManager.audioExposure > 0 ? String(format: "%.2f dB", healthKitManager.audioExposure) : "No Data")
                        .bold()
                }
                
                VStack(spacing: 15) {
                    // Other metrics like Walking Speed, Flights Climbed, etc.
                    HStack {
                        Text("Headphone Audio Levels:")
                        Spacer()
                        Text(healthKitManager.headphoneAudioLevel > 0 ? String(format: "%.2f dB", healthKitManager.headphoneAudioLevel) : "No Data")
                            .bold()
                    }
                }
                
                
            }
            .padding(.horizontal)
            .padding(.top, 20)

            Spacer()
        }
        .padding()
        .onAppear {
            healthKitManager.fetchHealthData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateWeeklySteps)) { notification in
            if let steps = notification.object as? [CGFloat] {
                weeklySteps = steps
            }
        }
    }
}

extension Notification.Name {
    static let didUpdateWeeklySteps = Notification.Name("didUpdateWeeklySteps")
}
