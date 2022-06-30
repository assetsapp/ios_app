//
//  FileModel.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 25/10/21.
//

import Foundation
import SwiftUI

struct FileUploadModel: Codable, Hashable {
    var fieldname: String
    var originalname: String
    var encoding: String
    var mimetype: String
    var destination: String
    var filename: String
    var path: String
    var size: Int = 0
    var replaced: Bool = false

    private enum CodingKeys: String, CodingKey {
        case fieldname, originalname, encoding, mimetype, destination, filename, path
    }
}

struct FileUploadApiModel: Codable {
    var platform: NSObject?
    var request: NSObject?
    var response: FileUploadModel
    
    private enum CodingKeys: String, CodingKey {
        case response
    }
}

class ApiFile {
    @AppStorage(Settings.apiHostKey) var apiHost = "http://159.203.41.87:3001"
    @AppStorage(Settings.apiDBKey) var apiDB = "notes-db-app"
    @AppStorage(Settings.userTokenKey) var token = ""
    
    func postImage(image: UIImage, _id: String = "", folder: String = "assets", completion: @escaping(Result<FileUploadModel, Error>) -> ()) {
        let urlComponent = URLComponents(string: "\(apiHost)/api/v1/upload/\(folder)")!
        let boundary = _id != "" ? _id : UUID().uuidString
        let imageData: Data = image.jpegData(compressionQuality: 0.2) ?? Data()
        
        var request = URLRequest(url: urlComponent.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        // Create data object with content prepared to send an image
        var data = Data()
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(boundary).jpeg\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        data.append(imageData)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(.failure(WMError.failedToSyncImage))
                return
            }
            do {
                let uploadedFile = try JSONDecoder().decode(FileUploadApiModel.self, from: data)
                print(uploadedFile)
                completion(.success(uploadedFile.response))
            } catch {
                completion(.failure(WMError.failedToSyncImage))
            }
        }.resume()
    }
}
