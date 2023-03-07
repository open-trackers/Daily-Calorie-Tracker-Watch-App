//
//  ContentView.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import SwiftUI

import DcaltLib
import DcaltUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack

    @SceneStorage("main-category-nav") private var categoryNavData: Data?

    var body: some View {
        DcaltNavStack(navData: $categoryNavData, destination: destination) {
            CategoryList()
        }
        .task(priority: .utility, taskAction)
        .onContinueUserActivity(logCategoryActivityType) {
            handleLogCategoryUA(viewContext, $0)
        }
        .onContinueUserActivity(logServingActivityType) {
            handleLogServingUA(viewContext, $0)
        }
    }

    // handle routes for watchOS-specific views here
    @ViewBuilder
    private func destination(_ router: DcaltRouter, _ route: DcaltRoute) -> some View {
        switch route {
        case let .dayRunDetail(dayRunURI):
            servingRunList(dayRunURI)
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        default:
            DcaltDestination(route)
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // NOTE that this is to access servingRun in Main Store (not Archive Store!)
    @ViewBuilder
    private func servingRunList(_ dayRunUri: URL) -> some View {
        if let zDayRun: ZDayRun = ZDayRun.get(viewContext, forURIRepresentation: dayRunUri),
           let mainStore = manager.getMainStore(viewContext)
        {
            ServingRunList(zDayRun: zDayRun, inStore: mainStore)
        } else {
            Text("Serving Run not available.")
        }
    }

    @Sendable
    private func taskAction() async {
        await handleTaskAction(manager)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext

        _ = MCategory.create(ctx, name: "Entrees", userOrder: 0)
        _ = MCategory.create(ctx, name: "Snacks", userOrder: 1)

        try? ctx.save()
        return ContentView()
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
