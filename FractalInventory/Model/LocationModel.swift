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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self._id = try container.decode(String.self, forKey: ._id)
        self.name = try container.decode(String.self, forKey: .name)
        self.profileName = try container.decode(String.self, forKey: .profileName)
        self.parent = try container.decode(String.self, forKey: .parent)
        self.assetsCount = try container.decodeIfPresent(Int.self, forKey: .assetsCount) ?? 0
        self.childrenCount = try container.decodeIfPresent(Int.self, forKey: .childrenCount) ?? 0
        do {
            self.profileLevel = try String(container.decode(Int.self, forKey: .profileLevel))
        } catch DecodingError.typeMismatch {
            self.profileLevel = try container.decode(String.self, forKey: .profileLevel)
        }
    }
    
    init(from location: Location) {
        self._id = location.id ?? ""
        self.name = location.name ?? ""
        self.profileName = location.profileName ?? ""
        self.profileLevel = location.profileLevel ?? ""
        self.parent = location.parent ?? ""
        self.assetsCount = Int(location.assetsCount)
        self.childrenCount = Int(location.childrenCount)
    }
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
    
    func getLocations(completion: @escaping(Result<[LocationModel2],Error>) -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/locationsReal/allLocationsCount/children/assets")!
        var request = URLRequest(url: urlComponent.url!)
        request.timeoutInterval = 160
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(.failure(WMError.locationsCouldNotBeDownloaded))
                return
            }
            do {
                let locations = try JSONDecoder().decode(LocationApiModel.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(locations.response))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
