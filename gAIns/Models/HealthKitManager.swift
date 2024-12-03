//
//  HealthKitManager.swift
//  gAIns
//
//  Created by Ambika Bhargava on 02/12/24.
//



import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var steps: Int = 0
    @Published var calories: Double = 0.0
    @Published var distance: Double = 0.0
    @Published var flightsClimbed: Int = 0
    @Published var audioExposure: Double = 0.0
    @Published var walkingSpeed: Double = 0.0
    @Published var headphoneAudioLevel: Double = 0.0
    
    
    
    init() {
        requestAuthorization()
        fetchHealthData()
    }
    
//    private func requestAuthorization() {
//        // Specify the types to share and read
//        let typesToShare: Set<HKSampleType> = []
//        let typesToRead: Set<HKSampleType> = [
//            HKObjectType.quantityType(forIdentifier: .stepCount)!,
//            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
//            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
//        ]
//        
//        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
//            if !success {
//                print("HealthKit authorization failed: \(String(describing: error))")
//            }
//        }
//    }
    
//    private func requestAuthorization() {
//        // Specify the types to share and read
//        let typesToShare: Set<HKSampleType> = []
//        let typesToRead: Set<HKSampleType> = [
//            HKObjectType.quantityType(forIdentifier: .stepCount)!,
//            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
//            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
////            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
////            HKObjectType.quantityType(forIdentifier: .environmentalAudioExposure)!,
////            HKObjectType.quantityType(forIdentifier: .walkingSpeed)!
//        ]
//
//        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
//            if success {
//                print("HealthKit authorization granted.")
//            } else {
//                print("HealthKit authorization failed: \(String(describing: error))")
//            }
//        }
//    }
    
    private func requestAuthorization() {
        // Specify the types to share and read
        let typesToShare: Set<HKSampleType> = []
        let typesToRead: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
            HKObjectType.quantityType(forIdentifier: .environmentalAudioExposure)!,
            HKObjectType.quantityType(forIdentifier: .headphoneAudioExposure)!, // Replacing Audio Exposure
            HKObjectType.quantityType(forIdentifier: .walkingSpeed)!
        ]

        // Request authorization
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("HealthKit authorization granted.")
                    // Fetch data after authorization
                    self.fetchHealthData()
                } else {
                    print("HealthKit authorization failed: \(String(describing: error))")
                    // Handle denial or error here if needed
                }
            }
        }
    }
//    func fetchHealthData() {
//        fetchSteps()
//        fetchCalories()
//        fetchDistance()
//    }
    
    
    func fetchHealthData() {
        fetchSteps()
        fetchCalories()
        fetchDistance()
        fetchHeadphoneAudioLevels() // Replaces fetchAudioExposure

        
        // Fetch weekly steps
        fetchWeeklySteps { steps in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didUpdateWeeklySteps, object: steps)
            }
        }
        
        fetchFlightsClimbed()
        fetchAudioExposure()
        fetchWalkingSpeed()
    }

    private func fetchSteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        fetchQuantityData(for: stepType) { steps in
            DispatchQueue.main.async {
                self.steps = Int(steps)
            }
        }
    }
    
    private func fetchCalories() {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        fetchQuantityData(for: calorieType) { calories in
            DispatchQueue.main.async {
                self.calories = calories
            }
        }
    }
    
    private func fetchDistance() {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        fetchQuantityData(for: distanceType) { distance in
            DispatchQueue.main.async {
                self.distance = distance / 1000.0 // Convert meters to kilometers
            }
        }
    }
    
    private func fetchQuantityData(for type: HKQuantityType, completion: @escaping (Double) -> Void) {
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            
            // Use the correct unit for each type
            let unit: HKUnit
            switch type.identifier {
            case HKQuantityTypeIdentifier.stepCount.rawValue:
                unit = HKUnit.count()
            case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                unit = HKUnit.kilocalorie()
            case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                unit = HKUnit.meter()
            default:
                print("Unknown type: \(type.identifier)")
                completion(0)
                return
            }
            
            // Convert the result to the correct unit
            completion(sum.doubleValue(for: unit))
        }
        
        healthStore.execute(query)
    }
    
    
    private func fetchWeeklySteps(completion: @escaping ([CGFloat]) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: now) else { return } // 7 days ago
        
        var interval = DateComponents()
        interval.day = 1 // Daily intervals
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: calendar.startOfDay(for: now),
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { _, results, error in
            guard let results = results else {
                print("Failed to fetch weekly steps: \(String(describing: error))")
                completion(Array(repeating: 0, count: 7)) // Default to zeros if no data
                return
            }
            
            var steps: [CGFloat] = []
            results.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let stepCount = sum.doubleValue(for: HKUnit.count())
                    steps.append(CGFloat(stepCount))
                } else {
                    steps.append(0) // No data for this day
                }
            }
            
            DispatchQueue.main.async {
                completion(steps)
            }
        }
        
        healthStore.execute(query)
    }
    
    
