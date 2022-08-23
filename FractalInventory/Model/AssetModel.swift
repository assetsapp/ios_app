//
//  AssetModel.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 25/09/21.
//

import Foundation
import SwiftUI

struct AssetModel: Codable, Hashable {
    var _id: String
    var brand: String
    var model: String
    var name: String
    var EPC: String?
    var serial: String?
    var location: String
    var status: String?
    var locationPath: String = ""
    
    private enum CodingKeys: String, CodingKey {
        case _id, brand, model, name, EPC, serial, location, status
    }
}

extension AssetModel {
    init(asset: Asset) {
        self._id = asset.identifier ?? ""
        self.brand = asset.brand ?? ""
        self.model = asset.model ?? ""
        self.name = asset.name ?? ""
        self.EPC = asset.epc ?? ""
        self.serial = asset.serial
        self.locationPath = asset.locationPath ?? ""
        self.location = asset.location ?? ""
        self.status = "external"
        if let rawstatus = asset.status {
            self.status = rawstatus == "active" ? "missing" : rawstatus
        }
    }
}

struct RealAssetModel: Codable, Hashable {
    var _id: String
    var brand: String
    var model: String
    var name: String
    var EPC: String?
    var serial: String?
    var status: String = "external"
    var locationPath: String?
    var fileExt: String?
    
    private enum CodingKeys: String, CodingKey {
        case _id, brand, model, name, EPC, serial, locationPath, fileExt
    }
}

extension RealAssetModel {
    init(asset: Asset) {
        self._id = asset.identifier ?? ""
        self.brand = asset.brand ?? ""
        self.model = asset.model ?? ""
        self.name = asset.name ?? ""
        self.EPC = asset.epc ?? ""
        self.serial = asset.serial
        self.status = asset.status ?? "external"
        self.locationPath = asset.locationPath
        self.fileExt = asset.fileExt
    }
}

struct RealAssetModelWithLocation: Codable, Hashable {
    var _id: String
    var brand: String?
    var model: String?
    var name: String
    var EPC: String?
    var serial: String?
    var locationPath: String?
    var status: String = "external"
    var fileExt: String?
    var assigned: String?
    var assignedTo: String?
    
    private enum CodingKeys: String, CodingKey {
        case _id, brand, model, name, EPC, locationPath, serial, fileExt, assigned, assignedTo
    }
}

extension RealAssetModelWithLocation {
    init(asset: Asset) {
        self._id = asset.identifier ?? ""
        self.brand = asset.brand ?? ""
        self.model = asset.model ?? ""
        self.name = asset.name ?? ""
        self.EPC = asset.epc ?? ""
        self.serial = asset.serial
        self.status = asset.status ?? "external"
        self.locationPath = asset.locationPath
        self.fileExt = asset.fileExt
        self.assigned = asset.assigned
        self.assignedTo = asset.assignedTo
    }
}


struct RealAssetsWithLocationApiModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: [RealAssetModelWithLocation]
    
    private enum CodingKeys: String, CodingKey {
        case response
    }
}

struct RealAssetsApiModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: [RealAssetModel]
    
    private enum CodingKeys: String, CodingKey {
        case response
    }
}

struct AssetsApiModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: [AssetModel]
    
    private enum CodingKeys: String, CodingKey {
        case response
    }
}

struct RepeatResult: Codable {
    var _id: String
    var EPC: String
}

struct RepeatResultApiModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: [RepeatResult]
    
    private enum CodingKeys: String, CodingKey {
        case response
    }
}

struct AssetMainRespondeModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: [AssetRespondeModel]
    private enum CodingKeys: String, CodingKey {
        case response
    }
}

struct AssetRespondeModel: Codable {
          var serial: String?
          var location: String?
          var status: String?
          var creator: String?
          var assigned: String?
          var EPC: String?
          var referenceId: String?
          var locationPath: String?
          var brand: String?
          var _id: String?
          var creation_date: String?
          var updateDate: String?
//          var category: Any?
          var fileExt: String?
//          var customFieldsTab: Any?
          var name: String?
          var parent: String?
          var imageURL: String?
          var quantity: Int?
          var responsible: String?
          var purchase_date: String?
//          var history: Any?
          var purchase_price: String?
          var total_price: String?
          var model: String?
          var labeling_user: String?
          var notes: String?
          var labeling_date: String?
          var price: String?
}

class ApiAssets {
    @AppStorage(Settings.apiHostKey) var apiHost = "http://159.203.41.87:3001"
    @AppStorage(Settings.apiDBKey) var apiDB = "notes-db-app"
    @AppStorage(Settings.userTokenKey) var token = ""
    
