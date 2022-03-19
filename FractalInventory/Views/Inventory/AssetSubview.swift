//
//  AssetSubview.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 25/09/21.
//

import SwiftUI

struct AssetSubview: View {
    
    @State var asset: AssetModel
    @State var status: StatusSet = StatusSet(backgroundColor: Color.red, foregroundColor: Color.primary, icon: Image(systemName: "questionmark.circle"))
    @State var showMoveExternalAssetModal: Bool = false
    @State var locationId: String
    @State var locationPath: String = ""
    @Binding var assets: [AssetModel]
    @Binding var inventoryUpdates: [String]
    @State var sessionId: String = ""

    var body: some View {
        VStack {
            HStack {
                if asset.status == "external" {
                    Button(action: { showMoveExternalAssetModal.toggle() }) {
                        status.icon
                            .resizable()
                            .frame(width: 40, height: 40, alignment: .center)
                    }
                    .alert(isPresented: $showMoveExternalAssetModal, content: {
                        Alert(
                            title: Text("External Asset"),
                            message: Text("Do you want to move this asset to this location?"),
                            primaryButton: .default(Text("OK"), action: { moveAssetToThisLocation(EPC: asset.EPC ?? "") }),
                            secondaryButton: .cancel(Text("Cancel"))
                        )
                    })
                } else {
                    status.icon
                        .resizable()
                        .frame(width: 40, height: 40, alignment: .center)
                }
                
                VStack(alignment: .leading, spacing: nil) {
                    Text(asset.name)
                        .font(.headline)
                    Text(asset.brand)
                        .font(.footnote)
                    Text(asset.model)
                        .font(.footnote)
                    Text("SN: \(asset.serial ?? "")")
                        .font(.footnote)
                    if asset.status == "external" {
                        Text("Origin: \(asset.locationPath)")
                            .font(.footnote)
                    }
                    Text(asset.EPC ?? "")
                        .font(.callout)
                }
                .padding(.leading)
                
                Spacer()
            }
            .padding(.all, 5)
            .padding(.leading)
            
        }
        .background(status.backgroundColor)
        .foregroundColor(status.foregroundColor)
        .onAppear {
            switch asset.status {
            case "found":
                status = StatusSet(backgroundColor: Color.green, foregroundColor: Color.white, icon: Image(systemName: "checkmark.circle"))
            case "external":
                status = StatusSet(backgroundColor: Color.orange, foregroundColor: Color.white, icon: Image(systemName: "arrow.backward.circle"))
            case "missing":
                status = StatusSet(backgroundColor: Color.red, foregroundColor: Color.primary, icon: Image(systemName: "questionmark.circle"))
            default:
                break
            }
        }
    }
    
    func moveAssetToThisLocation(EPC: String) {
        ApiAssets().moveAssetToLocation(assetId: asset._id, locationId: locationId, locationPath: filterOutLocationPath()) {
            let foundAssetIndex = assets.firstIndex { $0.EPC == EPC } ?? -1
            if foundAssetIndex >= 0 {
                assets[foundAssetIndex].status = "found"
                let foundEPC = assets[foundAssetIndex].EPC
                inventoryUpdates.append(foundEPC ?? "")
                pushAssetToSession()
            }
        }
    }
    
    func filterOutLocationPath() -> String {
        let locArray = locationPath.components(separatedBy: " / ")
        let locStr = locArray.joined(separator: "/")

        return locStr.count > 0 ? String(locStr.suffix(locStr.count - 1)) : ""
    }
    
    func pushAssetToSession() {
        if sessionId != "" {
            let _asset: [String: Any] = [
                "_id": asset._id,
                "name" : asset.name,
                "brand" : asset.brand,
                "model" : asset.model,
                "serial" : asset.serial,
                "location" : locationId,
                "EPC" : asset.EPC,
                "status" : "found"
            ]
            let params: [String: Any] = [
                "sessionId": sessionId,
                "asset": _asset
            ]
            ApiInventorySessions().pushAssetToInventorySession(params: params) { 
            }
        }
    }
    
}

struct StatusSet {
    var backgroundColor: Color
    var foregroundColor: Color
    var icon: Image
}

struct AssetSubview_Previews: PreviewProvider {
    static var asset = AssetModel(_id: "ABC1", brand: "Apple", model: "Mackbook Pro", name: "Laptop", EPC: "ABCDEF01234567890123AB00", serial: "qwerty0210", location: "", status: "external", locationPath: "Canada/Quebec")
    @State static var assets: [AssetModel] = []
    @State static var inventoryUpdates: [String] = []
    
    static var previews: some View {
        AssetSubview(asset: asset, locationId: "", assets: $assets, inventoryUpdates: $inventoryUpdates)
            .previewDevice("iPhone 11")
            .previewLayout(.sizeThatFits)
    }
}
