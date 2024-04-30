//
//  AssetsRequest.swift
//  FractalInventory
//
//  Created by Miguel Mexicano Herrera on 12/04/24.
//
import Foundation
struct AssetsRequest: Codable {
    let query: AssetsModel
}

struct AssetsModel: Codable {
    let status: AssetsRequestStatus
}
struct AssetsRequestStatus: Codable {
    let ne : String
    enum CodingKeys: String, CodingKey {
        case ne = "$ne"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ne = try values.decode(String.self, forKey: .ne)
    }
    init(ne: String) {
        self.ne = ne
    }
}
enum AssetsStatusType: Codable {
    case decommissioned
}
