//
//  LoadImage.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 08/12/21.
//

import SwiftUI

struct LoadImage: View {
    @State var fileExt: String
    @State var id: String
    var folder = "references"
    var sizeFraction: CGFloat = 5
    var applyFrame: Bool = true
    var placeHolderImage: Image = Image(systemName: "photo")
    @AppStorage(Settings.apiHostKey) var apiHost = "http://159.203.41.87:3001"

    var body: some View {
        if applyFrame {
            if fileExt != "" {
                RemoteImage(url: "\(getBasePicUrl())\(id).\(fileExt)")
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(30)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / sizeFraction)
                    .shadow(color: Color.gray, radius: 20, x: 20, y: 20)
                    .padding(.vertical)
            } else {
                placeHolderImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(30)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / sizeFraction)
                    .shadow(color: Color.gray, radius: 20, x: 20, y: 20)
                    .padding(.vertical)
            }
        } else {
            if fileExt != "" {
                RemoteImage(url: "\(getBasePicUrl())\(id).\(fileExt)")
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(30)
                    .padding(.vertical)
            } else {
                placeHolderImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(30)
                    .padding(.vertical)
            }
        }
    }
    
    func getBasePicUrl() -> String {
        print("@@@@@@@@@@@")
        print("\(apiHost)/uploads/\(folder)/\(id).\(fileExt)")
        print("@@@@@@@@@@@")
        
        return "\(apiHost)/uploads/\(folder)/"
    }
}

struct LoadImage_Previews: PreviewProvider {
    static var fileExt: String = ""
    static var id: String = ""

    static var previews: some View {
        LoadImage(fileExt: fileExt, id: id)
    }
}
