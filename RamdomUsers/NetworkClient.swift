
import UIKit

enum NetworkClientError: Error {
    case imageData
    case fileData
}

typealias NetworkResult = (AnyObject?, Error?) -> Void
//typealias ImageResult = (UIImage?, ErrorType?) -> Void
typealias ImageResult = (UIImage?, Float?, Error?) -> Void
typealias FileResult = (Data?, Float?, Error?) -> Void

let kBackgroundSessionID = "api.randomuser.me"
let kFileBackgroundSession = "file"

class NetworkClient: NSObject {
    fileprivate var urlSession: Foundation.URLSession
    fileprivate var backgroundSession: Foundation.URLSession!
    fileprivate var fileBackgroundSession: Foundation.URLSession!
    fileprivate var completionHandlers = [URL: ImageResult]()
    fileprivate var fileHandlers = [URL: FileResult]()
    
    static let sharedInstance = NetworkClient()

    override init() {
        let configuration = URLSessionConfiguration.default
        urlSession = Foundation.URLSession(configuration: configuration)
        super.init()
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: kBackgroundSessionID)
        backgroundSession = Foundation.URLSession(configuration: backgroundConfiguration, delegate: self, delegateQueue: nil)
        let fileBackgroundConfiguration = URLSessionConfiguration.background(withIdentifier: kFileBackgroundSession)
        fileBackgroundSession = Foundation.URLSession(configuration: fileBackgroundConfiguration, delegate: self, delegateQueue: nil)
    }

    // MARK: service methods

    func getURL(_ url: URL, completion: @escaping NetworkResult) {
        let request = URLRequest(url: url)
        let task = urlSession.dataTask(with: request, completionHandler: { [unowned self] (data, response, error) in
            guard let data = data else {
                OperationQueue.main.addOperation {
                    completion(nil, error)
                }
                return
            }
            self.parseJSON(data, completion: completion)
        })
        task.resume()
    }
    
    func getImageInBackground(_ url: URL, completion: ImageResult?) -> URLSessionDownloadTask {
        completionHandlers[url] = completion
        let request = URLRequest(url: url)
        let task = backgroundSession.downloadTask(with: request)
        task.resume()
        return task
    }
    
    func getFileInBackground(_ url: URL, completion: FileResult?) -> URLSessionDownloadTask {
        fileHandlers[url] = completion
        let request = URLRequest(url: url)
        let task = fileBackgroundSession.downloadTask(with: request)
        task.resume()
        return task
    }

    // MARK: helper methods

    fileprivate func parseJSON(_ data: Data, completion: @escaping NetworkResult) {
        do {
            let fixedData = fixedJSONData(data)
            let parseResults = try JSONSerialization.jsonObject(with: fixedData, options: [])
            if let dictionary = parseResults as? NSDictionary {
                OperationQueue.main.addOperation {
                  completion(dictionary, nil)
                }
            } else if let array = parseResults as? [NSDictionary] {
                OperationQueue.main.addOperation {
                  completion(array as AnyObject?, nil)
                }
            }
        } catch let parseError {
            OperationQueue.main.addOperation {
            completion(nil, parseError)
            }
        }
    }

    fileprivate func fixedJSONData(_ data: Data) -> Data {
        guard let jsonString = String(data: data, encoding: String.Encoding.utf8) else { return data }
        let fixedString = jsonString.replacingOccurrences(of: "\\'", with: "'")
        if let fixedData = fixedString.data(using: String.Encoding.utf8) {
            return fixedData
        } else {
            return data
        }
    }
    
}



extension NetworkClient: URLSessionDelegate, URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    
        if session.configuration.identifier == kFileBackgroundSession{
            if let error = error, let url = task.originalRequest?.url, let completion = fileHandlers[url] {
                fileHandlers[url] = nil
                OperationQueue.main.addOperation {
                    completion(nil, nil, error)
                }
            }
        }else if session.configuration.identifier == kBackgroundSessionID{
            if let error = error, let url = task.originalRequest?.url, let completion = completionHandlers[url] {
                completionHandlers[url] = nil
                OperationQueue.main.addOperation {
                    completion(nil, nil, error)
                }
            }
        }
    }

    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    
        if session.configuration.identifier == kFileBackgroundSession{
            // You must move the file or open it for reading before this closure returns or it will be deleted
            if let data = try? Data(contentsOf: location), let request = downloadTask.originalRequest, let response = downloadTask.response {
                let cachedResponse = CachedURLResponse(response: response, data: data)
                self.urlSession.configuration.urlCache?.storeCachedResponse(cachedResponse, for: request)
                if let url = downloadTask.originalRequest?.url, let completion = fileHandlers[url] {
                    fileHandlers[url] = nil
                    OperationQueue.main.addOperation {
                        completion(data, 1.0, nil)
                    }
                }
            } else {
                if let url = downloadTask.originalRequest?.url, let completion = fileHandlers[url] {
                    fileHandlers[url] = nil
                    OperationQueue.main.addOperation {
                        completion(nil, nil, NetworkClientError.fileData)
                    }
                }
            }
        }else if session.configuration.identifier == kBackgroundSessionID{
            // You must move the file or open it for reading before this closure returns or it will be deleted
            if let data = try? Data(contentsOf: location), let image = UIImage(data: data), let request = downloadTask.originalRequest, let response = downloadTask.response {
                let cachedResponse = CachedURLResponse(response: response, data: data)
                self.urlSession.configuration.urlCache?.storeCachedResponse(cachedResponse, for: request)
                if let url = downloadTask.originalRequest?.url, let completion = completionHandlers[url] {
                    completionHandlers[url] = nil
                    OperationQueue.main.addOperation {
                        completion(image, 1.0, nil)
                    }
                }
            } else {
                if let url = downloadTask.originalRequest?.url, let completion = completionHandlers[url] {
                    completionHandlers[url] = nil
                    OperationQueue.main.addOperation {
                        completion(nil, nil, NetworkClientError.imageData)
                    }
                }
            }
        }
    

    }
    

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if session.configuration.identifier == kFileBackgroundSession{
            if let url = downloadTask.originalRequest?.url, let completion = fileHandlers[url] {
                let progress : Float = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                OperationQueue.main.addOperation {
                    completion(nil, progress, nil)
                }
            }
        }else if session.configuration.identifier == kBackgroundSessionID{
            if let url = downloadTask.originalRequest?.url, let completion = completionHandlers[url] {
                let progress : Float = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                OperationQueue.main.addOperation {
                    completion(nil, progress, nil)
                }
            }
        }

    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let completionHandler = appDelegate.backgroundSessionCompletionHandler {
            appDelegate.backgroundSessionCompletionHandler = nil
            completionHandler()
        }
    }
    
    
    
}
