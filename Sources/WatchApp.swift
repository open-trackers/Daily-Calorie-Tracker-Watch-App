//
//  WatchApp.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import os
import SwiftUI

import DcaltLib
import TrackerLib

@main
struct Daily_Calorie_Tracker_Watch_App: App {
    @Environment(\.scenePhase) var scenePhase

    // MARK: - Locals

    private let persistenceManager = CoreDataStack(isCloud: true)

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "App"
    )

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                             persistenceManager.container.viewContext)
                .environmentObject(persistenceManager)
        }
        .onChange(of: scenePhase) { _ in
            // save if: (1) app moved to background, and (2) changes are pending
            do {
                try persistenceManager.container.viewContext.save()
            } catch {
                logger.error("\(#function): \(error.localizedDescription)")
            }
        }
    }
}
