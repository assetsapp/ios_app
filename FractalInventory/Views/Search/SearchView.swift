//
//  SearchView.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 30/11/21.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var cslvalues: CSLValues
    @State var isSearching = false
    @State var searchText = ""
    @State var apiAssets: [RealAssetModelWithLocation] = []
    @State var fromEmployees: Bool = false
    @Binding var closeModal: Bool
    @State var assigned: String = ""
    @State var showAssetToSameEmployee: Bool = false
    @State var showAssetAlreadyAssigned: Bool = false
    @State var showAssetAssign: Bool = false
    @State var assignAssetMessage: String = ""
    @State var showAssignAlert: Bool = false
    @Binding var selectedEmployee: EmployeeModel
    @State var selectedAsset: RealAssetModelWithLocation = RealAssetModelWithLocation(_id: "", brand: "", model: "", name: "")
    @State var oldEmployeeId: String = ""

    var body: some View {
        VStack {
            
            if fromEmployees {
                HStack {
                    Spacer()
                    Button("Search") {
                        cslvalues.isLoading = true
                        ApiAssets().getSearchAssets(searchText: searchText) { _resultAssets in
                            self.apiAssets = _resultAssets
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            cslvalues.isLoading = false
                        }
                    }
                    .disabled(searchText.count < 2)
                }.padding()
            }
            
            AssetSearchBox(searchText: $searchText, isSearching: $isSearching)
                .padding(.top, fromEmployees ? 0 : 5)
            
            ScrollView(.vertical, showsIndicators: false) {
                
                VStack {
                    LazyVStack {
                        ForEach(apiAssets, id: \.self) { asset in
                            if fromEmployees {
                                Button(action: {
                                    selectedAsset = asset
                                    if assigned == asset.assigned {
                                        assignAssetMessage = "The asset is already assigned to the current Employee"
                                        showAssignAlert.toggle()
                                        showAssetToSameEmployee.toggle()
                                    } else if asset.assigned ?? "" != "" {
                                        assignAssetMessage = "The asset is already assigned to \(asset.assignedTo ?? ""). Do you want to reassign it?"
                                        oldEmployeeId = asset.assigned ?? ""
                                        showAssignAlert.toggle()
                                    } else {
                                        assignAssetMessage = "Do you want to assign this asset?"
                                        oldEmployeeId = ""
                                        showAssignAlert.toggle()
                                    }
                                }) {
                                    ValidatedItemSubview(asset: asset, fromEmployees: fromEmployees)
                                        .foregroundColor(.black)
                                }
                                .alert(isPresented: $showAssignAlert) {
                                    Alert(
                                        title: Text("Asset assignment"),
                                        message: Text(assignAssetMessage),
                                        primaryButton: .default(Text("OK")) {
                                            if showAssetToSameEmployee {
                                            } else {
                                                assignAssetToEmployee()
                                            }
                                        },
                                        secondaryButton: .default(Text("Cancel")) {
                                        }
                                    )
                                }
                            } else {
                                NavigationLink(destination: AssetView(cslvalues: cslvalues, asset: asset, serialNumber: asset.serial ?? "")) {
                                    ValidatedItemSubview(asset: asset, fromEmployees: fromEmployees)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                }
                
            }.padding(.top)
            
            Spacer()
        }
        .onChange(of: searchText)  { _text in
            if _text == "" {
                apiAssets = []
            }
        }
        .navigationBarTitle("Search Assets (\(apiAssets.count))", displayMode: .inline)
        .navigationBarItems(trailing:
                                HStack {
                                    Button("Search") {
                                        cslvalues.isLoading = true
                                        ApiAssets().getSearchAssets(searchText: searchText) { _resultAssets in
                                            self.apiAssets = _resultAssets
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                            cslvalues.isLoading = false
                                        }
                                    }
                                    .disabled(searchText.count < 2)
                                }
        )
    }
    
    func assignAssetToEmployee() {
        cslvalues.isLoading = true
        ApiAssets().assignEmployeeToAsset(assetId: selectedAsset._id, employee: selectedEmployee) {
            let params: [String: Any] = [
                "id": selectedAsset._id,
                "name": selectedAsset.name,
                "brand": selectedAsset.brand ?? "",
                "model": selectedAsset.model ?? "",
                "EPC": selectedAsset.EPC ?? "",
                "serial": selectedAsset.serial ?? "",
                "oldEmployeeId": oldEmployeeId
            ]
            ApiEmployees().assignAssetToEmployee(params: params, employeeId: selectedEmployee._id) {
                cslvalues.isLoading = false
                let newAssetAssigned = AssetsAssigned(id: selectedAsset._id, name: selectedAsset.name, brand: selectedAsset.brand, model: selectedAsset.model, assigned: true, serial: selectedAsset.serial, EPC: selectedAsset.EPC, creationDate: "")
                selectedEmployee.assetsAssigned?.append(newAssetAssigned)
                closeModal.toggle()
            }
        }
    }
}

struct AssetSearchBox: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @State var placeHolder: String = "Search using Description, Brand, Model, EPC, and serial"
    
    var body: some View {
        
        HStack {
            HStack {
                TextField(placeHolder, text: $searchText)
                    .padding()
                    .padding(.leading, 30)
                    .padding(.trailing, searchText != "" ? 30 : 0)
                
            }
            .background(Color(.systemGray6))
            .cornerRadius(6)
            .padding(.horizontal)
            .onTapGesture {
                isSearching = true
            }
            .overlay(
                HStack {
                    Image(systemName: "magnifyingglass")
                    Spacer()
                    
                }
                .padding(.horizontal, 30)
                .foregroundColor(.gray)
            )
            .transition(.move(edge: .trailing))
            .animation(.spring())
        
            if (isSearching) {
                Button(action: {
                    isSearching = false
                    searchText = ""
                    
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Text("Cancel")
                        .padding(.trailing)
                        .padding(.leading, 0)
                }
                .transition(.move(edge: .trailing))
                .animation(.spring())
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    @State static var selectedEmployee: EmployeeModel = EmployeeModel(_id: "", name: "", lastName: "", email: "", assetsAssigned: [])
    static var previews: some View {
        SearchView(cslvalues: CSLValues(), closeModal: .constant(false), selectedEmployee: $selectedEmployee)
    }
}
