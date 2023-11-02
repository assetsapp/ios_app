//
//  InventorySessionModel.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 10/10/21.
//

import Foundation
import SwiftUI

struct InventoryDataModel: Codable, Hashable {
    var _id: String
    var sessionId: String
    var name: String
    var locationId: String
    var locationName: String
    var status: String
    var creation: String
    var assets: [AssetModel]?
}

extension InventoryDataModel {
    init(inventorySession: InventorySession) {
        self._id = inventorySession.identifier ?? ""
        self.sessionId = inventorySession.sessionId ?? ""
        self.name = inventorySession.name ?? ""
        self.locationId = inventorySession.locationId ?? ""
        self.locationName = inventorySession.locationName ?? ""
        self.status = inventorySession.status ?? ""
        self.creation = inventorySession.creation ?? ""
        
        if let assetsData = inventorySession.assets?.allObjects as? [Asset] {
            assets = assetsData.map({ AssetModel(asset: $0)})
        }
    }
}

struct ConstanciainventoryAssetModel: Codable, Hashable {
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
    var response: [InventoryDataModel]
    
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

    func getInventorySessions(location: String, completion: @escaping(Result<[InventoryDataModel], WMError>) -> Void) {
        var urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/inventorySessions/")!
        urlComponent.queryItems = [
            URLQueryItem(name: "fields", value: "{\"_id\":1,\"name\":1,\"sessionId\":1,\"locationId\":1,\"locationName\":1,\"status\":1,\"creation\":1}"),
        ]
        if !location.isEmpty {
            urlComponent.queryItems?.append(URLQueryItem(name: "query", value: "{\"locationId\":\"\(location)\"}"))
        }
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(.failure(.inventoriesCouldNotBeDownloaded))
                return
            }

            do {
                let inventorySessions = try JSONDecoder().decode(InventorySessionsApiModel.self, from: data)
                completion(.success(inventorySessions.response))
            } catch {
                completion(.failure(.inventoriesCouldNotBeDownloaded))
            }
        }.resume()
    }
    
    func getInventorySessions(completion: @escaping(Result<[InventoryDataModel], WMError>) -> Void) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/inventorySessions/")!
     
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(.failure(.inventoriesCouldNotBeDownloaded))
                return
            }
            do {
                let inventorySessions = try JSONDecoder().decode(InventorySessionsApiModel.self, from: data)
                completion(.success(inventorySessions.response))
            } catch {
                completion(.failure(.inventoriesCouldNotBeDownloaded))
            }
        }.resume()
    }
    
    func updateAssetsInInventorySession(params: [String: Any], completion: @escaping(Result<[SavedAsset], Error>) -> Void) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/updateInventorySessions")!
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else {
                guard let data = data else {
                    completion(.failure(WMError.inventoriesCouldNotBeDownloaded))
                    return
                }
                do {
                    let savedAssets = try JSONDecoder().decode(SavedAssetApiModel.self, from: data)
                    print(savedAssets)
                    completion(.success(savedAssets.response))
                } catch {
                    completion(.failure(error))
                }
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
