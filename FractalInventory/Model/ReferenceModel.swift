//
//  ReferenceModel.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 28/08/21.
//

import Foundation
import SwiftUI

struct ReferenceModel: Codable, Hashable {
    var _id: String
    var brand: String?
    var model: String?
    var name: String?
    var fileExt: String?
}

extension ReferenceModel {
    init(from reference:Reference) {
        self._id = reference.id ?? ""
        self.brand = reference.brand ?? ""
        self.model = reference.model ?? ""
        self.name = reference.name ?? ""
        self.fileExt = reference.fileExt ?? ""
    }
}

struct ReferenceApiModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: [ReferenceModel]
    
    private enum CodingKeys: String, CodingKey {
        case response
    }
}

struct tab: Codable, Hashable {
    var columns: Int
    var tabId: String
    var tabName: String
}

struct customField: Codable {
    var columnPosition: String
    var content: String
    var fieldId: String
    var options: [String]
    var columns: Int
    var tabId: String
    var tabName: String
    var fieldName: String
    var fieldIndex: Int
    var initialValue: String
    var fileName: String
    var fileId: String
    var fileExt: String
}

struct responseObj: Codable {
    var customFields: [customField]
    var tabs: [tab]
    
    init() {
        self.customFields = []
        self.tabs = []
    }
    
    init(customFields: [customField], tabs: [tab]) {
        self.customFields = customFields
        self.tabs = tabs
    }
}
struct CustomFieldsApiModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: responseObj
    
    private enum CodingKeys: String, CodingKey {
        case response
    }
}

struct SavedAsset: Codable {
    var _id: String
    var EPC: String
    
    private enum CodingKeys: String, CodingKey {
        case _id, EPC
    }
}

struct SavedAssetApiModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: [SavedAsset]
    
    private enum CodingKeys: String, CodingKey {
        case response
    }
}

class ApiReferences {
    @AppStorage(Settings.apiHostKey) var apiHost = Constants.apiHost
    @AppStorage(Settings.apiDBKey) var apiDB = Constants.apiDB
    @AppStorage(Settings.userTokenKey) var token = ""
    
    func getReferences(completion: @escaping(Result<[ReferenceModel], WMError>) -> ()) {
        var urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/references")!
        urlComponent.queryItems = [
            URLQueryItem(name: "fields", value: "{\"name\":1,\"brand\":1,\"model\":1,\"categoryPic\":1,\"fileExt\":1}")
        ]
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(.failure(WMError.referencesCouldNotBeDownloaded))
                return
            }

            let references = try! JSONDecoder().decode(ReferenceApiModel.self, from: data)
            DispatchQueue.main.async {
                completion(.success(references.response))
            }
        }.resume()
    }
    
    func getCustomFields(id: String, collection: String, completion: @escaping(responseObj) -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/\(collection)/" + id + "/custom-fields")!
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let customFields = try! JSONDecoder().decode(CustomFieldsApiModel.self, from: data!)
            DispatchQueue.main.async {
                completion(customFields.response)
            }
        }.resume()
    }
    
    func updateCustomFields(id: String, updatedCustomFields: [String], collection: String = "assets", completion: @escaping() -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/\(collection)/" + id + "/update-custom-fields")!
        let jsonData = try? JSONSerialization.data(withJSONObject: updatedCustomFields)
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
    
    func postAssets(params: [String: Any], completion: @escaping(Result<[SavedAsset],Error>) -> Void) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/assets/save-from-app")!
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
                do {
                    let savedAssets = try JSONDecoder().decode(SavedAssetApiModel.self, from: data!)
                    completion(.success(savedAssets.response))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
