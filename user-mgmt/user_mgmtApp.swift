//
//  user_mgmtApp.swift
//  user-mgmt
//
//  Created by Robert Brennan on 3/5/24.
//

import SwiftUI

@main
struct user_mgmtApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
