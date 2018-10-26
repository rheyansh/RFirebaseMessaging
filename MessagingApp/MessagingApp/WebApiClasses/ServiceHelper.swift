//
//  ServiceHelper.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import MobileCoreServices

//@@@@@@@@@@@@@@@@@@@@@ Helper constants @@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

//@@ Staging URL

let webApiBaseURL = ""

// Production URL
//let webApiBaseURL = ""

//@@ Basic auth crediantials
let basicAuthUserName = "admin"
let basicAuthPassword = "12345"

//@@ Multipart upload keys
let keyMultiPartData = "data"
let keyMultiPartFileType = "fileType"
let keyMultiPartKeyAtServerSide = "keyAtServerSide"
let keyMultiPartFilePath = "filePath"
let multiPartFileTypeVideo = "video"
let multiPartFileTypeAudio = "audio"
let multiPartFileTypeImage = "image"

let timeoutInterval:Double = 45

enum loadingIndicatorType: CGFloat {
    
    case iLoader  = 0 // interactive loader => showing indicator + user interaction on UI will be enable
    case withoutLoader  = 2 // Actually no loader will be loaded => hiding indicator + user interaction on UI will be disable
}

enum MethodType: CGFloat {
    case get  = 0
    case post  = 1
    case put  = 2
    case delete  = 3
    case patch  = 4
}

//var hud_type: loadingIndicatorType = .iLoader
//var method_type: MethodType = .GET

class ServiceHelper: NSObject {
    
