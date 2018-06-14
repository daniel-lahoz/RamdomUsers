
import Foundation

enum UserServiceError: String, Error {
  case NotImplemented = "This feature has not been implemented yet"
  case URLParsing = "Sorry, there was an error getting the photos"
  case JSONStructure = "Sorry, the photo service returned something different than expected"
}

typealias UserResult = ([User]?, Error?) -> Void

extension User {
    
  class func getAllFeedPhotos(_ completion: @escaping UserResult) {
    
    guard let url = URL(string: "http://api.randomuser.me/?results=30") else {
      completion(nil, UserServiceError.URLParsing)
      return
    }

    NetworkClient.sharedInstance.getURL(url) { (result, error) in
      guard error == nil else {
        completion(nil, error)
        return
      }
      if let dictionary = result as? NSDictionary, let items = dictionary["results"] as? [NSDictionary] {
        var photos = [User]()
        for item in items {
          photos.append(User(dictionary: item))
        }
        completion(photos, nil)
      } else {
        completion(nil, UserServiceError.JSONStructure)
      }
    }
    
    
  }
    
    
}
