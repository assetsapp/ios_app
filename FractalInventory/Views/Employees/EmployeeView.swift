//
//  EmployeeView.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 20/12/21.
//

import SwiftUI

struct EmployeeView: View {
    
    @ObservedObject var cslvalues: CSLValues
    @State var apiEmployees: [EmployeeModel] = []
    @State var searchText = ""
    @State var isSearching = false
    @State var isModal: Bool = false
    @State var isAssetListPresent: Bool = false
    @State var navigateToIdentify: Bool = false
    @Binding var showModal: Bool
    @Binding var selectedEmployee: EmployeeModel
    @State var selectedAsset: RealAssetModelWithLocation = RealAssetModelWithLocation(_id: "", brand: "", model: "", name: "", EPC: "", serial: "")
    @State var showAddEmployee: Bool = false
    let workModeManager = WorkModeManager()
    
    var body: some View {
        VStack {
            if isModal {
                VStack {
                    HStack {
                        Spacer()
                        Button("Close") {
                            showModal.toggle()
                        }
                        .padding(.trailing)
                        .padding(.top)
                    }
                    Text("Search Employees (\(getFilteredEmployees().count))")
                        .font(.title)
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                        .padding(.top, 3)
                }
            }
            
            EmployeeSearchBox(searchText: $searchText, isSearching: $isSearching)
                .padding(.top, isModal ? 0 : 20)
            
            ScrollView(.vertical, showsIndicators: false) {
                
                // MARK: Assets
                NavigationLink(destination: AssetView(cslvalues: cslvalues, asset: selectedAsset), isActive: $navigateToIdentify) {
                    EmptyView()
                }
                
                VStack {
                    LazyVStack {
                        ForEach(getFilteredEmployees(), id: \.self) { employee in
                            VStack {
                                Button (action: {
                                    selectedEmployee = employee
                                    if isModal {
                                        showModal.toggle()
                                    } else {
                                        isAssetListPresent.toggle()
                                    }
                                }) {
                                    EmployeeSubview(employee: employee)
                                }
                                .sheet(isPresented: $isAssetListPresent) {
                                    AssetListSubview(cslvalues: cslvalues, locationId:"", isModalOpen: $isAssetListPresent, selectedAsset: $selectedAsset, navigateToIdentify: $navigateToIdentify, selectedEmployee: selectedEmployee)
                                }
                            }
                        }
                    }
                }
                
            }
            .padding(.top, 5)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("Employees (\(getFilteredEmployees().count))")
            .navigationBarItems(trailing:
                                    HStack {
                Button("Add") {
                    showAddEmployee.toggle()
                }
                .sheet(isPresented: $showAddEmployee) {
                    NewEmployee(cslvalues: cslvalues, showModal: $showAddEmployee)
                }
            }
            )
        }
        .onChange(of: isAssetListPresent) { value in
            if !value {
                onAppearLoad()
            }
        }
        .onChange(of: showAddEmployee) { value in
            if !value {
                onAppearLoad()
            }
        }
        .onAppear {
            onAppearLoad()
        }
    }
    
    // MARK: FUNCTIONS
    func getFilteredEmployees() -> [EmployeeModel] {
        if (searchText != "" && apiEmployees.count > 0) {
            return apiEmployees.filter {
                $0.name.range(of: searchText, options: .caseInsensitive) != nil ||
                $0.lastName.range(of: searchText, options: .caseInsensitive) != nil ||
                ($0.employee_id ?? "").range(of: searchText, options: .caseInsensitive) != nil ||
                $0.email.range(of: searchText, options: .caseInsensitive) != nil
            }
        } else {
            return apiEmployees
        }
    }
    
    func onAppearLoad() {
        cslvalues.isLoading = true
        switch workModeManager.workMode {
        case .online:
            ApiEmployees().getEmployees { result in
                switch result {
                case .success(let employees):
                    self.apiEmployees = employees
                case .failure(_ ):
                    self.apiEmployees = []
                }
                cslvalues.isLoading = false
            }
        case .offline:
            workModeManager.getEmployees { result in
                switch result {
                case .success(let employees):
                    self.apiEmployees = employees
                case .failure(_ ):
                    self.apiEmployees = []
                }
                cslvalues.isLoading = false
            }
        }
    }
}

struct EmployeeSearchBox: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @State var placeHolder: String = "Search using Name, ID or email"
    
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

struct EmployeeView_Previews: PreviewProvider {
    @State static var emp = EmployeeModel(_id: "", name: "", lastName: "", email: "")
    static var previews: some View {
        EmployeeView(cslvalues: CSLValues(), showModal: .constant(false), selectedEmployee: $emp)
    }
}
