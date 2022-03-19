//
//  userModel.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 23/10/21.
//

import Foundation
import SwiftUI

struct UserModel: Codable, Hashable {
    var id: String
    var fileExt: String
    var name: String
    var lastName: String
    var email: String
    var accessToken: String
    var profilePermissions: String = ""
    var selectedBoss: String = ""

    private enum CodingKeys: String, CodingKey {
        case id, fileExt, name, lastName, email, accessToken
    }
}

struct UserApiModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: UserModel
    
    private enum CodingKeys: String, CodingKey {
        case response
    }
}

class ApiUser {
    @AppStorage(Settings.apiHostKey) var apiHost = "http://159.203.41.87:3001"
    @AppStorage(Settings.apiDBKey) var apiDB = "notes-db-app"
    @AppStorage(Settings.userTokenKey) var token = ""
    
    func logIn(user: String, pwd: String, completion: @escaping(UserModel) -> ()) {
        let params: [String: Any] = [
            "user": user,
            "password": pwd
        ]
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/user/validuser")!
        var request = URLRequest(url: urlComponent.url!)
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let errorUser = UserModel(id: "", fileExt: "", name: "", lastName: "", email: "", accessToken: "", profilePermissions: "", selectedBoss: "")
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    let user = try! JSONDecoder().decode(UserApiModel.self, from: data!)
                    DispatchQueue.main.async {
                        completion(user.response)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(errorUser)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(errorUser)
                }
            }
        }.resume()
    }
}
