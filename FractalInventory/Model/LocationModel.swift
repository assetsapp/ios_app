//
//  LocationModel.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 22/08/21.
//

import Foundation
import SwiftUI

struct LocationModel: Identifiable, Hashable {
  
    var id = UUID()
    var _id: String
    var name: String
    var type: String
    var level: Int
    var childrenNumber: Int
    var assetsNumber: Int
    var canTag: Bool
    var canInventory: Bool
    var path: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
  
}

struct LocationModel2: Codable, Hashable {
    var _id: String
    var name: String
    var profileName: String
    var profileLevel: String
    var parent: String
    var assetsCount: Int
    var childrenCount: Int
}

struct LocationApiModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: [LocationModel2]
    
    private enum CodingKeys: String, CodingKey {
        case response
    }
}

class ApiLocations {
    @AppStorage(Settings.apiHostKey) var apiHost = "http://159.203.41.87:3001"
    @AppStorage(Settings.apiDBKey) var apiDB = "notes-db-app"
    @AppStorage(Settings.userTokenKey) var token = ""
    
    func getLocations(id: String, level: String, completion: @escaping([LocationModel2]) -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/locationsReal/\(id)/\(level)/locations")!
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let locations = try! JSONDecoder().decode(LocationApiModel.self, from: data!)
            DispatchQueue.main.async {
                completion(locations.response)
            }
        }.resume()
    }
}
