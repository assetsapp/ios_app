//
//  LocationSubview.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 22/08/21.
//

import SwiftUI

struct LocationSubview: View {
    @ObservedObject var cslvalues: CSLValues
    @State var location: LocationModel
    @State var locationPath: String = ""
    @State var isInventoryModalPresent: Bool = false
    @State var isAssetListModalPresent: Bool = false
    @State var isInventorySessionsModalPresent: Bool = false
    @State var isTypeOfInventoryAlertPresented = false
    @State var navigateToInventory: Bool = false
    @State var sessionId: String = ""
    @State var inventoryName: String = ""
    @State var inventoryType: InventoryType = .root
    @State var selectedAsset: RealAssetModelWithLocation = RealAssetModelWithLocation(_id: "", brand: "", model: "", name: "", EPC: "", serial: "")
    @State var navigateToIdentify: Bool = false

    var body: some View {
            
        VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 0, content: {
            
            HStack {
                
                HStack {

                    Image(systemName: "globe")
                        .renderingMode(.original)
                        .resizable()
                        .frame(width: 20, height: 20, alignment: .center)
                        .foregroundColor(.primary)
                    
                    Text("\(location.name) - (\(location.childrenNumber))")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                }
                
                Spacer()
                
            }.padding(.all, 6)
            

            HStack {
                // MARK: Assets
                NavigationLink(destination: AssetView(cslvalues: cslvalues, asset: selectedAsset), isActive: $navigateToIdentify) {
                    EmptyView()
                }
                
                if location.assetsNumber > 0 {
                    Button(action: { isAssetListModalPresent = true }) {
                        AssetsLabel(assetsNumber: location.assetsNumber)
                    }
                    .sheet(isPresented: $isAssetListModalPresent) {
                        AssetListSubview(cslvalues: cslvalues, locationId:location._id, isModalOpen: $isAssetListModalPresent, selectedAsset: $selectedAsset, navigateToIdentify: $navigateToIdentify)
                    }
                    
                } else {
                    AssetsLabel(assetsNumber: location.assetsNumber)
                }
                
                Spacer()
                
                // MARK: Tag
                NavigationLink(destination: ReferencesView(cslvalues: cslvalues, location: location, locationPath: getLocationPath())) {
                    TaggingLabel()
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                }.padding(.leading)
                
                Spacer()
                
                // MARK: Inventory
                NavigationLink(destination: InventoryView(cslvalues: cslvalues, assets: [], locationPath: getLocationPath(), location: location._id, locationName: location.name, inventorySession: sessionId, inventoryName: inventoryName, type: inventoryType), isActive: $navigateToInventory) {
                    EmptyView()
                }
                Button(action: { isInventoryModalPresent = true }) {
                    InventoryLabel()
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                }
                .padding(.leading)
                .actionSheet(isPresented: $isInventoryModalPresent) {
                    ActionSheet(title: Text("Perform Inventory"),
                                message: Text("Select an action"),
                                buttons: [
                                    .default(Text("Quick Inventory")) {
                                        sessionId = ""
                                        inventoryName = ""
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            self.isTypeOfInventoryAlertPresented = true
                                        }
                                    },
                                    .default(Text("Create Inventory Session")) { alertWithText() },
                                    .default(Text("Continue Inventory Session")) { isInventorySessionsModalPresent = true },
                                    .cancel()
                                ]
                                )
                }
                NavigationLink(destination: InventorySessionSubview(cslvalues: cslvalues, location: location, isModalOpen: .constant(true), locationPath: getLocationPath()), isActive: $isInventorySessionsModalPresent) {
                    EmptyView()
                }
            }
            .padding(.vertical, 5)
            
            Divider()
            
        })
        .padding(.horizontal, 10)
        Divider()
        .actionSheet(isPresented: $isTypeOfInventoryAlertPresented) {
            ActionSheet(title: Text("Inventory Session"), message: Text(getSessionId()), buttons: [
                ActionSheet.Button.default(Text("Only This Level")) {
                    inventoryType = .root
                    navigateToInventory = true
                },
                ActionSheet.Button.default(Text("This Level and sublevels")) {
                    inventoryType = .subLevels
                    navigateToInventory = true
                },
                .cancel() ]
            )
        }
    }
    
    func alertWithText() {
        let _sessionId = getSessionId()
        let alert = UIAlertController(title: "Inventory Session", message: _sessionId, preferredStyle: .alert)
        
        alert.addTextField { field in
            field.placeholder = "Insert Session Name"
            field.text = "Inventory in \(location.name)"
        }
        
        let createSession = UIAlertAction(title: "Create", style: .default) { _ in
            sessionId = _sessionId
            inventoryName = alert.textFields![0].text ?? ""
            DispatchQueue.main.async {
                self.isTypeOfInventoryAlertPresented = true
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            sessionId = ""
            inventoryName = ""
        }

        alert.addAction(cancel)
        alert.addAction(createSession)
        
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: {})
    }
    
    func getSessionId() -> String {
        let _date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmssSSS"

        return "session-id-\(formatter.string(from: _date))"
    }
    
    func getLocationPath() -> String {
        return "\(locationPath) / \(location.name)"
    }
}


struct TaggingLabel: View {
    var body: some View {
        HStack {
            Image(systemName: "tag")
                .resizable()
                .frame(width: 15, height: 15, alignment: .center)
            Text("Tag")
                .font(.callout)
                .fontWeight(.light)
                .foregroundColor(.blue)
        }
    }
}

struct InventoryLabel: View {
    var body: some View {
        HStack {
            Image(systemName: "wave.3.right")
                .resizable()
                .frame(width: 13, height: 15, alignment: .center)
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            Text("Inventory")
                .font(.callout)
                .fontWeight(.light)
                .foregroundColor(.blue)
        }
        .padding(.trailing, 10)
    }
}

struct LocationsLabel: View {
    @State var locationNumber: Int
    
    var body: some View {
        HStack {
            Image(systemName: "location")
                .resizable()
                .frame(width: 15, height: 15, alignment: .center)
                .foregroundColor(.primary)
            Text("Locs: \(locationNumber)")
                .font(.callout)
                .fontWeight(.light)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
    }
}

struct AssetsLabel: View {
    @State var assetsNumber: Int
    
    var body: some View {
        HStack {
            Image(systemName: "laptopcomputer")
                .resizable()
                .frame(width: 15, height: 10, alignment: .center)
                .foregroundColor(assetsNumber > 0 ? .blue : .primary)
            
            Text("Assets: \(assetsNumber)")
                .font(.callout)
                .fontWeight(.light)
                .foregroundColor(assetsNumber > 0 ? .blue : .primary)
        }
        .padding(.leading, 10)
    }
}

struct LocationSubview_Previews: PreviewProvider {
    
    static var location: LocationModel = LocationModel(_id: "ab6", name: "Mexico City", type: "region", level: 0, childrenNumber: 22, assetsNumber: 51, canTag: true, canInventory: true, path: "path")
    
    static var previews: some View {
        LocationSubview(cslvalues: CSLValues(), location: location)
            .previewDevice("iPhone 12 mini")
            .previewLayout(.sizeThatFits)
    }
}
