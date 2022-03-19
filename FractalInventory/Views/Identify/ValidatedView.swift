//
//  ValidatedView.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 28/11/21.
//

import SwiftUI

struct ValidatedView: View {
    @ObservedObject var cslvalues: CSLValues
    @State var apiAssets: [RealAssetModelWithLocation] = []

    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                
                VStack {
                    LazyVStack {
                        ForEach(apiAssets, id: \.self) { asset in
                            NavigationLink(destination: AssetView(cslvalues: cslvalues, asset: asset)) {
                                ValidatedItemSubview(asset: asset)
                            }
                        }
                    }
                }
                
            }.padding(.top)
        }
        .navigationBarTitle("Identified Assets (\(apiAssets.count))", displayMode: .inline)
        .onAppear {
            getValidatedAssets()
        }
    }
    
    func getValidatedAssets() {
        var _epcs: [String] = []
        for tag in cslvalues.readings {
            _epcs.append(tag.epc)
        }
        let params: [String: Any] = ["fieldValues": _epcs]
        
        cslvalues.isLoading = true
        ApiAssets().getValidatedEPCS(params: params) { _existingAssets in
            self.apiAssets = _existingAssets
            cslvalues.isLoading = false
        }
    }
}

struct ValidatedView_Previews: PreviewProvider {
    static var previews: some View {
        ValidatedView(cslvalues: CSLValues())
    }
}