    //MARK:- Public Functions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    
    class func request(params: [String: Any],
                       method: MethodType,
                       apiName: String,
                       hudType: loadingIndicatorType = .iLoader,
                       completionBlock: ((AnyObject?, Error?, Int)->())?) {
        
        //>>>>>>>>>>> create request
        let url = requestURL(method, apiName: apiName, parameterDict: params)
        
        var request = URLRequest(url: url)
        request.httpMethod = methodName(method)
        request.timeoutInterval = timeoutInterval
        
        let jsonData = body(method, parameterDict: params)
        request.httpBody = jsonData

        if method == .post  || method == .put || method == .patch {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        //@@@ Add basic authentication if applicable
        //request.addBasicAuth()
        
        //@@@ Add access token if needed
        request.addAccessParameters(apiName)
        
        Debug.log("\n\n Request URL  >>>>>>\(url)")
        Debug.log("\n\n Request Header >>>>>> \n\(request.allHTTPHeaderFields.debugDescription)")
        Debug.log("Content-Length >>> \(String (jsonData.count))")
        Debug.log("\n\n Request Parameters >>>>>>\n\(params.toJsonString())")
        //Debug.log("\n\n Request Body  >>>>>>\(request.HTTPBody)")
        
        request.perform(hudType: hudType) { (responseObject: AnyObject?, error: Error?, httpResponse: HTTPURLResponse?) in
            
            guard let block = completionBlock else {
                return
            }
            
            DispatchQueue.main.async(execute: {
                guard let httpResponse = httpResponse else {
                    block(responseObject, error, 9999)
                    return
                }
                block(responseObject, error, httpResponse.statusCode)
            })
        }
    }
    
    //<<<<<<<<<<<<<@@@@@@@@@@@@@@@@@@@@@@@@ Multipart upload @@@@@@@@@@@@@@@@@@@@@@@@>>>>>>>>>>>//
    //@@@ mediaArray contains the all media files info in below format
    /*[
     {
     "data" : "nsdata",
     "fileType" : "image",
     "keyAtServerSide" : "thumbnail",
     },
     {
     "data" : "data",
     "fileType" : "video",
     "keyAtServerSide" : "video",
     }
     ]*/
    
    //@@@ fileType will be treated as image as by default
    //@@@ keyAtServerSide is the key for which your server is accepting the media
    //@@@ No need to keyAtServerSide in parameterDict
    //@@@ isUsingFilePathUpload; if you want to upload from filePath,
    // than media array will look like
    /*[
     {
     "filePath" : "filePath url",
     "keyAtServerSide" : "thumbnail",
     },
     {
     "filePath" : "filePath url",
     "keyAtServerSide" : "video",
     }
     ]*/
    //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
    
    class func multiPartRequest(params: [String: Any],
                                method: MethodType,
                                apiName: String,
                                hudType: loadingIndicatorType = .iLoader,
                                mediaArray: Array<Dictionary<String, AnyObject>>,
                                isUsingFilePathUpload: Bool,
                                completionBlock: ((AnyObject?, Error?, Int)->())?) {
        
        //>>>>>>>>>>> create request
        let url = requestURL(method, apiName: apiName, parameterDict: params)
   
        var request = URLRequest(url: url)
        request.httpMethod = methodName(method)
        //request.timeoutInterval = 90
        
        let boundary = self.generateBoundaryString()
        let contentType = "multipart/form-data; boundary=\(boundary)"
        
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        if (isUsingFilePathUpload) {
            request.httpBody = ServiceHelper.createBodyWithBoundary(boundary: boundary, parameters: params, paths: mediaArray)
        } else {
            request.httpBody = ServiceHelper.createBodyWithBoundary(boundary: boundary, parameters: params, mediaArray: mediaArray)
        }
        
        //@@@ Add basic authentication if applicable
        //request.addBasicAuth()
        
        //@@@ Add access token if needed
        request.addAccessParameters(apiName)
        
        Debug.log("\n\n mediaArray  >>>>>>\(mediaArray)")
        Debug.log("\n\n Request URL  >>>>>>\(url)")
        Debug.log("\n\n Request Header >>>>>> \n\(request.allHTTPHeaderFields.debugDescription)")
        //Debug.log("Content-Length >>> \(String (jsonData.count))")
        Debug.log("\n\n Request Parameters >>>>>>\n\(params.toJsonString())")
        //Debug.log("\n\n Request Body  >>>>>>\(request.HTTPBody)")
        
        request.perform(hudType: hudType) { (responseObject: AnyObject?, error: Error?, httpResponse: HTTPURLResponse?) in
            
            guard let block = completionBlock else {
                return
            }
            DispatchQueue.main.async(execute: {
                guard let httpResponse = httpResponse else {
                    block(responseObject, error, 9999)
                    return
                }
                block(responseObject, error, httpResponse.statusCode)
            })
        }
    }
    
    /// Create boundary string for multipart/form-data request
    ///
    /// - returns:            The boundary string that consists of "Boundary-" followed by a UUID string.
    
    class private func generateBoundaryString() -> String {
        let boundary = "Boundary-" + UUID().uuidString
        return boundary
    }
    
    /// Create body of the multipart/form-data request
    ///
    /// - parameter parameters:   The optional dictionary containing keys and values to be passed to web service
    /// - parameter filePathKey:  The optional field name to be used when uploading files. If you supply paths, you must supply filePathKey, too.
    /// - parameter paths:        The optional array of file paths of the files to be uploaded
    /// - parameter boundary:     The multipart/form-data boundary
    ///
    /// - returns:                The NSData of the body of the request
    
    class private func createBodyWithBoundary(boundary: String, parameters: [String: Any], paths: Array<Dictionary<String, AnyObject>>) -> Data {
        
        var httpBody = Data()
        
        for (parameterKey, parameterValue) in parameters.enumerated() {
            
            // add params (all params are strings)

            httpBody.append("--\(boundary)\r\n")
            httpBody.append("Content-Disposition: form-data; name=\"\(parameterKey)\"\r\n\r\n")
            httpBody.append("\(parameterValue)\r\n")
        }
        
        // add file data

        for pathInfo in paths {
            
            guard let filePath = pathInfo[keyMultiPartFilePath] as? String,
            let fieldName = pathInfo[keyMultiPartKeyAtServerSide] as? String else {
                return httpBody
            }
            
            let url = URL(fileURLWithPath: filePath)
            let filename = url.lastPathComponent
            let mimetype = mimeTypeForPath(for: filePath)
            
            var data: Data?
            
            do {
                data = try Data(contentsOf: url)
            } catch {
                print(error)
            }
            
            httpBody.append("--\(boundary)\r\n")
            httpBody.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n")
            httpBody.append("Content-Type: \(mimetype)\r\n\r\n")
            
            if let data = data {
                httpBody.append(data)
            }
            
            httpBody.append("\r\n")
        }
        
        httpBody.append("--\(boundary)--\r\n")
        
        //Debug.log("\(httpBody.count)")
        
        return httpBody
    }
    
    class private func createBodyWithBoundary(boundary: String, parameters: [String: Any], mediaArray: Array<Dictionary<String, AnyObject>>) -> Data {
        
        var httpBody = Data()
        
        for (parameterKey, parameterValue) in parameters.enumerated() {
            
            // add params (all params are strings)
            
            httpBody.append("--\(boundary)\r\n")
            httpBody.append("Content-Disposition: form-data; name=\"\(parameterKey)\"\r\n\r\n")
            httpBody.append("\(parameterValue)\r\n")
        }
        
        // add media data
        
        for mediaInfo in mediaArray {
            
            guard let fieldName = mediaInfo[keyMultiPartKeyAtServerSide] as? String,
                let data = mediaInfo[keyMultiPartData] as? Data else {
                    return httpBody
            }
            
            var fileType = ""
            var mimetype = data.mimeType

            if let type = mediaInfo[keyMultiPartFileType] as? String {
                fileType = type
            }
            
            // Get the Unix timestamp
            let timestamp = NSDate().timeIntervalSince1970
            var filename = "\(timestamp)"
            
            if fileType == multiPartFileTypeVideo {
                filename  = filename + "_video.mp4"
                mimetype = "video/mp4";
            } else if fileType == multiPartFileTypeAudio {
                filename  = filename + "_audio.m4a"
                mimetype = "audio/m4a";
            } else {
                filename  = filename + "_image.png"
            }
            
            httpBody.append("--\(boundary)\r\n")
            httpBody.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n")
            httpBody.append("Content-Type: \(mimetype)\r\n\r\n")
            httpBody.append(data)
            httpBody.append("\r\n")
        }
        
        httpBody.append("--\(boundary)--\r\n")
        
        //Debug.log("\(httpBody.count)")
        
        return httpBody
    }
    
    /// Determine mime type on the basis of extension of a file.
    ///
    /// This requires MobileCoreServices framework.
    ///
    /// - parameter path:         The path of the file for which we are going to determine the mime type.
    ///
    /// - returns:                Returns the mime type if successful. Returns application/octet-stream if unable to determine mime type.

    class private func mimeTypeForPath(for path: String) -> String {
        
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream";
    }

    class private func showErrorAlert(errorDict: Dictionary<String, AnyObject>) {
        
        // go to login screen
        
        var errorTitle = "Authentication Error!"
        let message = "Please login and try again."
        
        if let title = errorDict[pError] as? String {
            errorTitle = title
        }
 
        DispatchQueue.main.async(execute: {
            let alertController = UIAlertController(title: errorTitle, message: message, preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) -> Void in}
            
            let loginAction = UIAlertAction(title: "Login", style: .default) { (action) -> Void in
                APPDELEGATE.logOut()
            }
            alertController.addAction(cancelAction)
            alertController.addAction(loginAction)
            
            UIWindow.currentController!.present(alertController, animated: true, completion: nil)
        })
    }
    