//    private func fetchFlightsClimbed() {
//        guard let type = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else { return }
//        fetchQuantityData(for: type) { value in
//            DispatchQueue.main.async {
//                self.flightsClimbed = Int(value)
//            }
//        }
//    }
    
    private func fetchFlightsClimbed() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else { return }

        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    self.flightsClimbed = 0 // Set to 0 if no data
                }
                return
            }

            DispatchQueue.main.async {
                self.flightsClimbed = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }

        healthStore.execute(query)
    }

//    private func fetchAudioExposure() {
//        guard let type = HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure) else { return }
//        fetchQuantityData(for: type) { value in
//            DispatchQueue.main.async {
//                self.audioExposure = value // Value is in decibels
//            }
//        }
//    }

//    private func fetchAudioExposure() {
//        guard let type = HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure) else { return }
//
//        let startDate = Calendar.current.startOfDay(for: Date())
//        let endDate = Date()
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
//        
//        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
//            guard let results = results as? [HKQuantitySample] else {
//                print("Failed to fetch audio exposure data: \(String(describing: error))")
//                DispatchQueue.main.async {
//                    self.audioExposure = 0 // Default to 0 if no data
//                }
//                return
//            }
//
//            // Calculate the average audio exposure in dB
//            let totalExposure = results.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.decibelAWeightedSoundPressureLevel()) }
//            let averageExposure = totalExposure / Double(results.count)
//
//            DispatchQueue.main.async {
//                self.audioExposure = averageExposure
//            }
//        }
//        
//        healthStore.execute(query)
//    }
    
    private func fetchAudioExposure() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure) else { return }

        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            guard let results = results as? [HKQuantitySample], !results.isEmpty else {
                DispatchQueue.main.async {
                    self.audioExposure = 0.0 // Set to 0 if no data
                }
                return
            }

            // Calculate the average audio exposure
            let totalExposure = results.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.decibelAWeightedSoundPressureLevel()) }
            let averageExposure = totalExposure / Double(results.count)

            DispatchQueue.main.async {
                self.audioExposure = averageExposure
            }
        }

        healthStore.execute(query)
    }
//    private func fetchWalkingSpeed() {
//        guard let type = HKQuantityType.quantityType(forIdentifier: .walkingSpeed) else { return }
//        fetchQuantityData(for: type) { value in
//            DispatchQueue.main.async {
//                self.walkingSpeed = value // Value is in meters/second
//            }
//        }
//    }

    
    private func fetchWalkingSpeed() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .walkingSpeed) else { return }

        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            guard let results = results as? [HKQuantitySample] else {
                print("Failed to fetch walking speed data: \(String(describing: error))")
                DispatchQueue.main.async {
                    self.walkingSpeed = 0.0 // Default to 0 if no data
                }
                return
            }

            // Calculate the average walking speed in meters/second
            let totalSpeed = results.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.meter().unitDivided(by: HKUnit.second())) }
            let averageSpeed = totalSpeed / Double(results.count)

            DispatchQueue.main.async {
                self.walkingSpeed = averageSpeed
            }
        }
        
        healthStore.execute(query)
    }
    
//    private func fetchHeadphoneAudioLevels() {
//        guard let type = HKQuantityType.quantityType(forIdentifier: .headphoneAudioExposure) else { return }
//
//        let startDate = Calendar.current.startOfDay(for: Date())
//        let endDate = Date()
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
//
//        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
//            guard let results = results as? [HKQuantitySample], !results.isEmpty else {
//                DispatchQueue.main.async {
//                    self.audioExposure = 0.0 // Default to 0 if no data
//                }
//                return
//            }
//
//            // Calculate the average headphone audio level
//            let totalExposure = results.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.decibelAWeightedSoundPressureLevel()) }
//            let averageExposure = totalExposure / Double(results.count)
//
//            DispatchQueue.main.async {
//                self.audioExposure = averageExposure
//            }
//        }
//
//        healthStore.execute(query)
//    }
    
    private func fetchHeadphoneAudioLevels() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .headphoneAudioExposure) else { return }

        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            guard let results = results as? [HKQuantitySample], !results.isEmpty else {
                DispatchQueue.main.async {
                    self.headphoneAudioLevel = 0.0 // Default to 0 if no data
                }
                return
            }

            // Calculate the average headphone audio level
            let totalExposure = results.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.decibelAWeightedSoundPressureLevel()) }
            let averageExposure = totalExposure / Double(results.count)

            DispatchQueue.main.async {
                self.headphoneAudioLevel = averageExposure
            }
        }

        healthStore.execute(query)
    }
    
    
    
    
}
