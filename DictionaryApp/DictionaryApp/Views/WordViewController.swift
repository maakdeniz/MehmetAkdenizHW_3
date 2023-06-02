//
//  WordViewController.swift
//  DictionaryApp
//
//  Created by Mehmet Akdeniz on 26.05.2023.
//

import UIKit

class WordViewController: UIViewController, LoadingShowable {
    
    //MARK: - IBOutles
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var wordTableView: UITableView!
    @IBOutlet weak var searchButtonBottomConstraint: NSLayoutConstraint!
    
    //MARK: - Variables Definatios
    public var viewModel: WordViewModelProtocol!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let coreDataService = CoreDataService()
        viewModel = WordViewModel(coreDataService: coreDataService) as any WordViewModelProtocol
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
        self.showLoading()
        viewModel.searchWord(word: searchBar.text ?? "")
    }
    
    //MARK: - Functions Definations
    func configure() {
        wordTableView.dataSource = self
        wordTableView.delegate = self
        searchBar.delegate = self
    }
    internal func navigateToDetailViewControllera() {
        
        let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        guard let word = viewModel.getWord() else { return }
        let detailViewModel = DetailViewModel(word: word)
        detailViewController.viewModel = detailViewModel
        detailViewController.modalPresentationStyle = .fullScreen
        self.present(detailViewController, animated: true, completion: nil)
        self.hideLoading()
    }
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK: - WordViewModelDelegate Functions
extension WordViewController: WordViewModelDelegate {
    func reloadData() {
        self.wordTableView.reloadData()
    }
    
    func didUpdateWord(_ viewModel: WordViewModel) {
        DispatchQueue.main.async { [self] in
            reloadData()
            self.showLoading()
            self.navigateToDetailViewController()
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
            self.hideLoading()
            self.showAlert(title: "Error", message: message)
        }
    }
    func navigateToDetailViewController() {
        self.navigateToDetailViewControllera()
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
            return UITableViewCell() 
        }
    }
    //MARK: - objc functions
    @objc func goToDetails(_ sender: UIButton) {
        self.showLoading()
        let wordString = viewModel.searchHistory[sender.tag]
        viewModel.fetchWord(wordString)
    }
    
}
