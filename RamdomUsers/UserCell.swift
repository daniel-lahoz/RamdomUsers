

import UIKit

protocol UserCellDelegate: class {
    func didTouchFavorite(sender: UserCell)
    func didTouchPhoto(sender: UserCell)
    func didRemove(sender: UserCell)
}


class UserCell: UICollectionViewCell {
    
    weak var delegate:UserCellDelegate?
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    
    

    var imageTask: NSURLSessionDownloadTask?

    var photo: User? {
        didSet {
            imageTask?.cancel()
            
            //print("User: \(photo?.description)")
            if let name = photo?.name, surname = photo?.surname, email = photo?.email, phone = photo?.phone  {
                nameLabel.text = "\(name) \(surname)"
                emailLabel.text = email
                phoneLabel.text = phone
            }
            
            if photo?.favorite == true{
                favoriteButton.setTitleColor(UIColor.greenColor(), forState: .Normal)
            }else{
                favoriteButton.setTitleColor(UIColor.purpleColor(), forState: .Normal)
            }
            
            if let storedImage = photo?.image{
                self.photoImageView.image = storedImage
                return
            }
            
            guard let photoUrl = photo?.photoUrl else {
                self.photoImageView.image = UIImage(named: "Downloading")
                return
            }
            
            
            imageTask = NetworkClient.sharedInstance.getImageInBackground(photoUrl) { [weak self] (image, error) in
                guard error == nil else {
                    self?.photoImageView.image = UIImage(named: "Broken")
                    return
                }
                
                self?.photoImageView.image = image
                self?.photo?.image = image!.copy() as? UIImage
            
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photo = nil
    }
    
    @IBAction func touchPhoto(sender: AnyObject) {
        delegate?.didTouchPhoto(self)
    }
    
    @IBAction func touchRemove(sender: AnyObject) {
        delegate?.didRemove(self)
    }
    
    @IBAction func touchFavorite(sender: AnyObject) {
         delegate?.didTouchFavorite(self)
    }
    
}


