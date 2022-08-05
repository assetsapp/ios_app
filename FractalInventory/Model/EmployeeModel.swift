//
//  EmployeeModel.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 17/12/21.
//

import Foundation
import SwiftUI

struct EmployeeModel: Codable, Hashable {
    var _id: String
    var name: String
    var lastName: String
    var email: String
    var employee_id: String? = ""
    var profileName: String? = ""
    var profileId: String? = ""
    var assetsAssigned: [AssetsAssigned]? = []
}

extension EmployeeModel {
    init(from employee: Employee) {
        self._id = employee.identifier ?? ""
        self.employee_id = employee.identifier ?? ""
        self.name = employee.name ?? ""
        self.lastName = employee.lastName ?? ""
        self.email = employee.email ?? ""
        self.assetsAssigned = []
        self.profileId = employee.profileId
        self.profileName = employee.profileName
    }
}

struct AssetsAssigned: Codable, Hashable {
    var id: String? = ""
    var name: String? = ""
    var brand: String? = ""
    var model: String? = ""
    var assigned: Bool? = false
    var serial: String? = ""
    var EPC: String? = ""
    var creationDate: String? = ""
    
    private enum CodingKeys: String, CodingKey {
        case id, name, brand, model, serial, EPC
    }
}

struct EmployeesApiModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: [EmployeeModel]
    
    private enum CodingKeys: String, CodingKey {
        case response
    }
}

struct EmployeeProfileModel: Codable, Hashable {
    var _id: String
    var name: String
}

extension EmployeeProfileModel {
    init(profile: EmployeeProfile) {
        self._id = profile.identifier ?? ""
        self.name = profile.name ?? ""
    }
}

struct EmployeeProfilesApiModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: [EmployeeProfileModel]
    
    private enum CodingKeys: String, CodingKey {
        case response
    }
}

class ApiEmployees {
    @AppStorage(Settings.apiHostKey) var apiHost = "http://159.203.41.87:3001"
    @AppStorage(Settings.apiDBKey) var apiDB = "notes-db-app"
    @AppStorage(Settings.userTokenKey) var token = ""
    
    
    func getEmployees(completion: @escaping(Result<[EmployeeModel], Error>) -> ()) {
        var urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/employees")!
        urlComponent.queryItems = [
            URLQueryItem(name: "fields", value: "{\"name\":1,\"lastName\":1,\"email\":1,\"employee_id\":1,\"assetsAssigned\":1}")
        ]
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(.failure(WMError.employeesCouldNotBeDownloaded))
                return
            }
            
            do {
                let employees = try JSONDecoder().decode(EmployeesApiModel.self, from: data)
                completion(.success(employees.response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func assignAssetToEmployee(params: [String: Any], employeeId: String, completion: @escaping() -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/app/\(apiDB)/assignAssetToEmployee/\(employeeId)")!
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
    
    func getEmployeeProfiles(completion: @escaping([EmployeeProfileModel]) -> ()) {
        var urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/employeeProfiles")!
        urlComponent.queryItems = [
            URLQueryItem(name: "fields", value: "{\"name\":1}")
        ]
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let employees = try! JSONDecoder().decode(EmployeeProfilesApiModel.self, from: data!)
            completion(employees.response)
        }.resume()
    }
    
    func postEmployee(params: [String: Any], completion: @escaping() -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/\(apiDB)/employees")!
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion()
            }
        }.resume()
    }
}
