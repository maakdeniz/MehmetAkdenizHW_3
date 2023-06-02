//
//  LoadingShowable.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 2.06.2023.
//

import Foundation
import UIKit

protocol LoadingShowable where Self: UIViewController {
    func showLoading()
    func hideLoading()
}

extension LoadingShowable {
    func showLoading(){
        LoadingView.shared.startLoading()
        
    }
    func hideLoading(){
        LoadingView.shared.stopLoading()
    }
}

