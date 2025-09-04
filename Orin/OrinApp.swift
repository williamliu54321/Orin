//
//  OrinApp.swift
//  Orin
//
//  Created by William Liu on 2025-09-03.
//

import SwiftUI
import SuperwallKit
import FirebaseCore

@main
struct OrinApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        Superwall.configure(apiKey: "pk_4u3IdFlMP9qwOzQoy9pcn")
        FirebaseApp.configure()
    }
    

    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
