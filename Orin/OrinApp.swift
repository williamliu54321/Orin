//
//  OrinApp.swift
//  Orin
//
//  Created by William Liu on 2025-09-03.
//

import SwiftUI

@main
struct OrinApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
