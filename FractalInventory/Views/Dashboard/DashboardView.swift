//
//  DashboardView.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 04/09/21.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var cslvalues: CSLValues
    @Binding var isUserLoggedOut: Bool
    
    var body: some View {
        NavigationView {
            
            Main(cslvalues: cslvalues, isUserLoggedOut: $isUserLoggedOut)
                .navigationBarTitle("Home")
                .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear() {
//            ApiAssets().getAllAssets { assets in
//                print("\n-----")
//                print("****** Fetch assets done -> ")
//                print("\n-----")
//            }
        }
    }
}

struct Main: View {
    
    @ObservedObject var cslvalues: CSLValues
    @State var sideMenuOpen: Bool = false
    @Binding var isUserLoggedOut: Bool
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    Button(action: { sideMenuOpen.toggle() }) {
                        Image(systemName: "line.horizontal.3")
                            .imageScale(.large)
                            .foregroundColor(.primary)
                    }
                }
                Spacer()
                ScrollView(.vertical, showsIndicators: false) {
                    Dashboard(cslvalues: cslvalues, sideMenuOpen: $sideMenuOpen, isUserLoggedOut: $isUserLoggedOut)
                }
                
            }
            .padding()
            .onTapGesture {
                if sideMenuOpen {
                    sideMenuOpen = false
                }
            }
            Menu(cslvalues: cslvalues, isMenuOpen: $sideMenuOpen, isUserLoggedOut: $isUserLoggedOut)
        }
    }
    
}

struct Dashboard: View {
    @ObservedObject var cslvalues: CSLValues
    @Binding var sideMenuOpen: Bool
    @Binding var isUserLoggedOut: Bool
    @State var selectedEmployee: EmployeeModel = EmployeeModel(_id: "", name: "", lastName: "", email: "")

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Inventory App")
                        .font(.title)
                        .fontWeight(.bold)
                        
                    Text("DASHBOARD")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(cslvalues.appVersion)
                        .foregroundColor(Color(.systemGray5))
                        .padding(.trailing)
                }
                Spacer()
            }
            .padding(.top)
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                NavigationLink(destination: LocationsView(cslvalues: cslvalues)) {
                    Card(caption: "1", title: "Navigate", subTitle: "Tag and Inventory", icon: "map", colors: [Color.yellow, Color.orange])
                }
                .simultaneousGesture(TapGesture().onEnded{
                    sideMenuOpen = false
                })
                
                Spacer()
                
                NavigationLink(destination: IdentifyView(cslvalues: cslvalues)) {
                    Card(caption: "2", title: "Identify", subTitle: "Identify tags", icon: "rectangle", colors: [Color.blue, Color.purple])
                }
                .simultaneousGesture(TapGesture().onEnded{
                    sideMenuOpen = false
                })
            }.padding(.vertical)
            
            HStack {
                NavigationLink(destination: SearchView(cslvalues: cslvalues, closeModal: .constant(false), selectedEmployee: $selectedEmployee)) {
                    Card(caption: "3", title: "Search", subTitle: "Find assets", icon: "magnifyingglass", colors: [Color.blue, Color.blue])
                }
                .simultaneousGesture(TapGesture().onEnded{
                    sideMenuOpen = false
                })
                
                Spacer()
                
                NavigationLink(destination: EmployeeView(cslvalues: cslvalues, showModal: .constant(false), selectedEmployee: $selectedEmployee)) {
                    Card(caption: "4", title: "Employee", subTitle: "Assign assets", icon: "person", colors: [Color.red, Color.orange])
                }
                .simultaneousGesture(TapGesture().onEnded{
                    sideMenuOpen = false
                })
            }
            .padding(.vertical)
            
            HStack {
                NavigationLink(destination: RawRfidView(cslvalues: cslvalues)) {
                    Card(caption: "5", title: "Raw RFID", subTitle: "Read RFID", icon: "iphone.radiowaves.left.and.right", colors: [Color.green, Color.green])
                }
                .simultaneousGesture(TapGesture().onEnded{
                    sideMenuOpen = false
                })
                
                NavigationLink(destination: SettingsView(cslvalues: cslvalues, isUserLoggedOut: $isUserLoggedOut)) {
                    Card(caption: "6", title: "Settings", subTitle: "Configurations", icon: "slider.horizontal.3", colors: [Color.pink, Color.purple])
                }
                .simultaneousGesture(TapGesture().onEnded{
                    sideMenuOpen = false
                })
            }.padding(.vertical)
            
            Spacer()
            
        }
    }
}

