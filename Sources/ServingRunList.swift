//
//  ServingRunList.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import os
import SwiftUI

import Compactor

import TrackerLib
import TrackerUI

import DcaltLib
import DcaltUI

// A version that does NOT use Tabler, which doesn't support WatchOS yet.
// This one accesses exclusively in specified store -- mainStore in the watch's case.
struct ServingRunList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter

    // MARK: - Parameters

    private var zDayRun: ZDayRun
    private var inStore: NSPersistentStore

    init(zDayRun: ZDayRun, inStore: NSPersistentStore) {
        self.zDayRun = zDayRun
        self.inStore = inStore

        let predicate = NSPredicate(format: "zDayRun == %@ AND userRemoved != %@", zDayRun, NSNumber(value: true))
        let sortDescriptors = [NSSortDescriptor(keyPath: \ZServingRun.consumedTime, ascending: true)]
        let request = makeRequest(ZServingRun.self,
                                  predicate: predicate,
                                  sortDescriptors: sortDescriptors,
                                  inStore: inStore)

        _servingRuns = FetchRequest<ZServingRun>(fetchRequest: request)
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ServingRunList.self))

    private let columnSpacing: CGFloat = 2

    private var columnPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        // EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
    }

    @FetchRequest private var servingRuns: FetchedResults<ZServingRun>

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 30), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 60), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 20), spacing: columnSpacing, alignment: .trailing),
    ] }

    // MARK: - Views

    var body: some View {
        List {
            header()
                .listItemTint(.accentColor.opacity(0.5))

            ForEach(servingRuns) { servingRun in
                NavigationLink {
                    VStack(spacing: 15) {
                        Text(servingRun.displayConsumedTime)
                        Text(servingRun.zServing?.wrappedName ?? "unknown")
                        Text("\(servingRun.calories) cals")
                    }
                    .navigationTitle {
                        NavTitle("Summary")
                    }
                } label: {
                    listRow(element: servingRun)
                }
            }
            .onDelete(perform: userRemoveAction)
            .listItemTint(Color.accentColor.opacity(0.8))

            Text("Total: \(totalCalories) cals")
                .listItemTint(.accentColor.opacity(0.4))
        }
        .navigationTitle {
            NavTitle("Today")
        }
    }

    private func header() -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Text("Time")
                .padding(columnPadding)
            Text("Name")
                .padding(columnPadding)
            Text("Cals")
        }
    }

    @ViewBuilder
    private func listRow(element: ZServingRun) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Text(element.displayConsumedTime)
                .padding(columnPadding)
            Text(element.zServing?.name ?? "")
                .lineLimit(1)
                .padding(columnPadding)
            Text("\(element.calories)")
        }
    }

    @ViewBuilder
    private func footer() -> some View {
        Text("\(totalCalories) cal")
            .font(.largeTitle)
            .lineLimit(1)
    }

    // MARK: - Properties

    private var totalCalories: Int16 {
        // servingRuns.filter { !$0.userRemoved }.reduce(0) { $0 + $1.calories }
        servingRuns.reduce(0) { $0 + $1.calories }
    }

    // MARK: - Properties

    // MARK: - Actions

    // NOTE: 'removes' matching records, where present, from both mainStore and archiveStore.
    private func userRemoveAction(at offsets: IndexSet) {
        do {
            for index in offsets {
                let zServingRun = servingRuns[index]

                guard let servingArchiveID = zServingRun.zServing?.servingArchiveID,
                      let consumedDay = zServingRun.zDayRun?.consumedDay,
                      let consumedTime = zServingRun.consumedTime
                else { continue }

                try ZServingRun.userRemove(viewContext, servingArchiveID: servingArchiveID, consumedDay: consumedDay, consumedTime: consumedTime)
            }

            // re-total the calories in both stores (may no longer be present in main)
            if let consumedDay = zDayRun.consumedDay {
                refreshTotalCalories(consumedDay: consumedDay, inStore: inStore)
            }

            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    // Re-total the calories for the ZDayRun record, if present in specified store.
    private func refreshTotalCalories(consumedDay: String, inStore: NSPersistentStore) {
        logger.debug("\(#function):")

        // will need to update in both mainStore and mainStore
        guard let dayrun = try? ZDayRun.get(viewContext, consumedDay: consumedDay, inStore: inStore)
        else {
            logger.notice("\(#function): Unable to find ZDayRun record to re-total its calories.")
            return
        }

        dayrun.updateCalories()

        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct ServingRunList_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let store = manager.getMainStore(ctx)!

        let consumedDay1 = "2023-02-01"
        let consumedTime1 = "16:05"

        let category1ArchiveID = UUID()
        let category2ArchiveID = UUID()
        let serving1ArchiveID = UUID()
        let serving2ArchiveID = UUID()

        let zc1 = ZCategory.create(ctx, categoryArchiveID: category1ArchiveID, categoryName: "Fruit", toStore: store)
        let zc2 = ZCategory.create(ctx, categoryArchiveID: category2ArchiveID, categoryName: "Meat", toStore: store)
        let zs1 = ZServing.create(ctx, zCategory: zc1, servingArchiveID: serving1ArchiveID, servingName: "Banana", toStore: store)
        let zs2 = ZServing.create(ctx, zCategory: zc2, servingArchiveID: serving2ArchiveID, servingName: "Steak", toStore: store)
        let zdr = ZDayRun.create(ctx, consumedDay: consumedDay1, calories: 2433, toStore: store)
        _ = ZServingRun.create(ctx, zDayRun: zdr, zServing: zs1, consumedTime: consumedTime1, calories: 120, toStore: store)
        _ = ZServingRun.create(ctx, zDayRun: zdr, zServing: zs2, consumedTime: consumedTime1, calories: 450, toStore: store)
        try? ctx.save()

        return NavigationStack {
            ServingRunList(zDayRun: zdr, inStore: store)
                .environment(\.managedObjectContext, ctx)
                .environmentObject(manager)
        }
    }
}