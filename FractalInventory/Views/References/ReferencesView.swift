//
//  ReferencesView.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 28/08/21.
//

import SwiftUI

struct ReferencesView: View {
    @ObservedObject var cslvalues: CSLValues
    @State var apiReferences: [ReferenceModel] = []
    @State var searchText = ""
    @State var isSearching = false
    @State var location: LocationModel
    @State var locationPath: String = ""
    
    var body: some View {
        
            VStack {
                SearchBox(searchText: $searchText, isSearching: $isSearching)
                    .padding(.top, 20)
    
                ScrollView(.vertical, showsIndicators: false) {
                    
                    VStack {
                        LazyVStack {
                            ForEach(getFilteredReferences(), id: \.self) { reference in
                                VStack {
                                    NavigationLink(destination: TaggingView(cslvalues: cslvalues, reference: reference, location: location, customFields: responseObj(), locationPath: locationPath)) {
                                        ReferenceSubview(reference: reference)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    }
                    
                }
                .padding(.top, 5)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarTitle("References (\(apiReferences.count))")
            }
            .onAppear {
                print("OnAppear List!")
                cslvalues.isLoading = true
                ApiReferences().getReferences { references in
                    self.apiReferences = references
                    cslvalues.isLoading = false
                }
            }
        
    }

    // MARK: FUNCTIONS
    func getFilteredReferences() -> [ReferenceModel] {
        if (searchText != "" && apiReferences.count > 0) {
            return apiReferences.filter {
                ($0.name ?? "").range(of: searchText, options: .caseInsensitive) != nil ||
                ($0.brand ?? "").range(of: searchText, options: .caseInsensitive) != nil ||
                ($0.model ?? "").range(of: searchText, options: .caseInsensitive) != nil
            }
        } else {
            return apiReferences
        }
    }
}

struct SearchBox: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @State var placeHolder: String = "Search using Description, Brand, or Model"
    
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

struct ReferencesView_Previews: PreviewProvider {
    static var location: LocationModel = LocationModel(_id: "606b5e811b8b9f390457a5ff", name: "Quebec", type: "City", level: 2, childrenNumber: 5, assetsNumber: 15, canTag: true, canInventory: true, path: "Mexico / CDMX / Santa Fe / Punta / Floor 14 / Quebec")
    static var previews: some View {
        ReferencesView(cslvalues: CSLValues(), location: location)
    }
}
