import UIKit

protocol CreateReadingListViewControllerDelegate: NSObjectProtocol {
    func createdNewReadingList(in controller: CreateReadingListViewController, with name: String, description: String?)
}

class CreateReadingListViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var readingListNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var readingListNameTextView: ThemeableTextView!
    @IBOutlet weak var descriptionTextView: ThemeableTextView!
    
    @IBOutlet weak var createReadingListButton: WMFAuthButton!
    
    fileprivate var theme: Theme = Theme.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
        readingListNameTextView.textView.delegate = self
        createReadingListButton.isEnabled = false
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    init(theme: Theme) {
        self.theme = theme
        super.init(nibName: "CreateReadingListViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var delegate: CreateReadingListViewControllerDelegate?
    
    @IBAction func createReadingListButtonPressed() {
        let description = descriptionTextView.textView.text
        // The text has to be present for the button to be enabled.
        let name = readingListNameTextView.textView.text!
        
        delegate?.createdNewReadingList(in: self, with: name, description: description)
    }
    
}

extension CreateReadingListViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        createReadingListButton.isEnabled = !textView.text.isEmpty
    }

}

extension CreateReadingListViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        view.tintColor = theme.colors.link
        
        readingListNameTextView.apply(theme: theme)
        descriptionTextView.apply(theme: theme)
        
        titleLabel.textColor = theme.colors.primaryText
        readingListNameLabel.textColor = theme.colors.secondaryText
        descriptionLabel.textColor = theme.colors.secondaryText
        
        createReadingListButton.apply(theme: theme)
       
    }
}