    //MARK:- Private Functions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    
    class fileprivate func methodName(_ method: MethodType)-> String {
        
        switch method {
        case .get: return "GET"
        case .post: return "POST"
        case .delete: return "DELETE"
        case .put: return "PUT"
        case .patch: return "PATCH"

        }
    }
    
    class fileprivate func body(_ method: MethodType, parameterDict: [String: Any]) -> Data {
        
        // Create json with your parameters
        switch method {
        case .post: fallthrough
        case .patch: fallthrough
        case .put: return parameterDict.toData()
        case .get: fallthrough

        default: return Data()
        }
    }
    
    class fileprivate func requestURL(_ method: MethodType, apiName: String, parameterDict: [String: Any]) -> URL {
        let urlString = webApiBaseURL + apiName
        
        switch method {
        case .get:
            return getURL(apiName, parameterDict: parameterDict)
            
        case .post: fallthrough
        case .put: fallthrough
        case .patch: fallthrough

        default: return URL(string: urlString)!
        }
    }
    
    class fileprivate func getURL(_ apiName: String, parameterDict: [String: Any]) -> URL {
        
        var urlString = webApiBaseURL + apiName
        var isFirst = true
        
        for key in parameterDict.keys {
            
            let object = parameterDict[key]
            
            if object is NSArray {
                
                let array = object as! NSArray
                for eachObject in array {
                    var appendedStr = "&"
                    if (isFirst == true) {
                        appendedStr = "?"
                    }
                    urlString += appendedStr + (key) + "=" + (eachObject as! String)
                    isFirst = false
                }
                
            } else {
                var appendedStr = "&"
                if (isFirst == true) {
                    appendedStr = "?"
                }
                let parameterStr = parameterDict[key] as! String
                urlString += appendedStr + (key) + "=" + parameterStr
            }
            
            isFirst = false
        }
        
