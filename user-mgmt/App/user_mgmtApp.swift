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
    @StateObject var viewModel: ViewModel

    init() {
        let context = persistenceController.container.viewContext
        _viewModel = StateObject(wrappedValue: ViewModel(context: context))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
