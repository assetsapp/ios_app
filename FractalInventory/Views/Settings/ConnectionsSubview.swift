//
//  ConnectionsSubview.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 24/10/21.
//

import SwiftUI

struct ConnectionsSubview: View {
    @ObservedObject var cslvalues: CSLValues
    @AppStorage(Settings.apiHostKey) var apiHost = Constants.apiHost
    @AppStorage(Settings.apiDBKey) var apiDB = Constants.apiDB
    @State var testType: Int = 0
    @State var testResult: String = ""
    @State var showTestModal: Bool = false
    var testTypes = ["API", "DB"]
    @State var apiHostOrig = ""
    @State var apiDBOrig = ""
    @State var showUpdateModal: Bool = false
    @Binding var isUserLoggedOut: Bool
    @State var fromSettings: Bool = true
    
    var body: some View {
        VStack {
            Text("Any change will require you to log in again")
                .foregroundColor(.secondary)
            TextField("API Host", text: $apiHost)
            TextField("API Client", text: $apiDB)
            HStack {
                Picker("Mode", selection: $testType) {
                    Text("API").tag(0)
                    Text("DB").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 130)
                Spacer()
                Button(action: { testConnection() } ) {
                    Text("Test Connection")
                }
                .alert(isPresented: $showTestModal, content: {
                    Alert(
                        title: Text("Test \(testTypes[testType]) Connection: \(testResult)"),
                        dismissButton: .default(Text("OK"), action: { testResult = "" })
                    )
                })
            }
        }
        .onAppear {
            self.apiHostOrig = apiHost
            self.apiDBOrig = apiDB
        }
        .onDisappear {
            if (fromSettings && (apiHostOrig != apiHost || apiDBOrig != apiDB)) {
                UserDefaults.standard.removeObject(forKey: Settings.userTokenKey)
                UserDefaults.standard.removeObject(forKey: Settings.userNameKey)
                UserDefaults.standard.removeObject(forKey: Settings.userIdKey)
                UserDefaults.standard.removeObject(forKey: Settings.userLastNameKey)
                UserDefaults.resetStandardUserDefaults()
                isUserLoggedOut = true
            }
        }
    }
    
    func testConnection() {
        cslvalues.isLoading = true
        if testType == 0 {
            ApiTesting().testApiConnection() { result in
                testResult = result
                showTestModal = true
                cslvalues.isLoading = false
            }
        } else {
            ApiTesting().testDBConnection() { result in
                testResult = result
                showTestModal = true
                cslvalues.isLoading = false
            }
        }
    }
}

struct ConnectionsSubview_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionsSubview(cslvalues: CSLValues(), isUserLoggedOut: .constant(false))
    }
}
