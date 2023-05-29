//
//  WordDetailTableViewCell.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 27.05.2023.
//

import UIKit
import DictionaryAPI

class WordDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var partOfSpeechLabel: UILabel!
    @IBOutlet weak var definitionLabel: UILabel!
    @IBOutlet weak var exampleLabel: UILabel!

    static let identifier = "WordDetailTableViewCell"
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        //exampleLabel.isHidden = false
    }
    func configure(with meaning: Meaning, count: Int) {
        if let type = meaning.partOfSpeech {
            partOfSpeechLabel.text = "\(count) - \(type.capitalized)"
        } else {
            partOfSpeechLabel.text = "\(count) - Unknown"
        }

        if let firstDefinition = meaning.definitions.first {
            definitionLabel.text = firstDefinition.definition
            exampleLabel.text = "Example\n" + (firstDefinition.example ?? "") 
            exampleLabel.isHidden = firstDefinition.example == nil
        } else {
            definitionLabel.text = ""
            exampleLabel.text = ""
            exampleLabel.isHidden = true
        }
    }
}