struct Card: View {
    @State var caption: String = ""
    @State var title: String = ""
    @State var subTitle: String = ""
    @State var icon: String = ""
    @State var colors: [Color] = [Color.red, Color.orange]
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            VStack(alignment: .leading, spacing: 15) {
                Text(caption)
                    .foregroundColor(.white)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                HStack {
                    Spacer(minLength: 0)
                    
                    Text(subTitle)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: colors), startPoint:.top, endPoint: .bottom))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
            
            VStack {
                Image(systemName: icon)
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.35))
                .clipShape(Circle())
            }
            .padding(10)
        }
    }
}

struct Menu: View {
    @ObservedObject var cslvalues: CSLValues
    @Binding var isMenuOpen: Bool
    @Binding var isUserLoggedOut: Bool
    @State var imagePlaceHolder: Image = Image("user_avatar")
    @State var selectedEmployee: EmployeeModel = EmployeeModel(_id: "", name: "", lastName: "", email: "")
    @AppStorage(Settings.userIdKey) var userId = ""
    @AppStorage(Settings.userNameKey) var userName = "Guest"
    @AppStorage(Settings.userLastNameKey) var userLastName = "User"
    @AppStorage(Settings.userFileExt) var userFileExt = ""
    @AppStorage(Settings.apiHostKey) var apiHost = Constants.apiHost
    
