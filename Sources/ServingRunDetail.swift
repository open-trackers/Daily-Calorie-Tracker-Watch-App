//
//  ServingRunDetail.swift
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

struct ServingRunDetail: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter
    @EnvironmentObject private var manager: CoreDataStack

    // MARK: - Parameters

    var zServingRun: ZServingRun

    // MARK: - Locals

    private static let df: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    // MARK: - Views

    var body: some View {
        Form {
            Section("Name") {
                Text(zServingRun.zServing?.wrappedName ?? "unknown")
            }

            Section("Calories") {
                Text("\(zServingRun.calories) cal (\(percent, specifier: "%0.0f")%)")
            }

            Section("Consumed At") {
                Text(formattedConsumedDate)
            }
        }
        .navigationTitle {
            NavTitle("Serving")
        }
    }

    private var formattedConsumedDate: String {
        guard let consumedDate else { return "unknown" }
        return Self.df.string(from: consumedDate)
    }

    private var consumedDate: Date? {
        guard let consumedDay = zServingRun.zDayRun?.consumedDay,
              let consumedTime = zServingRun.consumedTime
        else { return nil }
        return mergeDateLocal(dateStr: consumedDay, timeStr: consumedTime)
    }

    private var totalCalories: Int16 {
        zServingRun.zDayRun?.calories ?? 0
    }

    private var percent: Float {
        guard totalCalories > 0 else { return 0 }
        return Float(zServingRun.calories) / Float(totalCalories) * 100
    }
}

struct ServingRunDetail_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let mainStore = manager.getMainStore(ctx)!

        let consumedDay1 = "2023-02-01"
        let consumedTime1 = "16:05"

        let category1ArchiveID = UUID()
        let serving1ArchiveID = UUID()

        let zc1 = ZCategory.create(ctx, categoryArchiveID: category1ArchiveID, categoryName: "Fruit", toStore: mainStore)
        let zs1 = ZServing.create(ctx, zCategory: zc1, servingArchiveID: serving1ArchiveID, servingName: "Banana and Peaches and Plums cooked slowly over several hours", toStore: mainStore)
        let zdr = ZDayRun.create(ctx, consumedDay: consumedDay1, calories: 2433, toStore: mainStore)
        let zsr = ZServingRun.create(ctx, zDayRun: zdr, zServing: zs1, consumedTime: consumedTime1, calories: 1230, toStore: mainStore)

        return NavigationStack {
            ServingRunDetail(zServingRun: zsr)
                .environment(\.managedObjectContext, ctx)
                .environmentObject(manager)
        }
    }
}