    func getInventoryAssets(location: String, locationName: String, sessionId: String, inventoryName: String, type: InventoryType, completion: @escaping([AssetModel]) -> ()) {
        var urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/assets/inventory/")!
        
        print("location: \(location)\nlocationName: \(locationName)\nsessionId: \(sessionId)\ninventoryName: \(inventoryName)\ntype: \(type)")
        
        urlComponent.queryItems = [
            URLQueryItem(name: "location", value: location),
            URLQueryItem(name: "children", value: type.rawValue),
            URLQueryItem(name: "locationName", value: locationName),
            URLQueryItem(name: "inventoryName", value: inventoryName),
            URLQueryItem(name: "sessionId", value: sessionId)
        ]
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.timeoutInterval = 999.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion([])
                return
            }
            let assets = try! JSONDecoder().decode(AssetsApiModel.self, from: data)
            DispatchQueue.main.async {
                completion(assets.response)
            }
        }.resume()
    }
    
    func getAssets(location: String, completion: @escaping([AssetModel]) -> ()) {
        var urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/assets/")!
        urlComponent.queryItems = [
            URLQueryItem(name: "fields", value: "{\"name\":1,\"brand\":1,\"model\":1,\"serial\":1,\"EPC\":1,\"location\":1}"),
            URLQueryItem(name: "query", value: "{\"location\":\"\(location)\",\"status\":{\"$ne\":\"decommissioned\"}}")
        ]
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let assets = try! JSONDecoder().decode(AssetsApiModel.self, from: data!)
            DispatchQueue.main.async {
                completion(assets.response)
            }
        }.resume()
    }
    
    func getAllAssets(completion: @escaping(Result<[AssetRespondeModel], Error>) -> Void) {
        var urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/assets/")!
        urlComponent.queryItems = [
            //            URLQueryItem(name: "fields", value: "{\"name\":1,\"brand\":1,\"model\":1,\"serial\":1,\"EPC\":1,\"location\":1}"),
            URLQueryItem(name: "query", value: "{\"status\":{\"$ne\":\"decommissioned\"}}")
        ]
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { completion(.failure(WMError.assetsCouldNotBeDownloaded)) ; return }
            do {
                let assets = try JSONDecoder().decode(AssetMainRespondeModel.self, from: data)
                completion(.success(assets.response))
            } catch let error {
                print("Error: 19 al 22 de agosto", error.localizedDescription)
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getRealAssets(location: String, completion: @escaping([RealAssetModel]) -> ()) {
        var urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/assets/")!
        urlComponent.queryItems = [
            URLQueryItem(name: "fields", value: "{\"name\":1,\"brand\":1,\"model\":1,\"serial\":1,\"EPC\":1,\"fileExt\":1,\"locationPath\":1}}}"),
            URLQueryItem(name: "query", value: "{\"location\":\"\(location)\",\"status\":{\"$ne\":\"decommissioned\"}}")
        ]
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let assets = try! JSONDecoder().decode(RealAssetsApiModel.self, from: data!)
            DispatchQueue.main.async {
                completion(assets.response)
            }
        }.resume()
    }
    
    func getRealAssetsForEmployee(assetIds: [String], completion: @escaping([RealAssetModel]) -> ()) {
        var urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/assets/")!
        let query = "{\"_id\":{\"$in\":[\(assetIds.joined(separator: ","))]}}"
        urlComponent.queryItems = [
            URLQueryItem(name: "fields", value: "{\"name\":1,\"brand\":1,\"model\":1,\"serial\":1,\"EPC\":1,\"fileExt\":1,\"locationPath\":1}}}"),
            URLQueryItem(name: "query", value: query)
        ]
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let assets = try! JSONDecoder().decode(RealAssetsApiModel.self, from: data!)
            DispatchQueue.main.async {
                completion(assets.response)
            }
        }.resume()
    }
    
    func getAsset(EPC: String, completion: @escaping([RealAssetModelWithLocation]) -> ()) {
        var urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/assets/")!
        urlComponent.queryItems = [
            URLQueryItem(name: "fields", value: "{\"name\":1,\"brand\":1,\"model\":1,\"serial\":1,\"EPC\":1,\"location\":1,\"locationPath\":1}"),
            URLQueryItem(name: "query", value: "{\"EPC\":\"\(EPC)\",\"status\":{\"$ne\":\"decommissioned\"}}")
        ]
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let asset = try! JSONDecoder().decode(RealAssetsWithLocationApiModel.self, from: data!)
            print(asset)
            DispatchQueue.main.async {
                completion(asset.response)
            }
        }.resume()
    }
    
    func validateEPCS(params: [String: Any], completion: @escaping([RepeatResult]) -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/assets/EPC/repeated")!
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let asset = try! JSONDecoder().decode(RepeatResultApiModel.self, from: data!)
            print(asset)
            DispatchQueue.main.async {
                completion(asset.response)
            }
        }.resume()
    }
    
    func moveAssetToLocation(assetId: String, locationId: String, locationPath: String, completion: @escaping() -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/assets/\(assetId)")!
        let params: [String: Any] = [
            "location": locationId,
            "locationPath": locationPath
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion()
            }
        }.resume()
    }
    
    func getValidatedEPCS(params: [String: Any], completion: @escaping([RealAssetModelWithLocation]) -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/getValidAssets")!
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let asset = try! JSONDecoder().decode(RealAssetsWithLocationApiModel.self, from: data!)
            print(asset)
            DispatchQueue.main.async {
                completion(asset.response)
            }
        }.resume()
    }
    
    func getSearchAssets(searchText: String, completion: @escaping([RealAssetModelWithLocation]) -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/getValidSearchAssets")!
        let params: [String: Any] = [
            "searchText": searchText
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let deserializedValues = try! JSONSerialization.jsonObject(with: data!)
            print("===============================>")
            print(deserializedValues)
            print("===============================>")
            
            let asset = try! JSONDecoder().decode(RealAssetsWithLocationApiModel.self, from: data!)
            print(asset)
            DispatchQueue.main.async {
                completion(asset.response)
            }
        }.resume()
    }
    
    func updateAsset(assetId: String, params: [String: Any], completion: @escaping() -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/assets/\(assetId)")!
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: urlComponent.url!)
        print("params: \(String(describing: jsonData))")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("Actualizo Asset, error: \(error?.localizedDescription)")
            DispatchQueue.main.async {
                completion()
            }
        }.resume()
    }
    
    func assignEmployeeToAsset(assetId: String, employee: EmployeeModel, completion: @escaping() -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/assets/\(assetId)")!
        let params: [String: Any] = [
            "assigned": employee._id,
            "assignedTo": "\(employee.name) \(employee.lastName) <\(employee.email)>"
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion()
            }
        }.resume()
    }
}
