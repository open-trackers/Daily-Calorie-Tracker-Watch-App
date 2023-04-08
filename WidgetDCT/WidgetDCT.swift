//
//  WidgetDCT.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI
import WidgetKit

import Compactor
import DcaltLib

struct WidgetDCTEntryView: View {
    var entry: Provider.Entry // not used

    static let tc = NumberCompactor(ifZero: "0", roundSmallToWhole: true)

    var body: some View {
        ProgressView(value: percent) {
            Text("\(Self.tc.string(from: remaining as NSNumber) ?? "")")
                .foregroundColor(remaining >= 0 ? .primary : .red)
                .padding()
                .font(.headline.bold())
//                .font(.system(size: 500))
//                .minimumScaleFactor(0.01)
        }
        .progressViewStyle(.circular)
        .tint(.accentColor)
    }

    private var remaining: Int {
        target - current // may be negative
    }

    private var current: Int {
        userDefault(.currentCalories)
    }

    private var target: Int {
        userDefault(.targetCalories)
    }

    private func userDefault(_ key: UserDefaults.Keys) -> Int {
        UserDefaults.appGroup.integer(forKey: key.rawValue)
    }

    private var percent: Float {
        guard target > 0 else { return 0 }
        return Float(current) / Float(target)
    }
}

@main
struct WidgetDCT: Widget {
    let kind: String = "WidgetDCT"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetDCTEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Calories")
        .description("Show progress towards your daily goal.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in _: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), targetCalories: 2000, currentCalories: 1200)
    }

    func getSnapshot(in _: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), targetCalories: 2000, currentCalories: 700)
        completion(entry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate,
                                targetCalories: UserDefaults.appGroup.integer(forKey: UserDefaults.Keys.targetCalories.rawValue),
                                currentCalories: UserDefaults.appGroup.integer(forKey: UserDefaults.Keys.currentCalories.rawValue))
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let targetCalories: Int
    let currentCalories: Int
}

struct WidgetDCT_Previews: PreviewProvider {
    static var previews: some View {
        UserDefaults.appGroup.set(2000, forKey: UserDefaults.Keys.targetCalories.rawValue)
        UserDefaults.appGroup.set(500, forKey: UserDefaults.Keys.currentCalories.rawValue)
        return WidgetDCTEntryView(entry: SimpleEntry(date: Date(), targetCalories: 2000, currentCalories: 500))
            .accentColor(.blue)
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
