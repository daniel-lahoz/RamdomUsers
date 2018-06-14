
import CoreLocation
import UIKit


// MARK: - UIViewController
class FeedViewController: UIViewController {
    var photos: [User]?
    var currentMessage = "Loading data, please wait :)"
    let cellIdentifier = "userCell"
    let messageCellIdentifier = "messageCell"
    
    var filtredText: String = ""
    
    var activeUserCell : UserCell? = nil

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var filtredTextField: UITextField!
    @IBOutlet weak var switchgender: UISwitch!
    @IBOutlet weak var switchFavorites: UISwitch!
    @IBOutlet weak var switchKM: UISwitch!
    
    let locationManager = CLLocationManager()
    var location: CLLocation? = nil
    
    //DetailView
    @IBOutlet var detailView: UIView!
    
    @IBOutlet weak var detailPicture: UIImageView!
    @IBOutlet weak var detailName: UILabel!
    @IBOutlet weak var detailEmail: UILabel!
    @IBOutlet weak var detailPhone: UILabel!
    @IBOutlet weak var detailgender: UILabel!
    @IBOutlet weak var detailAdress: UILabel!
    @IBOutlet weak var detailClose: UIButton!
    
    // MARK: - UIView methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        User.getAllFeedPhotos { [weak self] (photos, error) in
          guard error == nil else {
            if let error = error as? UserServiceError {
              self?.currentMessage = error.rawValue
            } else if let error = error as NSError? {
              self?.currentMessage = error.localizedDescription
            } else {
              self?.currentMessage = "Sorry, there was an error."
            }
            self?.photos = nil
            self?.collectionView?.reloadData()
            return
          }
          self?.photos = photos?.uniqueElements
          self!.photos?.sortByName()
          self?.collectionView?.reloadData()
        }
    }

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            self.detailView.center = self.view.center
        }) { _ in}
    }

    
    @IBAction func touchAddMoreContacts(_ sender: AnyObject) {
        
        User.getAllFeedPhotos { [weak self] (photos, error) in
            guard error == nil else {
                return
            }
            
            let photosListNew = photos!.uniqueElements
            let photosListOld = self!.photos!
            self?.photos = photosListNew + photosListOld
            
            if self!.switchgender.isOn {
                self!.photos?.sortByGender()
            }else{
                self!.photos?.sortByName()
            }
            
            self?.collectionView?.reloadData()
            
            //print("filtrado \(self?.photos?.filtredElements("li"))")
        }

    }
    
    @IBAction func sortgenderChange(_ genderSwitch: UISwitch) {
        if genderSwitch.isOn {
            self.photos?.sortByGender()
        }else{
            self.photos?.sortByName()
        }
        
        self.collectionView.reloadData()
        
    }
    
    
    @IBAction func filtredOnlyFavorites(_ sender: AnyObject) {
        self.switchKM.isOn = false
        self.collectionView.reloadData()
    }
    
    @IBAction func onekmChanges(_ sender: AnyObject) {
        self.switchFavorites.isOn = false
        self.collectionView.reloadData()
    }
    
    @IBAction func filtredChanged(_ textField: UITextField) {
        self.filtredText = textField.text!
        self.collectionView.reloadData()
    }
    
    @IBAction func closeDetailView(_ sender: AnyObject) {
        
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            
            let senderFrame = self.collectionView.convert(self.activeUserCell!.frame, to: self.view)
            self.detailView.frame = senderFrame
            
            self.view.layoutIfNeeded()
            
        }) { _ in
            self.detailView.removeFromSuperview()
            self.detailView.frame.size.width = 300
            self.detailView.frame.size.height = 100
        }
        
        
        
    }
    
}


// MARK: - UICollectionView delegate/data source

extension FeedViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let photos = photos else { return 1 }
        
        if switchFavorites.isOn {
            return photos.favoriteElements().filtredElements(self.filtredText).count
        }
        
        if switchKM.isOn {
            guard let mylocation = self.location else {
                return 0
            }
            return photos.onekmElements(mylocation).filtredElements(self.filtredText).count
        }
        
        return photos.filtredElements(self.filtredText).count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: UICollectionViewCell
        //We force non reuse cells
        
        if switchKM.isOn {
            if let photos = self.photos?.onekmElements(self.location!).filtredElements(self.filtredText) , self.photos!.onekmElements(self.location!).filtredElements(self.filtredText).count > 0 {
                
                let userCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! UserCell
                
                userCell.delegate = self
                userCell.photo = photos[(indexPath as NSIndexPath).item]
                cell = userCell
                
            } else {
                let messageCell = collectionView.dequeueReusableCell(withReuseIdentifier: messageCellIdentifier, for: indexPath) as! MessageCell
                
                messageCell.messageLabel.text = currentMessage
                messageCell.messageLabel.isHidden = false
                cell = messageCell
                
            }
        
        }else{
            
            if switchFavorites.isOn {
                if let photos = self.photos?.favoriteElements().filtredElements(self.filtredText) , self.photos!.favoriteElements().filtredElements(self.filtredText).count > 0 {
                    
                    let userCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! UserCell
                    
                    userCell.delegate = self
                    userCell.photo = photos[(indexPath as NSIndexPath).item]
                    cell = userCell
                    
                } else {
                    let messageCell = collectionView.dequeueReusableCell(withReuseIdentifier: messageCellIdentifier, for: indexPath) as! MessageCell
                    
                    messageCell.messageLabel.text = currentMessage
                    messageCell.messageLabel.isHidden = false
                    cell = messageCell
                    
                }
            }else{
                if let photos = self.photos?.filtredElements(self.filtredText) , self.photos!.filtredElements(self.filtredText).count > 0 {
                    
                    let userCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! UserCell
//                    let identi = "ident-\(indexPath.section)-\(indexPath.row)-\(indexPath.item)-"
//                    let nib = UINib(nibName: "UserCell", bundle: nil)
//                    collectionView.registerNib(nib, forCellWithReuseIdentifier: identi)
//                    let userCell = collectionView.dequeueReusableCellWithReuseIdentifier(identi, forIndexPath: indexPath) as! UserCell
                    
                    userCell.delegate = self
                    userCell.photo = photos[(indexPath as NSIndexPath).item]
                    cell = userCell
                    
                } else {
                    let messageCell = collectionView.dequeueReusableCell(withReuseIdentifier: messageCellIdentifier, for: indexPath) as! MessageCell
                    
                    messageCell.messageLabel.text = currentMessage
                    messageCell.messageLabel.isHidden = false
                    cell = messageCell
                    
                }
            }
            
        }
        
        return cell
        
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //All stuff is gestioned on UserCellDelegate
    }
    
}


