//
//  KeyboardHelper.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 30.05.2023.
//

import UIKit

protocol KeyboardVisibilityDelegate: AnyObject {
    func keyboardWillShow(_ height: CGFloat)
    func keyboardWillHide()
}

class KeyboardHelper: NSObject {
    static let shared = KeyboardHelper()
    
    weak var delegate: KeyboardVisibilityDelegate?
    
    var keyboardVisible: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .keyboardVisibilityDidChange, object: nil)
        }
    }

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.keyboardVisible = true
            delegate?.keyboardWillShow(keyboardSize.height)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.keyboardVisible = false
        delegate?.keyboardWillHide()
    }
}

extension NSNotification.Name {
    static let keyboardVisibilityDidChange = NSNotification.Name("keyboardVisibilityDidChange")
}
