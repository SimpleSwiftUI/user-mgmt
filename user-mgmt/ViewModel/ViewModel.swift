//
//  ViewModel.swift
//  user-mgmt
//
//  Created by Robert Brennan on 3/5/24.
//

// Sign in with Apple source:
// https://www.youtube.com/watch?v=O2FVDzoAB34


import Foundation
import CoreData
import AuthenticationServices

let baseUri = "https://user-mgmt-backend-five.vercel.app/api"

class ViewModel: ObservableObject {
    private var managedObjectContext: NSManagedObjectContext
    
    @Published var appleUser: AppleUser?
    
    init(context: NSManagedObjectContext) {
        self.managedObjectContext = context
        
        self.checkSignInStatus()
    }
    
    func configure(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    func handle(_ authResult: Result<ASAuthorization, Error>) {
        switch authResult {
        case .success(let auth):
            print("auth:", auth)
            switch auth.credential {
            case let appleIdCredentials as ASAuthorizationAppleIDCredential:
                print("appleIdCredentials:", appleIdCredentials)
                if let appleUser = AppleUser(credentials: appleIdCredentials),
                   let appleUserData = try? JSONEncoder().encode(appleUser) {
                    UserDefaults.standard.setValue(appleUser.userId, forKey: "AppleUserID")
                    UserDefaults.standard.setValue(appleUserData, forKey: appleUser.userId)
                    self.appleUser = appleUser
                    
                    registerAppleUserWithBackend(appleUser: appleUser)
                    
                    print("Saved apple user:", appleUser)
                } else {
                    print("Missing some fields", appleIdCredentials.email as Any, appleIdCredentials.fullName as Any, appleIdCredentials.user)
                    
                    guard
                        let appleUserData = UserDefaults.standard.data(forKey: appleIdCredentials.user),
                        let appleUser = try? JSONDecoder().decode(AppleUser.self, from: appleUserData)
                    else { return }
                    
                    print(appleUser)
                    self.appleUser = appleUser
                }
                
            default:
                print(auth.credential)
            }
            
        case .failure(let error):
            print("error:", error)
        }
    }
    
    func checkSignInStatus() {
        print("checkSignInStatus()...")
        guard let appleUserId = UserDefaults.standard.string(forKey: "AppleUserID") else {
            print("User is not signed in")
            self.appleUser = nil
            return
        }
        print("User found")
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: appleUserId) { [weak self] (credentialState, error) in
            DispatchQueue.main.async {
                switch credentialState {
                case .authorized:
                    // self?.loadAppleUserFromUserDefaults(userId: appleUserId)
                    self?.loadUserInfoFromBackend(userId: appleUserId)
                case .revoked, .notFound:
                    self?.appleUser = nil
                    UserDefaults.standard.removeObject(forKey: "AppleUserID")
                default:
                    break
                }
            }
        }
    }
    
    private func loadUserInfoFromBackend(userId: String) {
        guard let url = URL(string: baseUri + "/get-user?userId=\(userId)") else {
            print("Invalid URL"); return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching user info: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    let appleUser = try JSONDecoder().decode(AppleUser.self, from: data)
                    DispatchQueue.main.async {
                        self?.appleUser = appleUser
                        print("Loaded user info from backend for userId: \(userId)")
                    }
                } catch {
                    print("Failed to decode user info: \(error)")
                }
            } else {
                print("Failed to fetch user info, HTTP status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            }
        }
        task.resume()
    }
    
    func printAppleUser() {
        print("appleUser:", appleUser as Any)
    }
    
    func registerAppleUserWithBackend(appleUser: AppleUser) {
        guard let url = URL(string: baseUri + "/register-apple-user") else {
            print("Invalid URL"); return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let userRegistrationDetails = [
            "appleUserId": appleUser.userId,
            "firstName": appleUser.firstName,
            "lastName": appleUser.lastName,
            "email": appleUser.email
        ]
        
        do {
            let requestBody = try JSONSerialization.data(withJSONObject: userRegistrationDetails, options: [])
            request.httpBody = requestBody
        } catch {
            print("Failed to serialize user registration details: \(error)")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error with the response, unexpected status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return
            }
            
            if let error = error {
                print("Error registering Apple user with backend: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                print("Successfully registered Apple user.")
                UserDefaults.standard.removeObject(forKey: appleUser.userId)
                print("Deleted appleUserData from UserDefaults for userId: \(appleUser.userId)")
            }
        }
        task.resume()
    }
}
