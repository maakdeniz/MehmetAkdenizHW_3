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
    func configure(with definition: Definition, count: Int, partOfSpeech: String) {
        partOfSpeechLabel.text = "\(count) - \(partOfSpeech.capitalized)"
        definitionLabel.text = definition.definition
        exampleLabel.text = "Example\n" + (definition.example ?? "")
        exampleLabel.isHidden = definition.example == nil
    }
}

