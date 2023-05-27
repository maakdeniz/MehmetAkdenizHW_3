//
//  DetailViewController.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 26.05.2023.
//

import UIKit
import DictionaryAPI


class DetailViewController: UIViewController {
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var phoneticLabel: UILabel!
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var wordTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var wordMeaningTableView: UITableView!
    @IBOutlet weak var synonymsLabel: UILabel!
    @IBOutlet weak var synonymsCollectionView: UICollectionView!
    
    var viewModel: DetailViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "WordDetailTableViewCell", bundle: nil)
        wordMeaningTableView.register(nib, forCellReuseIdentifier: WordDetailTableViewCell.identifier)
        
        wordMeaningTableView.delegate = self
        wordMeaningTableView.dataSource = self
        //        synonymsCollectionView.delegate = self
        //        synonymsCollectionView.dataSource = self
        
        // Fetch the word details
        viewModel.fetchWordDetails { [weak self] result in
            switch result {
            case .failure(let error):
                print("Failed to fetch word details: \(error)")
                print(error)
            case .success(let word):
                DispatchQueue.main.async {
                    print("Successfully fetched word details: \(word)")
                    self?.updateUI(with: word)
                    self?.wordLabel.text = word.word
                    self?.phoneticLabel.text = word.phonetic
                }
            }
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func updateUI(with word: Word) {
        print("Updating UI with word: \(word)")
        
        wordLabel.text = word.word
        phoneticLabel.text = word.phonetic
        audioButton.isEnabled = word.phonetics != nil
        print("wordLabel: \(String(describing: wordLabel))")  // Bu satır
        print("phoneticLabel: \(String(describing: phoneticLabel))")  // Bu satır
        print("wordTypeSegmentedControl: \(String(describing: wordTypeSegmentedControl))")  // Bu satır
        
        
        
        wordTypeSegmentedControl.removeAllSegments()
        for (index, meaning) in word.meanings.enumerated() {
            wordTypeSegmentedControl.insertSegment(withTitle: meaning.partOfSpeech, at: index, animated: false)
        }
        wordTypeSegmentedControl.selectedSegmentIndex = 0
        
        wordMeaningTableView.reloadData()
        //synonymsCollectionView.reloadData()
    }
    
    // Other functions here...
}

extension DetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WordDetailTableViewCell.identifier, for: indexPath) as? WordDetailTableViewCell else {
            fatalError("Cannot dequeue WordDetailTableViewCell")
        }
        
        let meaning = viewModel.meaningForIndexPath(indexPath)
        cell.configure(with: meaning)
        
        return cell
    }
}


