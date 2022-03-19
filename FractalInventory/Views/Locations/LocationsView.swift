//
//  LocationsView.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 22/08/21.
//

import SwiftUI

struct LocationsView: View {
    @ObservedObject var cslvalues: CSLValues
    @State var id = "root"
    @State var profileLevel = "0"
    @State var locations: [LocationModel2] = []
    @State var locationPath: String = ""
    
    var body: some View {
        
        
        VStack {
            if id != "root" {
                HStack {
                    VStack(alignment: .leading) {
                        Text(locationPath)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding(.top)
                .padding(.horizontal)
            }
            ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach(locations, id: \.self) { location in
                            let currentLocation = LocationModel(_id: location._id, name: location.name, type: location.profileName, level: 0, childrenNumber: location.childrenCount, assetsNumber: location.assetsCount, canTag: true, canInventory: true, path: location.name)
                            if (location.childrenCount > 0) {
                                let nextProfileLevel = String((Int(location.profileLevel) ?? 0) + 1);
                                NavigationLink(destination: LocationsView(cslvalues: cslvalues, id: location._id, profileLevel: nextProfileLevel, locationPath: "\(locationPath) / \(location.name)")) {
                                    LocationSubview(cslvalues: cslvalues, location: currentLocation, locationPath: locationPath)
                                }
                            } else {
                                LocationSubview(cslvalues: cslvalues, location: currentLocation, locationPath: locationPath)
                            }
                        }

                    }
                }
                .padding(.top, 15)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("Locations")
            .onAppear {
                cslvalues.isLoading = true
                ApiLocations().getLocations(id: id, level: profileLevel) { locations in
                    self.locations = locations
                    cslvalues.isLoading = false
                }
        }
        
    }

}

struct LocationsView_Previews: PreviewProvider {
    static var previews: some View {
        LocationsView(cslvalues: CSLValues())
    }
}
