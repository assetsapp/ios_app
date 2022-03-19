//
//  ReferencesArray.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 28/08/21.
//

import Foundation

class CustomFieldsArray: ObservableObject {
    @Published var customFields: responseObj
    var _tabs: [tab] = []
    var _cf: [customField] = []
    
    init() {
        let tab0 = tab(columns: 1, tabId: "tab-0", tabName: "Garantia")
        let tab1 = tab(columns: 1, tabId: "tab-1", tabName: "Servicios")
        let tab2 = tab(columns: 1, tabId: "tab-2", tabName: "Legal")
        let tab3 = tab(columns: 1, tabId: "tab-3", tabName: "Administracion")
        let tab4 = tab(columns: 1, tabId: "tab-4", tabName: "Importacion")
        let tab5 = tab(columns: 1, tabId: "tab-5", tabName: "Marketing")
        let tab6 = tab(columns: 1, tabId: "tab-6", tabName: "Producto")
        self._tabs.append(tab0)
        self._tabs.append(tab1)
        self._tabs.append(tab2)
        self._tabs.append(tab3)
        self._tabs.append(tab4)
        self._tabs.append(tab5)
        self._tabs.append(tab6)

        customFields = responseObj(customFields: _cf, tabs: _tabs)
    }
}

class ReferencesArray: ObservableObject {
    
    @Published var references = [ReferenceModel]()
    let url = "https://cdn.pocket-lint.com/r/s/970x/assets/images/152137-laptops-review-apple-macbook-pro-2020-review-image1-pbzm4ejvvs.jpg"
    let fanImage = "https://target.scene7.com/is/image/Target/GUEST_1e862984-4e25-428d-8aee-20e683a26538?wid=488&hei=488&fmt=pjpeg"
    
    init() {
        
        print("Fetch from Backend")
        
        let reference0 = ReferenceModel(_id: "01", brand: "Honeywell", model: "TurboBlade", name: "Fan", fileExt: fanImage)
        let reference1 = ReferenceModel(_id: "02", brand: "Acer", model: "Movo3e", name: "Laptop", fileExt: url)
        let reference2 = ReferenceModel(_id: "03", brand: "Mac", model: "Air", name: "Computer", fileExt: url)
        let reference3 = ReferenceModel(_id: "04", brand: "Xiaomi", model: "Mi", name: "Cellphone", fileExt: url)
        let reference4 = ReferenceModel(_id: "05", brand: "PM", model: "Office", name: "Desk", fileExt: url)
        let reference5 = ReferenceModel(_id: "06", brand: "Epson", model: "A1333", name: "Projector", fileExt: url)
        let reference6 = ReferenceModel(_id: "07", brand: "Benigli", model: "Spinner", name: "Chair", fileExt: url)
        let reference7 = ReferenceModel(_id: "08", brand: "LG", model: "CoolerNova", name: "Minisplit", fileExt: url)
        let reference8 = ReferenceModel(_id: "09", brand: "Bose", model: "Woodstock", name: "Speakers", fileExt: url)
        let reference9 = ReferenceModel(_id: "0A", brand: "Samsung", model: "QLED", name: "TV", fileExt: url)
        let reference10 = ReferenceModel(_id: "0B", brand: "Huawei", model: "AXPeria", name: "Tablet", fileExt: url)
        let reference11 = ReferenceModel(_id: "0C", brand: "Xyrofonos", model: "Blackbird", name: "Keyboard", fileExt: url)

        self.references.append(reference0)
        self.references.append(reference1)
        self.references.append(reference2)
        self.references.append(reference3)
        self.references.append(reference4)
        self.references.append(reference5)
        self.references.append(reference6)
        self.references.append(reference7)
        self.references.append(reference8)
        self.references.append(reference9)
        self.references.append(reference10)
        self.references.append(reference11)

    }
    
    init(reference: ReferenceModel) {
        self.references.append(reference)
    }
    
}
