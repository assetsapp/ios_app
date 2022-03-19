//
//  InventorySessionModel.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 10/10/21.
//

import Foundation
import SwiftUI

struct inventorySessionModel: Codable, Hashable {
    var _id: String
    var sessionId: String
    var name: String
    var locationId: String
    var locationName: String
    var status: String
    var creation: String
}

struct inventoryAssetModel: Codable, Hashable {
    var _id: String
    var name: String
    var brand: String
    var model: String
    var serial: String
    var location: String
    var EPC: String
    var status: String
}

struct InventorySessionsApiModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: [inventorySessionModel]
    
    private enum CodingKeys: String, CodingKey {
        case response
    }
}

struct InventoryAssetsApiModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: [AssetModel]

    private enum CodingKeys: String, CodingKey {
        case response
    }
}

class ApiInventorySessions {
    @AppStorage(Settings.apiHostKey) var apiHost = "http://159.203.41.87:3001"
    @AppStorage(Settings.apiDBKey) var apiDB = "notes-db-app"
    @AppStorage(Settings.userTokenKey) var token = ""

    func getInventorySessions(location: String, completion: @escaping([inventorySessionModel]) -> ()) {
        var urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/inventorySessions/")!
        urlComponent.queryItems = [
            URLQueryItem(name: "fields", value: "{\"_id\":1,\"name\":1,\"sessionId\":1,\"locationId\":1,\"locationName\":1,\"status\":1,\"creation\":1}"),
            URLQueryItem(name: "query", value: "{\"locationId\":\"\(location)\"}")
        ]
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let inventorySessions = try! JSONDecoder().decode(InventorySessionsApiModel.self, from: data!)
            DispatchQueue.main.async {
                completion(inventorySessions.response)
            }
        }.resume()
    }
    
    func updateAssetsInInventorySession(params: [String: Any], completion: @escaping([SavedAsset]) -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/updateInventorySessions")!
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let savedAssets = try! JSONDecoder().decode(SavedAssetApiModel.self, from: data!)
            print(savedAssets)
            DispatchQueue.main.async {
                completion(savedAssets.response)
            }
        }.resume()
    }
    
    func pushAssetToInventorySession(params: [String: Any], completion: @escaping() -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/pushAssetToInventorySessions")!
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        print("=======================> 0")
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("=======================> 1")
            DispatchQueue.main.async {
                print("=======================> 2")
                completion()
            }
        }.resume()
    }

    
    func getInventorySessionAssets(sessionId: String, completion: @escaping([AssetModel]) -> ()) {
        var urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/getInventorySession/Assets/")!
        urlComponent.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId)
        ]
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let inventorySessionAssets = try! JSONDecoder().decode(InventoryAssetsApiModel.self, from: data!)
            DispatchQueue.main.async {
                completion(inventorySessionAssets.response)
            }
        }.resume()
    }
    
    func updateInventorySessionStatus(id: String, status: String) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/inventorySessions/\(id)")!
        let params: [String: Any] = [
            "status": status
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
        }.resume()
    }
}
