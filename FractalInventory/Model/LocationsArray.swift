//
//  LocationsArray.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 25/08/21.
//

import Foundation

class LocationsArray: ObservableObject {
    
    @Published var locations = [LocationModel]()
    
    init() {
        
        print("Fetch from Backend")
        
        let location1 = LocationModel(_id: "ab1", name: "CDMX", type: "City", level: 1, childrenNumber: 5, assetsNumber: 15, canTag: true, canInventory: true, path: "")
        let location2 = LocationModel(_id: "ab2", name: "Monterrey", type: "City", level: 1, childrenNumber: 6, assetsNumber: 14, canTag: true, canInventory: true, path: "")
        let location3 = LocationModel(_id: "ab3", name: "Gdl", type: "City", level: 1, childrenNumber: 7, assetsNumber: 13, canTag: true, canInventory: true, path: "")
        let location4 = LocationModel(_id: "ab4", name: "Puebla", type: "City", level: 1, childrenNumber: 8, assetsNumber: 12, canTag: true, canInventory: true, path: "")
        let location5 = LocationModel(_id: "ab5", name: "Tijuana", type: "City", level: 1, childrenNumber: 9, assetsNumber: 11, canTag: true, canInventory: true, path: "")
        
        self.locations.append(location1)
        self.locations.append(location2)
        self.locations.append(location3)
        self.locations.append(location4)
        self.locations.append(location5)

    }
    
    init(location: LocationModel) {
        self.locations.append(location)
    }
    
}
