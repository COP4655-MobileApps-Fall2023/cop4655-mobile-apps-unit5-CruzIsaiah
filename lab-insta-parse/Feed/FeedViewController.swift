import UIKit
import ParseSwift

class FeedViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var posts = [Post]()
    private var currentPage: Int = 1
    private let postsPerPage: Int = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        
        // Add a refresh control for pull-to-refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Fetch the initial page of posts
        queryPosts()
    }
    
    private func queryPosts() {
        // Calculate the number of posts to skip based on the current page
        let skip = (currentPage - 1) * postsPerPage
        
        // Create a query to fetch Posts with pagination
        let query = Post.query()
            .include("user")
            .order([.descending("createdAt")])
            .skip(skip) // Skip the posts from previous pages
            .limit(postsPerPage) // Limit the number of posts per page
        
        // Fetch objects (posts) defined in the query asynchronously
        query.find { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let posts):
                // If there are new posts, append them to the existing posts array
                if !posts.isEmpty {
                    self.posts.append(contentsOf: posts)
                    self.currentPage += 1 // Increment the current page
                }
                
                // Reload the table view on the main thread
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            case .failure(let error):
                self.showAlert(description: error.localizedDescription)
            }
        }
    }
    
    @objc private func refreshFeed() {
        // Reset the current page and clear the existing posts
        currentPage = 1
        posts.removeAll()
        
        // Fetch the latest posts
        queryPosts()
        
        // End the refresh control animation
        tableView.refreshControl?.endRefreshing()
    }
    
    @IBAction func onLogOutTapped(_ sender: Any) {
        showConfirmLogoutAlert()
    }
    
    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(title: "Log out of your account?", message: nil, preferredStyle: .alert)
        let logOutAction = UIAlertAction(title: "Log out", style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        cell.configure(with: posts[indexPath.row])
        return cell
    }
}

extension FeedViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollViewContentHeight = scrollView.contentSize.height
        let scrollViewOffset = scrollView.contentOffset.y
        let scrollViewFrameHeight = scrollView.frame.height
        
        // Define a threshold to trigger loading more data (e.g., 100 pixels from the bottom)
        let scrollThreshold: CGFloat = 100
        
        if scrollViewOffset + scrollViewFrameHeight >= scrollViewContentHeight - scrollThreshold {
            loadMoreData()
        }
    }
    
    private func loadMoreData() {
        // Fetch more data when the user scrolls to the bottom
        queryPosts()
    }
}
