//
//  LogInView.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 16/08/21.
//

import SwiftUI


struct LogInView: View {
    @ObservedObject var cslvalues: CSLValues
    @State var userName: String = ""
    @State var pwd: String = ""
    @State var showSettings: Bool = false
    @Binding var isUserLoggedOut: Bool
    
    var body: some View {
        
        VStack {
            HStack {
                Text(cslvalues.appVersion)
                    .foregroundColor(Color.white.opacity(0.2))
                    .padding(.leading)
                Spacer()
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.white)
                Button(action: { showSettings.toggle() }) {
                    Text("Settings")
                }
                .foregroundColor(.white)
                .padding(.trailing)
                .sheet(isPresented: $showSettings) {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { showSettings = false }) {
                                Text(" Save ")
                            }.buttonStyle(PlainButtonStyle())
                                .buttonStyle(PlainButtonStyle())
                                .padding(8)
                                .background(Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .shadow(radius: 2)
                                .font(.system(size: 14))
                            .padding()
                        }
                        Form {
                            Section(header: Text("Connection")) {
                                ConnectionsSubview(cslvalues: cslvalues, isUserLoggedOut: $isUserLoggedOut, fromSettings: false)
                            }
                        }
                    }
                    .background(Color(.systemGray6))
                }
            }
            Spacer(minLength: 0)
            
            LogoLogIn()
            LogInTitle()
            LogInBody(cslvalues: cslvalues, isUserLoggedOut: $isUserLoggedOut)

            Spacer(minLength: 0)
        }
        .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]), startPoint:.top, endPoint: .bottom).ignoresSafeArea(.all, edges: .all))
        
    }
}

struct LogoLogIn: View {
    var body: some View {
        Image("inventory")
            .resizable()
            .cornerRadius(35)
            .aspectRatio(contentMode: .fit)
            .frame(width: 250)
            .padding(.horizontal, 35)
            .padding(.vertical)
            .shadow(color: Color.yellow, radius: 45, x: 0, y: 0)
    }
}

struct LogInTitle: View {
    
    var body: some View {
        
        HStack {
            
            VStack(alignment: .leading, spacing: 12, content: {
                
                Text("Login")
                    .font(.title)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .foregroundColor(.white)
                
                Text("Please sign in to continue")
                    .foregroundColor(Color.white.opacity(0.5))
                    
            })
            
            Spacer(minLength: 0)
            
        }
        .padding()
        .padding(.leading, 1)
        
    }
    
}

struct LogInBody: View {
    @ObservedObject var cslvalues: CSLValues
    @State var userName: String = ""
    @State var pwd: String = ""
    @State var validUser: Bool = false
    @State private var isPasswordVisible: Bool = false
    @State var showErrorModal: Bool = false
    @Binding var isUserLoggedOut: Bool
    @Environment(\.presentationMode) var presentationMode//: Binding<PresentationMode>

    var body: some View {
        VStack {
            HStack {
                
                Image(systemName: "envelope")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 35, height: 35)
                
                TextField("EMAIL", text: $userName)
                    .foregroundColor(.white)
                
            }
            .padding()
            .background(Color.white.opacity(0.12))
            .cornerRadius(15)
            .padding(.horizontal)
    
            HStack {
                
                Image(systemName: "lock")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 35, height: 35)
                
                if isPasswordVisible {
                                    TextField("PASSWORD", text: $pwd)
                                        .foregroundColor(.white)
                                } else {
                                    SecureField("PASSWORD", text: $pwd)
                                        .foregroundColor(.white)
                                }
                                
                                Button(action: {
                                    isPasswordVisible.toggle() // Cambiar entre SecureField y TextField
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                        .foregroundColor(.white)
                                }
                                .padding(.trailing, 10)
                
            }
            .padding()
            .background(Color.white.opacity(0.12))
            .cornerRadius(15)
            .padding(.horizontal)
            .padding(.top)
            
            Button(action: { logUser() }) {
                Text("LOGIN")
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .padding(.vertical)
                    .frame(width: UIScreen.main.bounds.width - 150)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
            .padding(.top)
            .disabled(userName != "" && pwd != "" ? false : true)
            .alert(isPresented: $showErrorModal, content: {
                Alert(
                    title: Text("Login error, please check user and/or password"),
                    dismissButton: .default(Text("OK"), action: {})
                )
            })
        }
        
    }
    
    func logUser() {
        if userName != "" && pwd != "" {
            cslvalues.isLoading = true
            ApiUser().logIn(user: userName, pwd: pwd) { result in
                if result.id != "" {
                    print("VALID>>>>>>>>>>>>>>>>>>>")
                    UserDefaults.standard.set(result.name, forKey: Settings.userNameKey)
                    UserDefaults.standard.set(result.id, forKey: Settings.userIdKey)
                    UserDefaults.standard.set(result.lastName, forKey: Settings.userLastNameKey)
                    UserDefaults.standard.set(result.accessToken, forKey: Settings.userTokenKey)
                    UserDefaults.standard.set(result.fileExt, forKey: Settings.userFileExt)
                    isUserLoggedOut = false
                    presentationMode.wrappedValue.dismiss()
                } else {
                    showErrorModal = true
                    UserDefaults.standard.set("", forKey: Settings.userNameKey)
                    UserDefaults.standard.set("", forKey: Settings.userIdKey)
                    UserDefaults.standard.set("", forKey: Settings.userLastNameKey)
                    UserDefaults.standard.set("", forKey: Settings.userTokenKey)
                    UserDefaults.standard.set("", forKey: Settings.userFileExt)
                    UserDefaults.resetStandardUserDefaults()
                }
                cslvalues.isLoading = false
            }
        }
    }
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView(cslvalues: CSLValues(), isUserLoggedOut: .constant(true))
    }
}
