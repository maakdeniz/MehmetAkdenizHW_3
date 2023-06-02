//
//  WordDetailTableViewCell.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 27.05.2023.
//

import UIKit
import DictionaryAPI

class WordDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var mockExampleLabel: UILabel!
    @IBOutlet weak var partOfSpeechLabel: UILabel!
    @IBOutlet weak var definitionLabel: UILabel!
    @IBOutlet weak var exampleLabel: UILabel!

    static let identifier = "WordDetailTableViewCell"
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selectionStyle = .none
    }
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    //MARK: - TableViewCell Configure Function
    func configure(with definition: Definition, count: Int, partOfSpeech: String) {
        partOfSpeechLabel.text = "\(count) - \(partOfSpeech.capitalized)"
        definitionLabel.text = definition.definition
        if let example = definition.example {
            mockExampleLabel.isHidden = false
            mockExampleLabel.text = "Example"
            exampleLabel.text = example
            exampleLabel.isHidden = false
        } else {
            mockExampleLabel.isHidden = true
            mockExampleLabel.text = nil
            exampleLabel.text = nil
            exampleLabel.isHidden = true
        }
    }
}

