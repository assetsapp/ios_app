//
//  AssetListItemSubview.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 11/10/21.
//

import SwiftUI

struct AssetListItemSubview: View {
    @State var asset: RealAssetModel
    
    var body: some View {
        HStack {
            Image(systemName: "ipad.badge.play")
                .resizable()
                .frame(width: 50, height: 50, alignment: .center)
            
            VStack(alignment: .leading, spacing: nil) {
                Text(asset.name)
                    .font(.headline)
                Text(asset.brand)
                    .font(.footnote)
                Text(asset.model)
                    .font(.footnote)
                Text("SN: \(asset.serial ?? "")")
                    .font(.footnote)
                Text("EPC: \(asset.EPC ?? "")")
                    .font(.callout)
            }
            .padding(.leading)
            
            Spacer()
        }
        .foregroundColor(.black)
        .padding(.all, 5)
        .padding(.leading)
    }
}

struct AssetListItemSubview_Previews: PreviewProvider {
    static var asset = RealAssetModel(_id: "id", brand: "Apple", model: "Macbook", name: "Laptop", EPC: "4343242342342", serial: "SN")
    
    static var previews: some View {
        AssetListItemSubview(asset: asset)
    }
}
