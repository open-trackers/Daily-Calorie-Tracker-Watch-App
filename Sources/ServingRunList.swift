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
    @EnvironmentObject private var manager: CoreDataStack

    // MARK: - Parameters

    private var zDayRun: ZDayRun

    init(zDayRun: ZDayRun, mainStore: NSPersistentStore) {
        self.zDayRun = zDayRun

        let predicate = ZServingRun.getPredicate(zDayRun: zDayRun, userRemoved: false)
        let sortDescriptors = ZServingRun.byConsumedTime(ascending: true)
        let request = makeRequest(ZServingRun.self,
                                  predicate: predicate,
                                  sortDescriptors: sortDescriptors,
                                  inStore: mainStore)

        _servingRuns = FetchRequest<ZServingRun>(fetchRequest: request)
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ServingRunList.self))

    private let columnSpacing: CGFloat = 0

    private var columnPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    @FetchRequest private var servingRuns: FetchedResults<ZServingRun>

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 120), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 20, maximum: 50), spacing: columnSpacing, alignment: .trailing),
    ] }

    private static let nc = NumberCompactor(ifZero: nil)

    // MARK: - Views

    var body: some View {
        List {
            ForEach(servingRuns) { element in
                Button(action: { detailAction(element) }) {
                    listRow(element: element)
                }
            }
            .onDelete(perform: userRemoveAction)
//            .listItemTint(Color.accentColor.opacity(0.8))

            Text("Total: \(totalCalories) cal")
                .listItemTint(.accentColor.opacity(0.2))
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func listRow(element: ZServingRun) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: 0) {
            Text(element.zServing?.name ?? "")
                .lineLimit(3)
                .foregroundStyle(servingColorDarkBg)
            Text("\(Self.nc.string(from: element.calories as NSNumber) ?? "")")
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

    private func detailAction(_ element: ZServingRun) {
        router.path.append(.servingRunDetail(element.uriRepresentation))
    }

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
            if let mainStore = manager.getMainStore(viewContext) {
                // NOTE: this (re-)sums the day's total calories, as well as update the widget
                WidgetEntry.refresh(viewContext,
                                    inStore: mainStore,
                                    reload: true,
                                    defaultColor: .accentColor)
            }

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
        let zs1 = ZServing.create(ctx, zCategory: zc1, servingArchiveID: serving1ArchiveID, servingName: "Banana and Peaches and Pears and whatnot", toStore: store)
        let zs2 = ZServing.create(ctx, zCategory: zc2, servingArchiveID: serving2ArchiveID, servingName: "Steak and fritos and kiwis", toStore: store)
        let zdr = ZDayRun.create(ctx, consumedDay: consumedDay1, calories: 2433, toStore: store)
        _ = ZServingRun.create(ctx, zDayRun: zdr, zServing: zs1, consumedTime: consumedTime1, calories: 2120, toStore: store)
        _ = ZServingRun.create(ctx, zDayRun: zdr, zServing: zs2, consumedTime: consumedTime1, calories: 6450, toStore: store)
        try? ctx.save()

        return NavigationStack {
            ServingRunList(zDayRun: zdr, mainStore: store)
                .environment(\.managedObjectContext, ctx)
                .environmentObject(manager)
        }
    }
}
