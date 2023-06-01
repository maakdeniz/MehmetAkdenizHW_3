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
    public var viewModel: WordViewModelProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let networkService = NetworkService()
        let coreDataService = CoreDataService()
        viewModel = WordViewModel(networkService: networkService, coreDataService: coreDataService) as? any WordViewModelProtocol
        viewModel.delegate = self
        KeyboardHelper.shared.delegate = self
        configure()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchBar.text = ""
    }
    
    //MARK: - IBAction Func.
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        viewModel.searchWord(word: searchBar.text ?? "")
    }
    
    //MARK: - Functions Definations
    func configure() {
        wordTableView.dataSource = self
        wordTableView.delegate = self
        searchBar.delegate = self
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

extension WordViewController: WordViewModelDelegate {
    func reloadData() {
        self.wordTableView.reloadData()
    }
    
    func didUpdateWord(_ viewModel: WordViewModel, word: Word) {
        DispatchQueue.main.async { [self] in
            // Update UI with the new word
            reloadData()
            self.navigateToDetailViewController(with: word)
        }
    }
    
    func didFailWithError(_ viewModel: WordViewModel, error: Error) {
        DispatchQueue.main.async {
            let message: String
            if let fetchError = error as? WordViewModel.FetchWordError, fetchError == .wordNotFound {
                message = "The searched word could not be found."
            } else if let nsError = error as? NSError, nsError.domain == "NetworkServiceError" {
                switch nsError.code {
                case -1:
                    message = "Invalid URL."
                case -2:
                    message = "Unable to decode response."
                case -3:
                    message = "No data received."
                default:
                    message = "An error occurred."
                }
            } else {
                message = error.localizedDescription
            }
            self.showAlert(title: "Error", message: message)
        }
    }
    func navigateToDetailViewController(word: Word) {
          navigateToDetailViewController(with: word)
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
        viewModel.searchWord(word: searchBar.text ?? "")
    }
}
//MARK: - Tableview Extesion
extension WordViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.searchHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "WordCell", for: indexPath) as? WordTableViewCell {
            let word = viewModel.searchHistory[indexPath.row]
            cell.wordLabel.text = word
            cell.rightButton.tag = indexPath.row
            cell.rightButton.addTarget(self, action: #selector(goToDetails), for: .touchUpInside)
            return cell
        } else {
            return UITableViewCell() //
        }
    }
    //MARK: - objc functions
    @objc func goToDetails(_ sender: UIButton) {
        let wordString = viewModel.searchHistory[sender.tag]
        viewModel.fetchWord(wordString)
    }
    
}
