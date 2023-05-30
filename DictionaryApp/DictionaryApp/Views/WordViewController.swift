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
    @IBOutlet weak var searchButton: UIButton!
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
        KeyboardHelper.shared
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        searchButtonBottomConstraint.constant = KeyboardHelper.shared.keyboardHeight
//    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow triggered")
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.searchButtonBottomConstraint.constant = keyboardSize.height
                self?.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        print("keyboardWillHide triggered")
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.searchButtonBottomConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }
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
}

extension WordViewController {
    
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
            return UITableViewCell() // return a default cell if we can't get a WordTableViewCell
        }
    }
    //MARK: - objc functions
    @objc func goToDetails(_ sender: UIButton) {
        let word = searchHistory[sender.tag]
        navigateToDetailViewController(with: word)
    }
}
