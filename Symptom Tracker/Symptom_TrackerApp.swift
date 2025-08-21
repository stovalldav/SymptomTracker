//
//  Symptom_TrackerApp.swift
//  Symptom Tracker
//
//  Created by Davis Stovall on 8/18/25.
//
import SwiftUI

@main
struct SymptomTrackerApp: App {
    @StateObject private var dataManager = SymptomDataManager()
    
    var body: some Scene {
        WindowGroup {
            AuthenticationView()
                .environmentObject(dataManager)
        }
    }
}
