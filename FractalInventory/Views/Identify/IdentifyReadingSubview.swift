//
//  IdentifyReadingSubview.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 28/11/21.
//

import SwiftUI

struct IdentifyReadingSubview: View {
    @State var reading: EpcModel
    @State var isIpad: Bool = UIScreen.main.bounds.width > 400
    let remove: () -> Void
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "dot.radiowaves.right")
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: isIpad ? 32 : 16, height: isIpad ? 32 : 16, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .padding(.leading, isIpad ? 10 : 0)
                VStack(alignment: .leading) {
                    Text(reading.epc)
                        .font(.subheadline)
                        .fontWeight(isIpad ? .heavy : .semibold)
                        .padding(.top, 5)
                    Text("RSSI: \(reading.rssi)")
                        .font(.caption)
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.secondary)
                    Text(reading.timestamp)
                        .font(.caption)
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, isIpad ? 20 : 0)
                Spacer()
                
                Button(action: remove) {
                    Image(systemName: "trash")
                        .renderingMode(.original)
                        .resizable()
                        .frame(width: 16, height: 20, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .padding(0)
                }
            }
            Divider()
        }
    }
}

struct IdentifyReadingSubview_Previews: PreviewProvider {
    static var previews: some View {
        IdentifyReadingSubview(reading: EpcModel(epc: "ABCDEF0123456789123456AB", rssi: "99.21", timestamp: "04/09/2021 23:14:45"), remove: {})
            .previewLayout(.sizeThatFits)
    }
}
