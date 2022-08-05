//
//  InventorySessionItemSubview.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 10/10/21.
//

import SwiftUI

struct InventorySessionItemSubview: View {
    @State var session: InventoryDataModel
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "square.and.pencil")
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 50, height: 50, alignment: .center)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: nil) {
                    Text(session.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(session.sessionId)
                        .font(.footnote)
                        .foregroundColor(.primary)
                    Text("Status: \(session.status)")
                        .font(.footnote)
                        .foregroundColor(.primary)
                    Text("Created: \(session.creation)")
                        .font(.footnote)
                        .foregroundColor(.primary)
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

struct InventorySessionItemSubview_Previews: PreviewProvider {
    static var session: InventoryDataModel = InventoryDataModel(_id: "id", sessionId: "seid", name: "sename", locationId: "asxd", locationName: "testLN", status: "open", creation: "date")
    
    static var previews: some View {
        InventorySessionItemSubview(session: session)
            .previewLayout(.sizeThatFits)
    }
}
