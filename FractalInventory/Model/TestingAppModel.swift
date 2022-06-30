//
//  TestingAppModel.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 23/10/21.
//

import Foundation
import SwiftUI

class ApiTesting {
    @AppStorage(Settings.apiHostKey) var apiHost = "http://159.203.41.87:3001"
    @AppStorage(Settings.apiDBKey) var apiDB = "notes-db-app"
    @AppStorage(Settings.userTokenKey) var token = ""

    func testApiConnection(completion: @escaping(String) -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/test/api")!
        var request = URLRequest(url: urlComponent.url!)
        print(urlComponent.url!)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            print(error)
            if let httpResponse = response as? HTTPURLResponse {
                print("testapi> statusCode: \(httpResponse.statusCode)")
                
                print("testapi> statusCode: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        completion("Successful")
                    }
                } else {
                    DispatchQueue.main.async {
                        completion("Error")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion("Error")
                }
            }
        }.resume()
    }

    func testDBConnection(completion: @escaping(String) -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/test/db")!
        var request = URLRequest(url: urlComponent.url!)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        completion("Successful")
                    }
                } else {
                    DispatchQueue.main.async {
                        completion("Error")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion("Error")
                }
            }
        }.resume()
    }
    
    func testToken(completion: @escaping(String) -> ()) {
        switch WorkModeManager().workMode {
        case .online:
            validateOnlineToken(completion: completion)
        case .offline:
            validateOfflineToken(completion: completion)
        }
    }
    
    private func validateOnlineToken(completion: @escaping(String) -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/test/valid-user")!
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        print(urlComponent.url!)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                
                print("testapp> statusCode: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        completion("Successful")
                    }
                } else {
                    DispatchQueue.main.async {
                        completion("Error")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion("Error")
                }
            }
        }.resume()
    }
    
    private func validateOfflineToken(completion: @escaping(String) -> ()) {
        print("Validando Token Offline")
        if token.isEmpty {
            completion("Error")
        } else {
            completion("Successful")
        }
    }
}
