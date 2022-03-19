//
//  AssetListSubview.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 11/10/21.
//

import SwiftUI

struct AssetListSubview: View {
    @ObservedObject var cslvalues: CSLValues
    @State var locationId: String = ""
    @State var isSearching = true
    @State var searchText = ""
    @State var apiAssets: [RealAssetModel] = []
    @Binding var isModalOpen: Bool
    @Binding var selectedAsset: RealAssetModelWithLocation
    @Binding var navigateToIdentify: Bool
    @State var selectedEmployee: EmployeeModel = EmployeeModel(_id: "", name: "", lastName: "", email: "", assetsAssigned: [])
    @State var showSearchList: Bool = false

    var placeholder = "Search for name, brand, model, EPC or serial number"
    
    var body: some View {
        VStack {
            HStack {
                if selectedEmployee._id != "" {
                    Button("Add Asset") {
                        showSearchList = true
                    }
                }
                Spacer()
                Button("Close") {
                    isModalOpen.toggle()
                }
            }
            .padding(.leading)
            .padding(.trailing)
            .padding(.top, 20)
            
            SearchBox(searchText: $searchText, isSearching: $isSearching, placeHolder: placeholder)
                .padding(.top, 20)
            
            ScrollView(.vertical, showsIndicators: false) {
                
                VStack {
                    LazyVStack {
                        ForEach(getFilteredAssets(), id: \.self) { asset in
                            Button(action: {
                                let _asset = RealAssetModelWithLocation(_id: asset._id, brand: asset.brand, model: asset.model, name: asset.name, EPC: asset.EPC, serial: asset.serial, locationPath: asset.locationPath ?? "", fileExt: asset.fileExt ?? "")
                                selectedAsset = _asset
                                isModalOpen.toggle()
                                navigateToIdentify = true
                            }) {
                                AssetListItemSubview(asset: asset)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showSearchList) {
                    SearchView(cslvalues: cslvalues, fromEmployees: selectedEmployee._id != "", closeModal: $showSearchList, assigned: selectedEmployee._id, selectedEmployee: $selectedEmployee)
                }
                
            }
        }
        .onAppear {
            onAppearLoad()
        }
        .onChange(of: showSearchList) { value in
            if !value {
                onAppearLoad()
            }
        }
    }
    
    func onAppearLoad() {
        if locationId != "" {
            cslvalues.isLoading = true
            ApiAssets().getRealAssets(location: locationId) { assets in
                self.apiAssets = assets
                cslvalues.isLoading = false
            }
        } else if selectedEmployee._id != "" {
            cslvalues.isLoading = true
            var assetIds: [String] = []
            for _asset in selectedEmployee.assetsAssigned ?? [] {
                let assetId = _asset.id ?? ""
                assetIds.append("\"ObjectId('\(assetId)')\"")
            }
            ApiAssets().getRealAssetsForEmployee(assetIds: assetIds) { assets in
                self.apiAssets = assets
                cslvalues.isLoading = false
            }
        }
    }
    
    func getFilteredAssets() -> [RealAssetModel] {
        if (searchText != "" && apiAssets.count > 0) {
            return apiAssets.filter {
                $0.name.range(of: searchText, options: .caseInsensitive) != nil ||
                $0.brand.range(of: searchText, options: .caseInsensitive) != nil ||
                $0.model.range(of: searchText, options: .caseInsensitive) != nil ||
                ($0.EPC ?? "").range(of: searchText, options: .caseInsensitive) != nil ||
                ($0.serial ?? "").range(of: searchText, options: .caseInsensitive) != nil
            }
        } else {
            return apiAssets
        }
    }
}

struct AssetListSubview_Previews: PreviewProvider {
    static var locationId = "606b5e811b8b9f390457a5ff"
    @State static var selectedAsset: RealAssetModelWithLocation = RealAssetModelWithLocation(_id: "", brand: "", model: "", name: "", EPC: "", serial: "")
    static var previews: some View {
        AssetListSubview(cslvalues: CSLValues(), locationId: locationId, isModalOpen: .constant(true), selectedAsset: $selectedAsset, navigateToIdentify: .constant(false))
    }
}
