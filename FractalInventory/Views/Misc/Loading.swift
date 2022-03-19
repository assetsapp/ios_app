//
//  Loading.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 09/12/21.
//

import SwiftUI

struct Loading: View {
    var body: some View {
        ZStack {
            Color(.black)
                .ignoresSafeArea()
                .opacity(0.5)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(3)
        }
    }
}

struct Loading_Previews: PreviewProvider {
    static var previews: some View {
        Loading()
    }
}
