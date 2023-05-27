//
//  WordViewController.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 26.05.2023.
//

import UIKit
import DictionaryAPI

class WordViewController: UIViewController {
    
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var wordTableView: UITableView!
    
    private var viewModel: WordViewModel!
    private var searchHistory: [Word] = []
    
    private var defaultsService = DefaultsService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        searchHistory = defaultsService.getSearchHistory() ?? []
        
        
        wordTableView.dataSource = self
        wordTableView.delegate = self
        searchBar.delegate = self
        viewModel = WordViewModel(networkService: NetworkService())
    }
    
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        searchWordAndNavigateIfNeeded()
    }
    private func searchWordAndNavigateIfNeeded() {
        guard let searchText = searchBar.text, !searchText.isEmpty else {
            return
        }
        
        viewModel.fetchWord(searchText) { [weak self] result in
            DispatchQueue.main.async { [self] in
                switch result {
                case .failure(let error):
                    //                        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    //                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    //                        self?.present(alert, animated: true, completion: nil)
                    print(error)
                case .success(let words):
                    guard let word = words.first else {
                        // Handle the case where the word is not found
                        return
                    }
                    
                    self?.searchHistory.append(word)
                    if self?.searchHistory.count ?? 0 > 5 {
                        self?.searchHistory.removeFirst()
                    }
                    
                    self?.defaultsService.saveSearchHistory(self?.searchHistory ?? [])
                    
                    
                    self?.wordTableView.reloadData()
                    self?.navigateToDetailViewController(with: word)
                }
            }
        }
    }
    
    private func navigateToDetailViewController(with word: Word) {
        let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        let detailViewModel = DetailViewModel(word: word, networkService: NetworkService())
        detailViewController.viewModel = detailViewModel
        detailViewController.modalPresentationStyle = .fullScreen
        self.present(detailViewController, animated: true, completion: nil)
    }
}

extension WordViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchWordAndNavigateIfNeeded()
    }
}

extension WordViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WordCell", for: indexPath) as! WordTableViewCell
        let word = searchHistory[indexPath.row]
        cell.wordLabel.text = word.word
        cell.rightButton.tag = indexPath.row
        cell.rightButton.addTarget(self, action: #selector(goToDetails), for: .touchUpInside)
        return cell
    }
    
    @objc func goToDetails(_ sender: UIButton) {
        let word = searchHistory[sender.tag]
        navigateToDetailViewController(with: word)
    }
}




