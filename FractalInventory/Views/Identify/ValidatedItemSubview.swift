//
//  ValidatedItemSubview.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 29/11/21.
//

import SwiftUI

struct ValidatedItemSubview: View {
    @State var asset: RealAssetModelWithLocation
    @State var fromEmployees: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "ipad.badge.play")
                    .resizable()
                    .frame(width: 40, height: 40, alignment: .center)
                
                VStack(alignment: .leading, spacing: nil) {
                    Text(asset.name)
                        .font(.headline)
                    Text(asset.brand ?? "")
                        .font(.footnote)
                    Text(asset.model ?? "")
                        .font(.footnote)
                    Text("SN: \(asset.serial ?? "")")
                        .font(.footnote)
                    Text("Origin: \(asset.locationPath ?? "")")
                        .font(.footnote)
                    if fromEmployees {
                        Text("Assigned To: \(asset.assignedTo ?? "")")
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
            
            Divider()
        }
    }
}

struct ValidatedItemSubview_Previews: PreviewProvider {
    static var asset = RealAssetModelWithLocation(_id: "id", brand: "Apple", model: "Macbook", name: "Laptop", EPC: "4343242342342", serial: "SN", locationPath: "Canada/Quebec", assigned: "codeassigned", assignedTo: "Name and <email>")
    
    static var previews: some View {
        ValidatedItemSubview(asset: asset)
            .scaledToFit()
    }
}
