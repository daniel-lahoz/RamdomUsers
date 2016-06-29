
import Foundation

enum UserServiceError: String, ErrorType {
  case NotImplemented = "This feature has not been implemented yet"
  case URLParsing = "Sorry, there was an error getting the photos"
  case JSONStructure = "Sorry, the photo service returned something different than expected"
}

typealias UserResult = ([User]?, ErrorType?) -> Void

extension User {
    
  class func getAllFeedPhotos(completion: UserResult) {
    
    guard let url = NSURL(string: "http://api.randomuser.me/?results=300") else {
      completion(nil, UserServiceError.URLParsing)
      return
    }

    NetworkClient.sharedInstance.getURL(url) { (result, error) in
      guard error == nil else {
        completion(nil, error)
        return
      }
      if let dictionary = result as? NSDictionary, items = dictionary["results"] as? [NSDictionary] {
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