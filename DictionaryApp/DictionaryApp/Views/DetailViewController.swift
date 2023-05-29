//
//  DetailViewController.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 26.05.2023.
//

import UIKit
import DictionaryAPI
import AVFoundation


class DetailViewController: UIViewController {
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var phoneticLabel: UILabel!
    @IBOutlet weak var audioButton: UIButton!
    
    @IBOutlet weak var wordMeaningTableView: UITableView!
    @IBOutlet weak var synonymsCollectionView: UICollectionView!
    @IBOutlet weak var filteredCollectionView: UICollectionView!
    
    var viewModel: DetailViewModel!
    var player: AVPlayer?
    var wordTypes: [String] = []
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        tableviewRegister()
        asyncOperations()
    
    }
    

    
    
    @IBAction func audioButtonTapped(_ sender: Any) {
        guard let urlString = viewModel.word?.phonetics?.first?.audio,
              let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        player = AVPlayer(url: url)
        player?.play()
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func configure(){
        wordMeaningTableView.delegate = self
        wordMeaningTableView.dataSource = self
        filteredCollectionView.delegate = self
        filteredCollectionView.dataSource = self
        synonymsCollectionView.delegate = self
        synonymsCollectionView.dataSource = self

    }
    
    func tableviewRegister() {
        let nib = UINib(nibName: "WordDetailTableViewCell", bundle: nil)
        wordMeaningTableView.register(nib, forCellReuseIdentifier: WordDetailTableViewCell.identifier)
    }
    
    func asyncOperations() {
        viewModel.onWordTypesUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.filteredCollectionView.reloadData()
            }
        }
        
        viewModel.fetchWordDetails { [weak self] result in
            switch result {
            case .failure(let error):
                print("Failed to fetch word details: \(error)")
                print(error)
            case .success(let word):
                DispatchQueue.main.async {
                    print("Successfully fetched word details: \(word)")
                    self?.updateUI(with: word)
                }
            }
        }
        
        if let word = viewModel.wordText {
            viewModel.fetchFilteredSynonyms(word: word) { [weak self] result in
                switch result {
                case .failure(let error):
                    print("Failed to fetch synonyms: \(error)")
                case .success(let synonyms):
                    DispatchQueue.main.async {
                        print("Successfully fetched synonyms: \(synonyms)")
                        self?.synonymsCollectionView.reloadData()
                    }
                }
            }
        }
    }
    
    func updateUI(with word: Word) {
        wordLabel.text = viewModel.wordText
        phoneticLabel.text = viewModel.phoneticText
        audioButton.isEnabled = (viewModel.word?.phonetics != nil)
        wordMeaningTableView.reloadData()
    }
}

extension DetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.wordTypes.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let partOfSpeech = viewModel.wordTypes[section]
        return viewModel.groupedMeanings[partOfSpeech]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WordDetailTableViewCell.identifier, for: indexPath) as! WordDetailTableViewCell
        if let meaning = viewModel.meaningForIndexPath(indexPath) {
            let count = viewModel.meaningIndexForType(meaning.partOfSpeech ?? "", indexPath: indexPath)
            cell.configure(with: meaning, count: count)
        }
        return cell
    }
}

extension DetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == synonymsCollectionView {
            return viewModel.filteredSynonyms.count
        }
        return viewModel.wordTypes.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == synonymsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "synonymCell", for: indexPath) as! SynonymCollectionViewCell
            let synonym = viewModel.filteredSynonyms[indexPath.row]
            cell.synonymCellLabel.text = synonym.word
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filtiredCell", for: indexPath) as? FilteredCollectionViewCell else {
                fatalError("Cannot dequeue FilteredCollectionViewCell")
            }
            
            let wordType = viewModel.wordTypes[indexPath.row]
            cell.filtiredWordLabel.text = wordType

            if wordType == "X" {
                cell.filtiredWordLabel.backgroundColor = .blue
                cell.removeFilterLabel.isHidden = false
                cell.removeFilterTapAction = { [weak self] in
                    self?.viewModel.selectedWordType = nil
                    self?.wordMeaningTableView.reloadData()
                }
            } else {
                cell.filtiredWordLabel.backgroundColor = .clear
                cell.removeFilterLabel.isHidden = true
            }

            return cell
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == filteredCollectionView {
            let wordType = viewModel.wordTypes[indexPath.row]
            if viewModel.selectedWordTypes.contains(wordType) {
                viewModel.selectedWordTypes.removeAll(where: { $0 == wordType })
            } else {
                viewModel.selectedWordTypes.append(wordType)
            }
            DispatchQueue.main.async {
                self.wordMeaningTableView.reloadData()
            }
            print("TableView güncellenmiyor")
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width / 3
        return CGSize(width: width, height: 50)
    }
}
