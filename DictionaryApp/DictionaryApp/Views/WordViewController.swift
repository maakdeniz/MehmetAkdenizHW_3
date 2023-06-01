//
//  WordViewController.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 26.05.2023.
//

import UIKit
import DictionaryAPI

class WordViewController: UIViewController {
    
    //MARK: - IBOutles
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var wordTableView: UITableView!
    @IBOutlet weak var searchButtonBottomConstraint: NSLayoutConstraint!
    
    //MARK: - Variables Definatios
    public var viewModel: WordViewModel!
    private var searchHistory: [Word] = []
    private var defaultsService = DefaultsService()
    private var coreDataService = CoreDataService()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchHistory = defaultsService.getSearchHistory() ?? []
        configure()
        viewModel = WordViewModel(networkService: NetworkService())
        KeyboardHelper.shared.delegate = self
    }

    //MARK: - IBAction Func.
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        searchWord()
    }
    
    //MARK: - Functions Definations
    func configure() {
        wordTableView.dataSource = self
        wordTableView.delegate = self
        searchBar.delegate = self
    }
    
    private func searchWord() {
        guard let searchText = searchBar.text, !searchText.isEmpty else {
            showAlert(title: "Error", message: "You haven't entered a word to search.")
            return
        }

        viewModel.fetchWord(searchText) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    if let fetchError = error as? WordViewModel.FetchWordError, fetchError == .wordNotFound {
                        self?.showAlert(title: "Error", message: "The searched word could not be found.")
                    } else if let nsError = error as? NSError, nsError.domain == "NetworkServiceError" && nsError.code == -2 {
                        self?.showAlert(title: "Error", message: "The searched word could not be found.")
                    } else {
                        print(error)
                    }
                case .success(let words):
                    guard let word = words.first else {
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
        let detailViewModel = DetailViewModel(word: word,
                                              networkService: NetworkService())
        detailViewController.viewModel = detailViewModel
        detailViewController.modalPresentationStyle = .fullScreen
        self.present(detailViewController, animated: true, completion: nil)
    }
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK: - Keyboard Delegate
extension WordViewController:KeyboardVisibilityDelegate {
    func keyboardWillShow(_ height: CGFloat) {
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.searchButtonBottomConstraint.constant = height
                self?.view.layoutIfNeeded()
            }
        }
    func keyboardWillHide() {
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.searchButtonBottomConstraint.constant = 0
                self?.view.layoutIfNeeded()
            }
        }
}

//MARK: - Searchbar Extesion
extension WordViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchWord()
    }
}
//MARK: - Tableview Extesion
extension WordViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "WordCell", for: indexPath) as? WordTableViewCell {
            let word = searchHistory[indexPath.row]
            cell.wordLabel.text = word.word
            cell.rightButton.tag = indexPath.row
            cell.rightButton.addTarget(self, action: #selector(goToDetails), for: .touchUpInside)
            return cell
        } else {
            return UITableViewCell() //
        }
    }
    //MARK: - objc functions
    @objc func goToDetails(_ sender: UIButton) {
        let word = searchHistory[sender.tag]
        navigateToDetailViewController(with: word)
    }
}
