//
//  DetailViewController.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 26.05.2023.
//

import UIKit
import AVFoundation


class DetailViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var phoneticLabel: UILabel!
    @IBOutlet weak var audioButton: UIButton!
    
    @IBOutlet weak var wordMeaningTableView: UITableView!
    @IBOutlet weak var synonymsCollectionView: UICollectionView!
    @IBOutlet weak var filteredCollectionView: UICollectionView!
    
    var viewModel: DetailViewModelProtocol!
    var player: AVPlayer?
    var wordTypes: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        tableviewRegister()
        configureViewModel()
    }
    

    //MARK: - IBAction Functions
    @IBAction func audioButtonTapped(_ sender: Any) {
        viewModel.playAudio { error in
                if let error = error {

                }
            }
       }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Definations Functions
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
    
    func configureViewModel() {
        viewModel.onWordTypesUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.reloadFilteredCollectionView()
            }
        }
        viewModel.onSelectedWordTypesUpdated = {[weak self] in
            DispatchQueue.main.async {
                self?.reloadWordMeaningTableView()
            }
        }
        viewModel.fetchWordDetails { [weak self] result in
            switch result {
            case .failure(_): break
                
            case .success(_):
                DispatchQueue.main.async {

                    self?.updateUI()
                    self?.audioButtonIsVisibilty()
                }
            }
        }
        if let word = viewModel.wordText {
            viewModel.fetchFilteredSynonyms(word: word) { [weak self] result in
                switch result {
                case .failure(_): break
                    
                case .success(_):
                    DispatchQueue.main.async {
                        
                        self?.reloadSynonymsCollectionView()
                    }
                }
            }
        }
    }
    
    func updateUIKit() {
        wordLabel.text = viewModel.wordText
        phoneticLabel.text = viewModel.phoneticText
        audioButton.isEnabled = !(viewModel.getPhonetics()?.isEmpty ?? true)
        reloadWordMeaningTableView()
    }
}

extension DetailViewController: DetailViewModelDelegate {
    func audioButtonIsVisibilty() {
        self.viewModel.isAudioURLValid { isValid in
            DispatchQueue.main.async {
                self.audioButton.isHidden = !isValid
            }
        }
    }
    
    func updateUI() {
        updateUIKit()
    }
    
    func reloadSynonymsCollectionView() {
        synonymsCollectionView.reloadData()
    }
    
    func reloadFilteredCollectionView() {
        filteredCollectionView.reloadData()
    }
    
    func reloadWordMeaningTableView() {
        wordMeaningTableView.reloadData()
    }
    

    
    
}


//MARK: - Tableview Extesion
extension DetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfWordTypes
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let wordTypes = viewModel.getWordTypes(section) else { return 0}
        return viewModel.getCountGroupedDefinitions(wordTypes)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WordDetailTableViewCell.identifier, for: indexPath) as! WordDetailTableViewCell
        if let definition = viewModel.definitionForIndexPath(indexPath) {
            let partOfSpeech = viewModel.getWordTypes(indexPath.section)
            let count = viewModel.meaningIndexForType(partOfSpeech ?? "", indexPath: indexPath)
            cell.configure(with: definition, count: count, partOfSpeech: partOfSpeech ?? "")
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        wordMeaningTableView.allowsSelection = false
        wordMeaningTableView.isScrollEnabled = true
        
    }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
//MARK: - Tableview Extesion
extension DetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == synonymsCollectionView {
            return viewModel.numberOfFilteredSynonyms
        }
        return viewModel.numberOfWordTypes
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == synonymsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "synonymCell", for: indexPath) as! SynonymCollectionViewCell
            let synonym = viewModel.getCountFilteredSynonyms(indexPath.row)
            cell.synonymCellLabel.text = synonym?.word
            cell.layer.borderWidth = 1.0
            cell.layer.borderColor = UIColor.systemGray.cgColor
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filtiredCell", for: indexPath) as? FilteredCollectionViewCell else {
                fatalError("Cannot dequeue FilteredCollectionViewCell")
            }
            
            let wordType = viewModel.getWordTypes(indexPath.row)
            cell.filtiredWordLabel.text = wordType
            cell.filtiredWordLabel.backgroundColor = .systemBlue

            cell.layer.borderWidth = 1.0
            cell.layer.borderColor = UIColor.systemGray.cgColor
            if viewModel.selectedWordTypes.contains(wordType ?? "") {
                cell.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                cell.layer.borderColor = UIColor.systemGray.cgColor
            }

            
            if wordType == "X" {
                cell.filtiredWordLabel.backgroundColor = .clear
                cell.removeFilterLabel.isHidden = false
                cell.removeFilterTapAction = { [weak self] in
                    self?.viewModel.selectedWordType = nil
                    self?.viewModel.selectedWordTypes = []
                    self?.reloadWordMeaningTableView()
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
            let wordType = viewModel.getWordTypes(indexPath.row)
            if wordType == "X" {
                viewModel.selectedWordTypes.removeAll()
                viewModel.isFiltering = false
            } else {
                if let index = viewModel.selectedWordTypes.firstIndex(of: wordType ?? "") {
                    viewModel.selectedWordTypes.remove(at: index)
                    if viewModel.selectedWordTypes.isEmpty {
                        viewModel.isFiltering = false
                    }
                } else {
                    viewModel.selectedWordTypes.append(wordType ?? "")
                    viewModel.isFiltering = true
                }
            }
            viewModel.onSelectedWordTypesUpdated?()
            reloadFilteredCollectionView()
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width / 3
        return CGSize(width: width, height: 50)
    }
}
