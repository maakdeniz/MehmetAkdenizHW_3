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
    @IBOutlet weak var synonymsLabel: UILabel!
    @IBOutlet weak var synonymsCollectionView: UICollectionView!
    @IBOutlet weak var filteredCollectionView: UICollectionView!
    
    var viewModel: DetailViewModel!
    var player: AVPlayer?
    var wordTypes: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "WordDetailTableViewCell", bundle: nil)
        wordMeaningTableView.register(nib, forCellReuseIdentifier: WordDetailTableViewCell.identifier)
        
        wordMeaningTableView.delegate = self
        wordMeaningTableView.dataSource = self
        filteredCollectionView.delegate = self
        filteredCollectionView.dataSource = self
        
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
    
    
    
    
    func updateUI(with word: Word) {
        wordLabel.text = viewModel.wordText
        phoneticLabel.text = viewModel.phoneticText
        audioButton.isEnabled = (viewModel.word?.phonetics != nil)
        wordMeaningTableView.reloadData()
    }
}

extension DetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WordDetailTableViewCell.identifier, for: indexPath) as! WordDetailTableViewCell
        
        if let meaning = viewModel.meaningForIndexPath(indexPath) {
            cell.configure(with: meaning)
        } else {
            cell.partOfSpeechLabel.text = "Unknown"
            cell.definitionLabel.text = "Unknown"
            cell.exampleLabel.text = "Unknown"
        }
        
        return cell
    }
}

extension DetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.wordTypes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let wordType = viewModel.wordTypes[indexPath.item]
        if wordType != "X" {
            if !viewModel.selectedWordTypes.contains(wordType) {
                viewModel.selectedWordTypes.append(wordType)
            }
        } else {
            viewModel.selectedWordTypes.removeAll()
        }
        wordMeaningTableView.reloadData()
    }


    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width / 3
        return CGSize(width: width, height: 50)
    }
}