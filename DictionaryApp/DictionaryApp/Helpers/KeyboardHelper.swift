//
//  KeyboardHelper.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 30.05.2023.
//

import UIKit

class KeyboardHelper: NSObject {
    static let shared = KeyboardHelper()
    
    var keyboardVisible: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .keyboardVisibilityDidChange, object: nil)
        }
    }

    private override init() {
        super.init()
    }
}

extension NSNotification.Name {
    static let keyboardVisibilityDidChange = NSNotification.Name("keyboardVisibilityDidChange")
}


