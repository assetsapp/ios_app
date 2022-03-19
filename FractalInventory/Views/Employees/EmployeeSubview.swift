//
//  EmployeeSubview.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 20/12/21.
//

import SwiftUI

struct EmployeeSubview: View {
    
    @State var employee: EmployeeModel
    
    var body: some View {
        HStack {
            Image(systemName: "person")
                .renderingMode(.original)
                .resizable()
                .frame(width: 50, height: 50, alignment: .center)
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: nil) {
                Text("\(employee.name) \(employee.lastName)")
                    .font(.headline)
                    .foregroundColor(.black)
                Text("ID: \(employee.employee_id ?? "")")
                    .font(.footnote)
                    .foregroundColor(.black)
                Text(employee.email)
                    .font(.footnote)
                    .foregroundColor(.black)
                Text("Assets: \((employee.assetsAssigned ?? []).count)")
                    .font(.footnote)
                    .foregroundColor(.black)
            }
            .padding(.leading)
            
            Spacer()
        }
        .padding(.all, 10)
        .padding(.leading)
        
        Divider()
            .padding(.horizontal)
    }
}

struct EmployeeSubview_Previews: PreviewProvider {
    static var employee = EmployeeModel(_id: "123456", name: "Luis", lastName: "Pérez Luna", email: "luis@luis.com", employee_id: "ASDCD4342")
    
    static var previews: some View {
        EmployeeSubview(employee: employee)
    }
}
