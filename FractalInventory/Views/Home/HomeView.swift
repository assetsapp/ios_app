//
//  HomeView.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 24/10/21.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var cslvalues: CSLValues = CSLValues()
    @State var isUserLoggedOut: Bool = true

    var body: some View {
            ZStack {
                CSLDelegates(cslvalues: cslvalues)
                    .frame(height: 0)
                DashboardView(cslvalues: cslvalues, isUserLoggedOut: $isUserLoggedOut)
                    .alert(isPresented: $cslvalues.showNonConnected, content: {
                        Alert(
                            title: Text("RFID device is not connected"),
                            dismissButton: .cancel(Text("OK"), action: {})
                        )
                    })
                if isUserLoggedOut {
                    LogInView(cslvalues: cslvalues, isUserLoggedOut: $isUserLoggedOut)
                }
                if cslvalues.isLoading {
                    Loading()
                }
            }
            .onAppear {
                cslvalues.isLoading = true
                ApiTesting().testToken() { result in
                    isUserLoggedOut = result != "Successful"
                    cslvalues.isLoading = false
                }
            }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
