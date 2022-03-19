//
//  WebViewStateModel.swift
//  FractalInventory
//
//  Created by Miguel Cruz on 08/12/21.
//

import Foundation

class WebViewStateModel: ObservableObject {
    @Published var pageTitle: String = "https://google.com"
    @Published var goToPage: Bool = false
    @Published var goBack: Bool = false
    @Published var goForward: Bool = false
}
