//
//  FilteredCollectionViewCell.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 27.05.2023.
//

import UIKit

class FilteredCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var filtiredWordLabel: UILabel!
    var removeFilterLabel: UILabel!
    var removeFilterTapAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        removeFilterLabel = UILabel()
        removeFilterLabel.text = "X"
        removeFilterLabel.textColor = .white
        removeFilterLabel.textAlignment = .center
        removeFilterLabel.backgroundColor = .red
        removeFilterLabel.layer.cornerRadius = 15
        removeFilterLabel.clipsToBounds = true
        removeFilterLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(removeFilterLabel)
        
        NSLayoutConstraint.activate([
            removeFilterLabel.widthAnchor.constraint(equalToConstant: 30),
            removeFilterLabel.heightAnchor.constraint(equalToConstant: 30),
            removeFilterLabel.trailingAnchor.constraint(equalTo: filtiredWordLabel.trailingAnchor, constant: 10),
            removeFilterLabel.centerYAnchor.constraint(equalTo: filtiredWordLabel.centerYAnchor)
        ])
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(removeFilterTapped))
        removeFilterLabel.addGestureRecognizer(tapGestureRecognizer)
        removeFilterLabel.isUserInteractionEnabled = true
    }
    
    @objc private func removeFilterTapped() {
        removeFilterTapAction?()
    }
}
