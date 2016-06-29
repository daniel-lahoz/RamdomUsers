

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
    
    @IBOutlet weak var progressbar: UIProgressView!
    

    var imageTask: NSURLSessionDownloadTask?
    var fileTask: NSURLSessionDownloadTask?

    var photo: User? {
        didSet {
            imageTask?.cancel()
            
            photo?.delegate = self
            progressbar.hidden = true
            
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
            
            
            imageTask = NetworkClient.sharedInstance.getImageInBackground(photoUrl) { [weak self] (image, progress, error) in
                guard error == nil else {
                    self?.photoImageView.image = UIImage(named: "Broken")
                    return
                }
                
                guard progress != nil else {
                    return
                }
                print("tarea: \(self!.photo?.photoUrl) progreso:\(progress)")
                self?.progressbar.hidden = false
                self?.progressbar.progress = progress!
                
                guard image != nil else {
                    return
                }
                
                self?.progressbar.hidden = true
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
    
    @IBAction func touchFile(sender: AnyObject) {
        
        self.photo?.downloadFile()
        
        /*
        fileTask?.cancel()

        let url = NSURL(string: "http://www.proyectos-simed.es/firmacorreo/DrUrbano.m4v")
        
        fileTask = NetworkClient.sharedInstance.getFileInBackground(url!) { [weak self] (file, progress, error) in
            guard error == nil else {
                return
            }
            
            guard progress != nil else {
                return
            }
            print("tarea: \(self!.photo?.photoUrl) progreso:\(progress)")
            self?.progressbar.hidden = false
            self?.progressbar.progress = progress!
            
            guard file != nil else {
                return
            }
            
            self?.progressbar.hidden = true

            
        }
 */
    }


}

extension UserCell : UserDelegate{
    
    func isDownloading(progress: Float, email: String){
        
        if email == self.emailLabel.text{
            if progress < 0.99 {
                self.progressbar.hidden = false
                self.progressbar.progress = progress
                print("lblemail: \(self.emailLabel.text)")
            }else{
                self.progressbar.hidden = true
            }
        }else{
             self.progressbar.hidden = true
        }
        
    }
}


