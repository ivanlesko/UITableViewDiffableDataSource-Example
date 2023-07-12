//
//  ClosureButton.swift
//  Diffable Table View Example
//
//  Created by Ivan Lesko on 7/11/23.
//

import Foundation
import UIKit

class ClosureButton: UIButton {
    var primaryActionClosure: (() -> Void)?
    
    convenience init(title: String, closure: (() -> Void)? = nil) {
        self.init(type: .system)
        primaryActionClosure = closure
        setTitle(title, for: .normal)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        addTarget(self, action: #selector(handlePrimaryAction), for: .primaryActionTriggered)
    }
    
    @objc private func handlePrimaryAction() {
        primaryActionClosure?()
    }
}