// MARK: - UserCell Delegate
extension FeedViewController: UserCellDelegate {
    
    func didTouchPhoto(_ sender: UserCell) {
        
        let senderFrame = self.collectionView.convert(sender.frame, to: self.view)
        
        self.detailView.frame = senderFrame
        
        self.detailName.text = "\(sender.photo!.name) \(sender.photo!.surname)"
        self.detailEmail.text = sender.photo!.email
        self.detailPhone.text = sender.photo!.phone
        self.detailAdress.text = "\(sender.photo!.street), \(sender.photo!.city), \(sender.photo!.state)"
        self.detailgender.text = sender.photo!.gender
        self.detailPicture.image = sender.photo!.image
        
        self.view.addSubview(self.detailView)
        self.view.layoutIfNeeded()
        
        self.activeUserCell = sender
        
        UIView.animate(withDuration: 0.6, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            
            self.detailView.frame.size.width = 400
            self.detailView.frame.size.height = 250
            self.detailView.center = self.view.center
            
            self.view.layoutIfNeeded()
            
        }) { _ in}
    
    }
    
    func didTouchFavorite(_ sender: UserCell) {
        
        sender.photo!.favorite = !sender.photo!.favorite
        
         self.collectionView.reloadData()
        
        let favorites = self.photos?.favoriteElements()
        print("favorites \(String(describing: favorites))")
        
    }
    
    func didRemove(_ sender: UserCell) {
        
        self.photos?.removeObject(sender.photo!)
        
        self.collectionView.reloadData()
        
    }
    
    
}



// MARK: - CLLocationManager Delegate
extension FeedViewController: CLLocationManagerDelegate {
  
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        //print("locations = \(locValue.latitude) \(locValue.longitude)")
        self.location = manager.location!
    }
    
}



// MARK: - Hashtable and Equatalbe Extension for get Unique Elements genderator @see: http://stackoverflow.com/a/33553374
public extension Sequence where Iterator.Element: Hashable {
    var uniqueElements: [Iterator.Element] {
        return Array(
            Set(self)
        )
    }
}
public extension Sequence where Iterator.Element: Equatable {
    var uniqueElements: [Iterator.Element] {
        return self.reduce([]){uniqueElements, element in
            uniqueElements.contains(element) ? uniqueElements : uniqueElements + [element]
        }
    }
}

// MARK: - Array extension for remove objects and get favorites
extension Array where Element: User {
    
    mutating func removeObject(_ object: Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }
    
    mutating func removeObjectsInArray(_ array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
    
    mutating func sortByName(){
        self.sort(by: { $0.name < $1.name })
    }
    
    mutating func sortByGender(){
        self.sort(by: { $0.gender < $1.gender })
    }
    
    func favoriteElements() -> [User]{
        return self.reduce([]){favoriteElements, element in
            element.favorite ? favoriteElements + [element] : favoriteElements
        }
    }
    
    func onekmElements(_ location: CLLocation) -> [User]{
        return self.reduce([]){onekmElements, element in
            element.fakelocation.distance(from: location) < 1000 ? onekmElements + [element] : onekmElements
        }

    }
    
    func filtredElements(_ filtred: String) -> [User]{
        
        if filtred.count > 0 {
            
            let emailList = self.filter({
                if $0.email.range(of: filtred) != nil{
                    return true
                }
                return false
            })
            
            let namelList = self.filter({
                if $0.name.range(of: filtred) != nil{
                    return true
                }
                return false
            })
            
            let surnameList = self.filter({
                if $0.surname.range(of: filtred) != nil{
                    return true
                }
                return false
            })
            
            let rawList = emailList + namelList + surnameList
            let list = rawList.uniqueElements
            
            return list

        }
        
        return self
    }

}


