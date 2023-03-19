//
//  WatchTodayDayRun.swift
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

import DcaltLib
import DcaltUI
import TrackerUI

import SwiftUI

struct WatchTodayDayRun: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter
    @EnvironmentObject private var manager: CoreDataStack

//    private static let df: DateFormatter = {
//        let df = DateFormatter()
//        df.dateStyle = .medium
//        df.timeStyle = .none
//        return df
//    }()

    var body: some View {
        VStack {
            if let mainStore = manager.getMainStore(viewContext) {
                TodayDayRun(mainStore: mainStore) { zDayRun, _ in
                    ServingRunList(zDayRun: zDayRun, mainStore: mainStore)
                    // .navigationTitle(Self.df.string(from: dateVal))
                }
            } else {
                Text("Recent data not available.")
            }
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WatchTodayDayRun_Previews: PreviewProvider {
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
            WatchTodayDayRun()
        }
        .environment(\.managedObjectContext, ctx)
        .environmentObject(manager)
    }
}
