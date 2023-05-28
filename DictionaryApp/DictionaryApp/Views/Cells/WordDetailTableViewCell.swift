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
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        exampleLabel.isHidden = false
        
    }

    func configure(with meaning: Meaning) {
        partOfSpeechLabel.text = meaning.partOfSpeech
        if let firstDefinition = meaning.definitions.first {
            definitionLabel.text = firstDefinition.definition
            exampleLabel.text = firstDefinition.example
        } else {
            definitionLabel.text = ""
            exampleLabel.text = ""
        }
    }
}
