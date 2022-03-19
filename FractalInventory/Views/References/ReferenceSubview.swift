//
//  ReferenceSubview.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 28/08/21.
//

import SwiftUI

struct ReferenceSubview: View {
    
    @State var reference: ReferenceModel
    
    var body: some View {
        
        VStack {
            HStack {
                Image(systemName: "tag")
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 50, height: 50, alignment: .center)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: nil) {
                    Text(reference.name ?? "")
                        .font(.headline)
                    Text(reference.brand ?? "")
                        .font(.footnote)
                    Text(reference.model ?? "")
                        .font(.footnote)
                }
                .padding(.leading)
                
                Spacer()
            }
            .padding(.all, 10)
            .padding(.leading)
            
            Divider()
                .padding(.horizontal)
        }
    }
}

struct ReferenceSubview_Previews: PreviewProvider {
    
    static var url = "https://cdn.pocket-lint.com/r/s/970x/assets/images/152137-laptops-review-apple-macbook-pro-2020-review-image1-pbzm4ejvvs.jpg"
    static var reference: ReferenceModel = ReferenceModel(_id: "ABCDEF12345", brand: "Apple", model: "Macbook Pro", name: "Laptop", fileExt: url)
    
    static var previews: some View {
        ReferenceSubview(reference: reference)
            .previewLayout(.sizeThatFits)
    }
}
