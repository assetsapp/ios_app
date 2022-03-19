//
//  ReadingSubview.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 04/09/21.
//

import SwiftUI

struct ReadingSubview: View {
    
    @ObservedObject var cslvalues: CSLValues
    @State var reading: EpcModel
    @State var isIpad: Bool = UIScreen.main.bounds.width > 400
    @State var barcodeMode: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: barcodeMode ? "barcode" : "dot.radiowaves.right")
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: isIpad ? 32 : 16, height: isIpad ? 32 : 16, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .padding(.leading, isIpad ? 10 : 0)
                VStack(alignment: .leading) {
                    Text(reading.epc)
                        .font(.subheadline)
                        .fontWeight(isIpad ? .heavy : .semibold)
                        .padding(.top, 5)
                    if !barcodeMode {
                        Text("RSSI: \(reading.rssi)")
                            .font(.caption)
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .foregroundColor(.secondary)
                    }
                    Text(reading.timestamp)
                        .font(.caption)
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, isIpad ? 20 : 0)
                Spacer()
                
                Button(action: { cslvalues.removeEpc(epc: reading.epc) }) {
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

struct ReadingSubview_Previews: PreviewProvider {
    static var previews: some View {
        ReadingSubview(cslvalues: CSLValues(), reading: EpcModel(epc: "ABCDEF0123456789123456AB", rssi: "99.21", timestamp: "04/09/2021 23:14:45"))
            .previewLayout(.sizeThatFits)
    }
}