        let strUrl = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        //let strUrl = urlString.addingPercentEscapes(using: String.Encoding.utf8)
        
        return URL(string:strUrl!)!
    }
    
    class func hideAllHuds(_ status: Bool, type: loadingIndicatorType) {
        //UIApplication.sharedApplication().networkActivityIndicatorVisible = !status
        
        if (type == .withoutLoader) {
            return
        }
        
        DispatchQueue.main.async(execute: {
            var hud = MBProgressHUD(for: APPDELEGATE.window!)
            if hud == nil {
                hud = MBProgressHUD.showAdded(to: APPDELEGATE.window!, animated: true)
            }
            hud?.bezelView.layer.cornerRadius = 8.0
            hud?.bezelView.color = UIColor(red: 222/225.0, green: 222/225.0, blue: 222/225.0, alpha: 222/225.0)
            hud?.margin = 12
            //hud?.activityIndicatorColor = UIColor.white
            
            if (status == false) {
                if (type  == .withoutLoader) {
                   // do nothing
                } else {
                    hud?.show(animated: true)
                }
            } else {
                hud?.hide(animated: true, afterDelay: 0.3)
            }
        })
    }
}

extension URLRequest  {
    
    mutating func addBasicAuth() {
        
        let authStr = basicAuthUserName + ":" + basicAuthPassword
        
        let authData = authStr.data(using: .ascii)
        let authValue = "Basic " + (authData?.base64EncodedString(options: .lineLength64Characters))!
        self.setValue(authValue, forHTTPHeaderField: "Authorization")
    }
    
    mutating func addAccessParameters(_ apiName: String) {
        
        self.setValue("TOKEN_VALUE", forHTTPHeaderField: "keyName")

    }
    
    func perform(hudType: loadingIndicatorType, completionBlock: @escaping (AnyObject?, Error?, HTTPURLResponse?) -> Void) -> Void {
        
        //hud_type = hudType
        if (APPDELEGATE.isReachable == false) {
            AlertController.alert(title: "Connection Error!", message: "Internet connection appears to be offline. Please check your internet connection.")
            return
        }
        
        ServiceHelper.hideAllHuds(false, type: hudType)
        
        let config = URLSessionConfiguration.default // Session Configuration
        let session = URLSession(configuration: config) // Load configuration into Session
        //var session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        
        let task = session.dataTask(with: self, completionHandler: {
            (data, response, error) in
            
            ServiceHelper.hideAllHuds(true, type: hudType)

            if let error = error {
                Debug.log("\n\n error  >>>>>>\n\(error)")
                completionBlock(nil, error, nil)
            } else {
            
                let httpResponse = response as! HTTPURLResponse
                let responseCode = httpResponse.statusCode
                
                //let responseHeaderDict = httpResponse.allHeaderFields
                //Debug.log("\n\n Response Header >>>>>> \n\(responseHeaderDict.debugDescription)")
                Debug.log("Response Code : \(responseCode))")

                if let responseString = NSString.init(data: data!, encoding: String.Encoding.utf8.rawValue) {
                    Debug.log("Response String : \n \(responseString)")
                }
                
                do {
                    let result = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
                      //Debug.log("\n\n result  >>>>>>\n\(result)")
                    completionBlock(result as AnyObject?, nil, httpResponse)
                } catch {
                    
                    Debug.log("\n\n error in JSONSerialization")
                    Debug.log("\n\n error  >>>>>>\n\(error)")
                    
                    if responseCode == 200 {
                        let result = ["responseCode":"200"]
                        completionBlock(result as AnyObject?, nil, httpResponse)
                    } else {
                        //AlertController.alert(title: "", message: "Something went wrong. Please try after some time.")
                        completionBlock(nil, error, httpResponse)
                    }
                }
            }
        })
        
        task.resume()
    }
}

