//
//  InventorySessionSubview.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 10/10/21.
//

import SwiftUI

struct InventorySessionSubview: View {
    @ObservedObject var cslvalues: CSLValues
    @State var location: LocationModel?
    @Binding var isModalOpen: Bool?
    @State var isSearching = true
    @State var searchText = ""
    @State var apiInventorySessions: [InventoryDataModel] = []
    @State var locationPath: String = "Location Path"
    var placeholder = "Search for session id or name"
    @State var isClosedSessionsFilter: Bool = false
    @State var reopenSessionModal: Bool = false
    @State var navigateToInventory: Bool = false
    let workModeManager = WorkModeManager()
    
    var body: some View {
        VStack {
            
            VStack {
                SearchBox(searchText: $searchText, isSearching: $isSearching, placeHolder: placeholder)
                HStack {
                    Spacer()
                    Toggle("Closed Sessions", isOn: $isClosedSessionsFilter)
                        .toggleStyle(SwitchToggleStyle(tint: .gray))
                        .frame(width: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.top, 20)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    LazyVStack {
                        ForEach(getFilteredSessions(), id: \.self) { session in
                            if session.status == "open" {
                                NavigationLink(destination: EmptyView()) {
                                    EmptyView()
                                }
                                NavigationLink(destination: InventoryView(cslvalues: cslvalues, locationPath: locationPath, location: session.locationId, inventorySession: session.sessionId, inventoryName: session.name, isExistingSession: true)) {
                                    InventorySessionItemSubview(session: session)
                                }
                            } else {
                                Button(action: { reopenSessionModal.toggle() }) {
                                    VStack {
                                        InventorySessionItemSubview(session: session)
                                        NavigationLink(destination: InventoryView(cslvalues: cslvalues, locationPath: locationPath, location: session.locationId, inventorySession: session.sessionId, inventoryName: session.name, isExistingSession: true), isActive: $navigateToInventory) {
                                            EmptyView()
                                        }
                                    }
                                }
                                .alert(isPresented: $reopenSessionModal, content: {
                                    Alert(
                                            title: Text("Inventory Session"),
                                            message: Text("Do you want to reopen the session?"),
                                            primaryButton: .default(Text("OK"), action: {
                                                openInventorySession(id: session._id)
                                                navigateToInventory = true
                                            }),
                                            secondaryButton: .cancel(Text("Cancel"))
                                        )
                                })
                            }
                        }
                    }
                }
            }
            
        }
        .navigationBarTitle("Inventories", displayMode: .inline)
        .onAppear {
            cslvalues.isLoading = true
            switch workModeManager.workMode {
            case .online:
                ApiInventorySessions().getInventorySessions(location: location?._id ?? "" ) { result in
                    switch result {
                    case .success(let inventorySessions):
                        self.apiInventorySessions = inventorySessions
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    cslvalues.isLoading = false
                }
            case .offline:
                DataManager().getInventories { result in
                    switch result {
                    case .success(let inventorySessions):
                        self.apiInventorySessions = inventorySessions
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    cslvalues.isLoading = false
                }
            }
            isClosedSessionsFilter = false
        }
    }
    
    func getFilteredSessions() -> [InventoryDataModel] {
        var visibleSessions: [InventoryDataModel] = []
        if (searchText != "" && apiInventorySessions.count > 0) {
            visibleSessions = apiInventorySessions.filter {
                $0.name.range(of: searchText, options: .caseInsensitive) != nil ||
                $0.sessionId.range(of: searchText, options: .caseInsensitive) != nil
            }
        } else {
            visibleSessions = apiInventorySessions
        }
        
        return visibleSessions.filter {
            $0.status == (isClosedSessionsFilter ? "closed" : "open")
        }
    }
    
    func openInventorySession(id: String) {
        switch workModeManager.workMode {
        case .online:
            ApiInventorySessions().updateInventorySessionStatus(id: id, status: "open")
        case .offline:
            DataManager().updateInventory(by: id, status: "open") { result in
                
            }
        }
    }
}



struct InventorySessionSubview_Previews: PreviewProvider {
    static var location: LocationModel = LocationModel(_id: "606b5e811b8b9f390457a5ff", name: "Mexico City", type: "region", level: 0, childrenNumber: 22, assetsNumber: 51, canTag: true, canInventory: true, path: "path")
    
    static var previews: some View {
        InventorySessionSubview(cslvalues: CSLValues(), location: location, isModalOpen: .constant(true))
    }
}
