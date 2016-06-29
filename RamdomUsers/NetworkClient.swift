

import UIKit

enum NetworkClientError: ErrorType {
    case ImageData
    case FileData
}

typealias NetworkResult = (AnyObject?, ErrorType?) -> Void
//typealias ImageResult = (UIImage?, ErrorType?) -> Void
typealias ImageResult = (UIImage?, Float?, ErrorType?) -> Void
typealias FileResult = (NSData?, Float?, ErrorType?) -> Void

let kBackgroundSessionID = "api.randomuser.me"
let kFileBackgroundSession = "file"

class NetworkClient: NSObject {
  private var urlSession: NSURLSession
  private var backgroundSession: NSURLSession!
    private var fileBackgroundSession: NSURLSession!
  private var completionHandlers = [NSURL: ImageResult]()
    private var fileHandlers = [NSURL: FileResult]()
  static let sharedInstance = NetworkClient()

  override init() {
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    urlSession = NSURLSession(configuration: configuration)
    super.init()
    let backgroundConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(kBackgroundSessionID)
    backgroundSession = NSURLSession(configuration: backgroundConfiguration, delegate: self, delegateQueue: nil)
    let fileBackgroundConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(kFileBackgroundSession)
    fileBackgroundSession = NSURLSession(configuration: fileBackgroundConfiguration, delegate: self, delegateQueue: nil)

  }

  // MARK: service methods

  func getURL(url: NSURL, completion: NetworkResult) {
    let request = NSURLRequest(URL: url)
    let task = urlSession.dataTaskWithRequest(request) { [unowned self] (data, response, error) in
      guard let data = data else {
        NSOperationQueue.mainQueue().addOperationWithBlock {
          completion(nil, error)
        }
        return
      }
      self.parseJSON(data, completion: completion)
    }
    task.resume()
  }
    
  func getImageInBackground(url: NSURL, completion: ImageResult?) -> NSURLSessionDownloadTask {
    completionHandlers[url] = completion
    let request = NSURLRequest(URL: url)
    let task = backgroundSession.downloadTaskWithRequest(request)
    task.resume()
    return task
  }
    
    func getFileInBackground(url: NSURL, completion: FileResult?) -> NSURLSessionDownloadTask {
        fileHandlers[url] = completion
        let request = NSURLRequest(URL: url)
        let task = fileBackgroundSession.downloadTaskWithRequest(request)
        task.resume()
        return task
    }

  // MARK: helper methods

  private func parseJSON(data: NSData, completion: NetworkResult) {
    do {
      let fixedData = fixedJSONData(data)
      let parseResults = try NSJSONSerialization.JSONObjectWithData(fixedData, options: [])
      if let dictionary = parseResults as? NSDictionary {
        NSOperationQueue.mainQueue().addOperationWithBlock {
          completion(dictionary, nil)
        }
      } else if let array = parseResults as? [NSDictionary] {
        NSOperationQueue.mainQueue().addOperationWithBlock {
          completion(array, nil)
        }
      }
    } catch let parseError {
      NSOperationQueue.mainQueue().addOperationWithBlock {
        completion(nil, parseError)
      }
    }
  }

  private func fixedJSONData(data: NSData) -> NSData {
    guard let jsonString = String(data: data, encoding: NSUTF8StringEncoding) else { return data }
    let fixedString = jsonString.stringByReplacingOccurrencesOfString("\\'", withString: "'")
    if let fixedData = fixedString.dataUsingEncoding(NSUTF8StringEncoding) {
      return fixedData
    } else {
      return data
    }
  }
}



extension NetworkClient: NSURLSessionDelegate, NSURLSessionDownloadDelegate {
    
    
  func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
    
    if session.configuration.identifier == kFileBackgroundSession{
        if let error = error, url = task.originalRequest?.URL, completion = fileHandlers[url] {
            fileHandlers[url] = nil
            NSOperationQueue.mainQueue().addOperationWithBlock {
                completion(nil, nil, error)
            }
        }
    }else if session.configuration.identifier == kBackgroundSessionID{
        if let error = error, url = task.originalRequest?.URL, completion = completionHandlers[url] {
            completionHandlers[url] = nil
            NSOperationQueue.mainQueue().addOperationWithBlock {
                completion(nil, nil, error)
            }
        }
    }
    
  }

  func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
    
    if session.configuration.identifier == kFileBackgroundSession{
        // You must move the file or open it for reading before this closure returns or it will be deleted
        if let data = NSData(contentsOfURL: location), request = downloadTask.originalRequest, response = downloadTask.response {
            let cachedResponse = NSCachedURLResponse(response: response, data: data)
            self.urlSession.configuration.URLCache?.storeCachedResponse(cachedResponse, forRequest: request)
            if let url = downloadTask.originalRequest?.URL, completion = fileHandlers[url] {
                fileHandlers[url] = nil
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    completion(data, 1.0, nil)
                }
            }
        } else {
            if let url = downloadTask.originalRequest?.URL, completion = fileHandlers[url] {
                fileHandlers[url] = nil
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    completion(nil, nil, NetworkClientError.FileData)
                }
            }
        }
    }else if session.configuration.identifier == kBackgroundSessionID{
        // You must move the file or open it for reading before this closure returns or it will be deleted
        if let data = NSData(contentsOfURL: location), image = UIImage(data: data), request = downloadTask.originalRequest, response = downloadTask.response {
            let cachedResponse = NSCachedURLResponse(response: response, data: data)
            self.urlSession.configuration.URLCache?.storeCachedResponse(cachedResponse, forRequest: request)
            if let url = downloadTask.originalRequest?.URL, completion = completionHandlers[url] {
                completionHandlers[url] = nil
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    completion(image, 1.0, nil)
                }
            }
        } else {
            if let url = downloadTask.originalRequest?.URL, completion = completionHandlers[url] {
                completionHandlers[url] = nil
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    completion(nil, nil, NetworkClientError.ImageData)
                }
            }
        }
    }
    

  }
    

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if session.configuration.identifier == kFileBackgroundSession{
            if let url = downloadTask.originalRequest?.URL, completion = fileHandlers[url] {
                let progress : Float = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    completion(nil, progress, nil)
                }
            }
        }else if session.configuration.identifier == kBackgroundSessionID{
            if let url = downloadTask.originalRequest?.URL, completion = completionHandlers[url] {
                let progress : Float = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    completion(nil, progress, nil)
                }
            }
        }
        


    
    }
    
  func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {

        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, completionHandler = appDelegate.backgroundSessionCompletionHandler {
            appDelegate.backgroundSessionCompletionHandler = nil
            completionHandler()
        }

  }
    
    
    
}