    var body: some View {
        VStack {
            Text("Inventory App")
                .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                .foregroundColor(.white)
                .font(.system(size: 25, weight: .bold))
                .padding(.top, 30)
                .padding(.bottom, 30)
            
            HStack {
                
                ZStack {
                    if userId == "" {
                        Image("user_avatar")
                            .resizable()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                            .padding(.horizontal, 44)
                            .shadow(radius: 25)
                    } else {
                        LoadImage(fileExt: userFileExt, id: userId, folder: "user", sizeFraction: 5, applyFrame: false, placeHolderImage: imagePlaceHolder)
    
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .padding(.horizontal, 44)
                            .shadow(radius: 25)
                    }
                    
                    Circle()
                        .stroke(Color.yellow)
                        .frame(width: 100, height: 100)
                        .offset(x: 2, y: 1)
                    
                    Circle()
                        .stroke(Color.white)
                        .frame(width: 100, height: 100)
                        .offset(x: -2, y: -1)
                    
                }
                
            }.padding(.top, 20)
            
            Text("\(userName) \(userLastName)")
                .foregroundColor(.white)
                .font(.system(size: 22, weight: .semibold))
                .padding(.top, 10)
                .padding(.bottom, 40)
            
            VStack {
                Row(moduleActive: .constant(false), moduleIcon: "house", moduleName: "Home")
                NavigationLink(destination: LocationsView(cslvalues: cslvalues)) {
                    Row(moduleActive: .constant(false), moduleIcon: "map", moduleName: "Navigation")
                }
                .simultaneousGesture(TapGesture().onEnded{
                    isMenuOpen = false
                })
                NavigationLink(destination: IdentifyView(cslvalues: cslvalues)) {
                    Row(moduleActive: .constant(false), moduleIcon: "rectangle", moduleName: "Identify")
                }
                .simultaneousGesture(TapGesture().onEnded{
                    isMenuOpen = false
                })
                NavigationLink(destination: SearchView(cslvalues: cslvalues, closeModal: .constant(false), selectedEmployee: $selectedEmployee)) {
                    Row(moduleActive: .constant(false), moduleIcon: "magnifyingglass", moduleName: "Search")
                }
                .simultaneousGesture(TapGesture().onEnded{
                    isMenuOpen = false
                })
                NavigationLink(destination: EmployeeView(cslvalues: cslvalues, isModal: false, showModal: .constant(false), selectedEmployee: $selectedEmployee)) {
                    Row(moduleActive: .constant(false), moduleIcon: "person", moduleName: "Employees")
                }
                .simultaneousGesture(TapGesture().onEnded{
                    isMenuOpen = false
                })
                NavigationLink(destination: RawRfidView(cslvalues: cslvalues)) {
                    Row(moduleActive: .constant(false), moduleIcon: "iphone.radiowaves.left.and.right", moduleName: "Raw RFID")
                }
                .simultaneousGesture(TapGesture().onEnded{
                    isMenuOpen = false
                })
                NavigationLink(destination: InventorySessionSubview(cslvalues: cslvalues, isModalOpen: .constant(true), locationPath: "")) {
                    Row(moduleActive: .constant(false), moduleIcon: "square.split.2x2", moduleName: "Inventories")
                }
                .simultaneousGesture(TapGesture().onEnded {
                    isMenuOpen = false
                })
                NavigationLink(destination: SettingsView(cslvalues: cslvalues, isUserLoggedOut: $isUserLoggedOut)) {
                    Row(moduleActive: .constant(false), moduleIcon: "slider.horizontal.3", moduleName: "Settings")
                }
                .simultaneousGesture(TapGesture().onEnded{
                    isMenuOpen = false
                })
                Spacer()
                Button(action: {
                    UserDefaults.standard.removeObject(forKey: Settings.userTokenKey)
                    UserDefaults.standard.removeObject(forKey: Settings.userNameKey)
                    UserDefaults.standard.removeObject(forKey: Settings.userIdKey)
                    UserDefaults.standard.removeObject(forKey: Settings.userLastNameKey)
                    UserDefaults.resetStandardUserDefaults()
                    isMenuOpen = false
                    isUserLoggedOut = true
                }) {
                    Row(moduleActive: .constant(false), moduleIcon: "arrow.uturn.left", moduleName: "Log out")
                }
            }

            
            
        }.padding(.vertical, 30)
        .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]), startPoint:.top, endPoint: .bottom))
        .padding(.trailing, UIScreen.main.bounds.width * 0.33)
        .offset(x: isMenuOpen ? 0 : -UIScreen.main.bounds.width)
        .rotation3DEffect(
            Angle(degrees: isMenuOpen ? 0 : 45),
            axis: (x: 0, y: 20, z: 0)
        )
        .animation(.easeOut)
        .onTapGesture {
            self.isMenuOpen.toggle()
        }
        .edgesIgnoringSafeArea(.vertical)
        .onAppear {
            CSLGlobalVariables._cslvalues = cslvalues
        }
    }
}

struct Row: View {

    @Binding var moduleActive: Bool
    var moduleIcon: String = "house"
    var moduleName: String = "Dashboard"
    
    var body: some View {

        HStack {
            
            Image(systemName: moduleIcon)
                .foregroundColor(moduleActive ? .orange : .white)
                .font(.system(size:15, weight: moduleActive ? .bold : .regular))
                .frame(width: 48, height: 32)
            
            Text(moduleName)
                .foregroundColor(moduleActive ? .orange : .white)
                .font(.system(size: 18, weight: moduleActive ? .bold : .regular))
            
            Spacer()
            
        }
        .padding(4)
        .background(moduleActive ? Color.white : Color.white.opacity(0))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .offset(x: 20)
        
    }
}

struct SideMenu_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(cslvalues: CSLValues(), isUserLoggedOut: .constant(false))
    }
}
