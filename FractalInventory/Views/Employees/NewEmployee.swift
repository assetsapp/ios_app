//
//  NewEmployee.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 23/12/21.
//

import SwiftUI

struct NewEmployee: View {
    @ObservedObject var cslvalues: CSLValues
    @Binding var showModal: Bool
    @State var name: String = ""
    @State var lastName: String = ""
    @State var employeeId: String = ""
    @State var email: String = ""
    @State var closeModal: Bool = false
    @State var showAlert: Bool = false
    @State var alertMessage: String = ""

    
    @State var profileNames: [String] = []
    @State var profileIds: [String] = []
    @State var selectedProfileName = ""
    
    var body: some View {
        VStack {
            HStack {
                Button("Save") {
                    onSave()
                }
                Spacer()
                Button("Close") {
                    showModal.toggle()
                }
            }.padding()
            
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Select a Profile:")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Picker("Select a Profile:", selection: $selectedProfileName) {
                        ForEach(profileNames, id:\.self) { profileName in
                            Text(profileName)
                        }
                    }
                    
                    Text("Name:")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    TextField("Insert Name", text: $name)
                    
                    Text("Last Name:")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    TextField("Insert Last Name", text: $lastName)
                    
                    Text("Employee Id:")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    TextField("Insert Employee Id", text: $employeeId)
                    
                    Text("Email:")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    TextField("Insert Email", text: $email)
                }
                .padding()
            }
            
            Spacer()
        }
        .alert(isPresented: $showAlert, content: {
            Alert(
                title: Text(alertMessage),
                dismissButton: .default(Text("OK"), action: {
                    if closeModal {
                        showModal.toggle()
                    }
                })
            )
        })
        .onAppear {
            cslvalues.isLoading = true
            ApiEmployees().getEmployeeProfiles { profiles in
                if profiles.count > 0 {
                    selectedProfileName = profiles[0].name
                    for profile in profiles {
                        profileIds.append(profile._id)
                        profileNames.append(profile.name)
                    }
                } else {
                    alertMessage = "There are no Employee Profiles. Please, first create at least one"
                    closeModal = true
                    showAlert = true
                }
                cslvalues.isLoading = false
            }
        }
    }
    
    func onSave() {
        if name == "" || lastName == "" || employeeId == "" || email == "" {
            alertMessage = "Please fill all fields"
            showAlert = true
        } else {
            cslvalues.isLoading = true
            let selectedProfileIx = profileNames.firstIndex(of: selectedProfileName)
            let selectedProfile: [String:String] = [
                "value": profileIds[selectedProfileIx ?? 0],
                "label": profileNames[selectedProfileIx ?? 0]
            ]
            let params: [String:Any] = [
                "name": name,
                "lastName": lastName,
                "employee_id": employeeId,
                "email": email,
                "employeeProfile": selectedProfile,
                "assetsAssigned": []
            ]
            ApiEmployees().postEmployee(params: params) {
                cslvalues.isLoading = false
                showModal.toggle()
            }
        }
    }
}

struct NewEmployee_Previews: PreviewProvider {
    static var previews: some View {
        NewEmployee(cslvalues: CSLValues(), showModal: .constant(false))
    }
}