extension NSDictionary {
    func toData() -> Data {
        return try! JSONSerialization.data(withJSONObject: self, options: [])
    }
    
    func toJsonString() -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions.prettyPrinted)
        let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
        return jsonString
    }
}

extension Dictionary {
    
    func toData() -> Data {
        return try! JSONSerialization.data(withJSONObject: self, options: [])
    }
    
    func toJsonString() -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions.prettyPrinted)
        let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
        return jsonString
    }
}

extension Data {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `NSMutableData`.
    
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
    
    private static let mimeTypeSignatures: [UInt8 : String] = [
        0xFF : "image/jpeg",
        0x89 : "image/png",
        0x47 : "image/gif",
        0x49 : "image/tiff",
        0x4D : "image/tiff",
        0x25 : "application/pdf",
        0xD0 : "application/vnd",
        0x46 : "text/plain",
        ]
    
    var mimeType: String {
        var c: UInt8 = 0
        copyBytes(to: &c, count: 1)
        return Data.mimeTypeSignatures[c] ?? "application/octet-stream"
    }
}

func resolutionScale() -> CGFloat {
    
    return UIScreen.main.scale
}


//@@@@@@@@@@@@@@@@@@@@@ Standard response code @@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* multipart upload>> https://stackoverflow.com/questions/26162616/upload-image-with-parameters-in-swift

 >> Standard response codes
 http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
 
 if status == 400 { description = "Bad Request" }
 
 if status == 401 { description = "Unauthorized" }
 
 if status == 402 { description = "Payment Required" }
 
 if status == 403 { description = "Forbidden" }
 
 if status == 404 { description = "Not Found" }
 
 if status == 405 { description = "Method Not Allowed" }
 
 if status == 406 { description = "Not Acceptable" }
 
 if status == 407 { description = "Proxy Authentication Required" }
 
 if status == 408 { description = "Request Timeout" }
 
 if status == 409 { description = "Conflict" }
 
 if status == 410 { description = "Gone" }
 
 if status == 411 { description = "Length Required" }
 
 if status == 412 { description = "Precondition Failed" }
 
 if status == 413 { description = "Payload Too Large" }
 
 if status == 414 { description = "URI Too Long" }
 
 if status == 415 { description = "Unsupported Media Type" }
 
 if status == 416 { description = "Requested Range Not Satisfiable" }
 
 if status == 417 { description = "Expectation Failed" }
 
 if status == 422 { description = "Unprocessable Entity" }
 
 if status == 423 { description = "Locked" }
 
 if status == 424 { description = "Failed Dependency" }
 
 if status == 425 { description = "Unassigned" }
 
 if status == 426 { description = "Upgrade Required" }
 
 if status == 427 { description = "Unassigned" }
 
 if status == 428 { description = "Precondition Required" }
 
 if status == 429 { description = "Too Many Requests" }
 
 if status == 430 { description = "Unassigned" }
 
 if status == 431 { description = "Request Header Fields Too Large" }
 
 if status == 432 { description = "Unassigned" }
 
 if status == 500 { description = "Internal Server Error" }
 
 if status == 501 { description = "Not Implemented" }
 
 if status == 502 { description = "Bad Gateway" }
 
 if status == 503 { description = "Service Unavailable" }
 
 if status == 504 { description = "Gateway Timeout" }
 
 if status == 505 { description = "HTTP Version Not Supported" }
 
 if status == 506 { description = "Variant Also Negotiates" }
 
 if status == 507 { description = "Insufficient Storage" }
 
 if status == 508 { description = "Loop Detected" }
 
 if status == 509 { description = "Unassigned" }
 
 if status == 510 { description = "Not Extended" }
 
 if status == 511 { description = "Network Authentication Required" }
 
 */
