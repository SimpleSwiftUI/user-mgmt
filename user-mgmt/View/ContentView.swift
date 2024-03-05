//
//  ContentView.swift
//  user-mgmt
//
//  Created by Robert Brennan on 3/5/24.
//

import SwiftUI
import AuthenticationServices
import CoreData

struct ContentView: View {
    @EnvironmentObject var viewModel: ViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            
            if viewModel.appleUser == nil {
                SignInWithAppleButton(.signIn, onRequest: viewModel.configure, onCompletion: viewModel.handle)
                    .signInWithAppleButtonStyle(
                        colorScheme == .dark ? .white : .black
                    )
                    .frame(width: 222, height: 48)
                    .padding()
            } else {
                Text("Welcome \(viewModel.appleUser?.firstName ?? "[error]")")
                    .padding()
            }
            
            Button {
                viewModel.printAppleUser()
            } label: {
                Text("Log appleUser")
                    .padding()
            }
        }
    }

}



//#Preview {
//    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}
