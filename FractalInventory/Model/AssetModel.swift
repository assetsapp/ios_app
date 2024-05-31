//
//  AssetModel.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 25/09/21.
//

import Foundation
import SwiftUI
import ConnectionLayer
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.serial = try container.decodeIfPresent(String.self, forKey: .serial)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.creator = try container.decodeIfPresent(String.self, forKey: .creator)
        self.assigned = try container.decodeIfPresent(String.self, forKey: .assigned)
        self.EPC = try container.decodeIfPresent(String.self, forKey: .EPC)
        self.referenceId = try container.decodeIfPresent(String.self, forKey: .referenceId)
        self.locationPath = try container.decodeIfPresent(String.self, forKey: .locationPath)
        self.brand = try container.decodeIfPresent(String.self, forKey: .brand)
        self._id = try container.decodeIfPresent(String.self, forKey: ._id)
        self.creation_date = try container.decodeIfPresent(String.self, forKey: .creation_date)
        self.updateDate = try container.decodeIfPresent(String.self, forKey: .updateDate)
        self.fileExt = try container.decodeIfPresent(String.self, forKey: .fileExt)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.parent = try container.decodeIfPresent(String.self, forKey: .parent)
        self.imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        if let quantity = try? container.decodeIfPresent(Int.self, forKey: .quantity) {
            self.quantity = quantity
        } else if let quantityS = try? container.decodeIfPresent(String.self, forKey: .quantity), let quantity = Int(quantityS) {
            self.quantity = quantity
        }
        self.responsible = try container.decodeIfPresent(String.self, forKey: .responsible)
        self.purchase_date = try container.decodeIfPresent(String.self, forKey: .purchase_date)
        self.purchase_price = try container.decodeIfPresent(String.self, forKey: .purchase_price)
        
        if let total_price = try? container.decodeIfPresent(Int.self, forKey: .total_price) {
            self.total_price = String(total_price)
        } else if let total_priceS = try? container.decodeIfPresent(String.self, forKey: .total_price) {
            self.total_price = total_priceS
        }
        
        self.model = try container.decodeIfPresent(String.self, forKey: .model)
        self.labeling_user = try container.decodeIfPresent(String.self, forKey: .labeling_user)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        self.labeling_date = try container.decodeIfPresent(String.self, forKey: .labeling_date)
        self.price = try container.decodeIfPresent(String.self, forKey: .price)
    }
}

class ApiAssets {
    @AppStorage(Settings.apiHostKey) var apiHost = Constants.apiHost
    @AppStorage(Settings.apiDBKey) var apiDB = Constants.apiDB
    @AppStorage(Settings.userTokenKey) var token = ""
    
    func getInventoryAssets(location: String, locationName: String, sessionId: String, inventoryName: String, type: InventoryType, completion: @escaping(Result<[AssetModel], Error>) -> Void) {
        let connection = ConnectionLayer(isDebug: false)
        let endPoint = EndPoints.inventoryAssets.replacingOccurrences(of: "{apiDB}", with: apiDB)
        let url = apiHost + endPoint
        let headers: HTTPHeaders = HTTPHeaders([
            HTTPHeaders.authorization(bearerToken: token),
            HTTPHeaders.contentTypeJson,
            HTTPHeaders.acceptJson
        ])
        let body = InventoryAssetsRequest(location: location, children: type.rawValue, locationName: locationName, inventoryName: inventoryName, sessionId: sessionId)
        connection.connectionRequest(url: url, method: .post, headers: headers, data: body.toData) { data, error in
            if let error = error {
                print(error)
                completion(.failure(WMError.inventoriesCouldNotBeDownloaded))
            }
            guard let data = data else {
                completion(.failure(WMError.inventoriesCouldNotBeDownloaded))
                return
            }
            if let assets = Utils.decode(AssetsApiModel.self, from: data, serviceName: "getInventoryAssets") {
                completion(.success(assets.response))
            } else {
                completion(.failure(WMError.inventoriesCouldNotBeDownloaded))
            }
        }
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
        let connection = ConnectionLayer(isDebug: false)
        let endPoint = EndPoints.allAssets.replacingOccurrences(of: "{apiDB}", with: apiDB)
        let url = apiHost + endPoint
        let headers: HTTPHeaders = HTTPHeaders([
            HTTPHeaders.authorization(bearerToken: token),
            HTTPHeaders.contentTypeJson,
            HTTPHeaders.acceptJson
        ])
        let data = AssetsRequest(query: AssetsModel(status: AssetsRequestStatus(ne: "decommissioned")))  
        connection.connectionRequest(url: url, method: .get, headers: headers, parameters: data.toDictionary) { data, error in
            if let error = error {
                print(error)
                completion(.failure(WMError.assetsCouldNotBeDownloaded))
            }
            guard let data = data else {
                completion(.failure(WMError.assetsCouldNotBeDownloaded))
                return
            }
            if let assets = Utils.decode(AssetMainRespondeModel.self, from: data, serviceName: "getAllAssets") {
                completion(.success(assets.response))
            } else {
                completion(.failure(WMError.assetsCouldNotBeDownloaded))
            }
        }
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
            let asset = try! JSONDecoder().decode(RealAssetsWithLocationApiModel.self, from: data!)
            print(asset)
            DispatchQueue.main.async {
                completion(asset.response)
            }
        }.resume()
    }
    
    func updateAsset(assetId: String, params: [String: Any], completion: @escaping(Result<String, Error>) -> Void) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/assets/\(assetId)")!
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(assetId))
            }
        }.resume()
    }
    
    func assignEmployeeToAsset(assetId: String, employee: EmployeeModel, completion: @escaping(Result<String, Error>) -> Void) {
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
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(assetId))
            }
        }.resume()
    }
}
