/*
 * Copyright 2015-2016 IBM Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

public enum WhiskNetworkError: ErrorProtocol {
    case MalformedUrlString(url: String, cause: String)
    case QualifiedNameFormat(description: String)
}


/* Type of Whisk operation requested */
enum WhiskCallType {
    case Action
    case Trigger
    case Package
    case Rule
    case Sequence
}

public struct WhiskCredentials {
    // whisk credentials
    public var accessKey: String!
    public var accessToken: String!
    
    public init(accessKey: String?, accessToken: String?) {
        self.accessToken = accessToken
        self.accessKey = accessKey
    }
    
    public func getBase64AuthString() -> String {
        // set authorization string
        let loginString = (accessKey+":"+accessToken) as NSString
        
        let loginData: NSData = loginString.data(using: String.Encoding.utf8.rawValue)!
        let base64LoginString = loginData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        return base64LoginString
    }
    
}


class WhiskAPI {
    
    // Default value for Whisk backend
    var DefaultBaseURL = "https://openwhisk.ng.bluemix.net/api/v1/"
    
    // user settable backend
    var whiskBaseURL: String?
    
    // credentials
    let whiskCredentials: WhiskCredentials!
    
    // network classes
    let networkManager: WhiskNetworkManager!
    // return base URL of backend including common path for all API calls
    var baseURL: String? {
        set {
            if let url = newValue {
                let c = url.characters.last
                let separater =  c == "/" ? "" : "/"
                whiskBaseURL = url + separater + "api/v1/"
            } else {
                whiskBaseURL = nil
            }
        }
        get {
            return whiskBaseURL
        }
    }
    
    // Initialize with credentials, region currently not used
    init(credentials: WhiskCredentials, session: URLSession? = nil) {
        // initialize
        whiskCredentials = credentials
        
        let sess: URLSession!
        if let _ = session {
            sess = session
        } else {
            let sessConfig = URLSessionConfiguration.default
            sess = URLSession(configuration: sessConfig)
        }
        
        networkManager = WhiskNetworkManager(credentials: credentials, session: sess)
    }
    
    /* Convert qualified name string into component parts of action or trigger call */
    func processQualifiedName(qName: String) throws -> (namespace:String, package: String?, name: String) {
        var namespace = "_"
        var package: String? = nil
        var name = ""
        var doesSpecifyNamespace = false
        
        if qName.characters.first == "/" {
            doesSpecifyNamespace = true
        }
        
        let pathParts = qName.characters.split { $0 == "/" }.map(String.init)
        
        if doesSpecifyNamespace == true {
            if pathParts.count == 2 {
                namespace = pathParts[0]
                name = pathParts[1]
            } else if pathParts.count == 3 {
                namespace = pathParts[0]
                package = pathParts[1]
                name = pathParts[2]
            } else {
                throw WhiskNetworkError.QualifiedNameFormat(description: "Cannot parse \(qName)")
            }
        } else {
            if pathParts.count == 1 {
                name = pathParts[0]
            } else if pathParts.count == 2 {
                package = pathParts[0]
                name = pathParts[1]
            } else {
                throw WhiskNetworkError.QualifiedNameFormat(description: "Cannot parse \(qName)")
            }
        }
        
        return (namespace, package, name)
    }
    
    func createTrigger(name: String, namespace: String, parameters: Array<[String:AnyObject]>? = nil, group: DispatchGroup) throws {
        
        let urlStr: String = whiskBaseURL != nil ? whiskBaseURL! : DefaultBaseURL
        
        
        let path = "namespaces/\(namespace)/triggers/\(name)"
        var whiskParameters = [String:AnyObject]()
        
        if let parameters = parameters {
            
            var paramArray = Array<[String:AnyObject]>()
            for param in parameters {
                
                for (key, value) in param {
                    var pair = [String:AnyObject]()
                    pair["key"] = key as AnyObject
                    pair["value"] = value
                    paramArray.append(pair)
                }
            }
            
            whiskParameters["parameters"] = paramArray as AnyObject
        }
        
        group.enter()
        try networkManager.putCall(url: urlStr, path: path, parameters: whiskParameters, group: group)
        
    }
    
    func createAction(qualifiedName: String, kind: String, code: String, parameters: Array<[String:AnyObject]>? = nil, group: DispatchGroup) throws {
        
        let urlStr: String = whiskBaseURL != nil ? whiskBaseURL! : DefaultBaseURL
        
        let nameParts = try processQualifiedName(qName: qualifiedName)
        
        var path = ""
        if nameParts.package != nil {
            path = "namespaces/\(nameParts.namespace)/actions/\(nameParts.package!)/\(nameParts.name)"
        } else {
            path = "namespaces/\(nameParts.namespace)/actions/\(nameParts.name)"
        }
        
        let exec = ["kind":kind, "code": code] as [String:String]
        let limits = ["timeout": 30000, "memory":256] as [String:AnyObject]
        
        var whiskParameters: [String:AnyObject] = ["exec":exec as AnyObject, "limits":limits as AnyObject]
        
        if let parameters = parameters {
            
            var paramArray = Array<[String:AnyObject]>()
            for param in parameters {
                
                for (key, value) in param {
                    var pair = [String:AnyObject]()
                    pair["key"] = key as AnyObject
                    pair["value"] = value
                    paramArray.append(pair)
                    
                }
                
            }
            
            whiskParameters["parameters"] = paramArray as AnyObject
        }
        
        group.enter()
        try networkManager.putCall(url: urlStr, path: path, parameters: whiskParameters, group: group)
        
        
    }
    
    func createPackage(name: String, bindTo:String? = nil, namespace: String, parameters: Array<[String:AnyObject]>? = nil, group: DispatchGroup) throws {
        let urlStr: String = whiskBaseURL != nil ? whiskBaseURL! : DefaultBaseURL
        
        let path = "namespaces/\(namespace)/packages/\(name)"
        
        var whiskParameters = [String:AnyObject]()
        
        if let parameters = parameters {
            
            var paramArray = Array<[String:AnyObject]>()
            for param in parameters {
                for (key, value) in param {
                    var pair = [String:AnyObject]()
                    pair["key"] = key as AnyObject
                    pair["value"] = value
                    paramArray.append(pair)
                }
            }
            
            whiskParameters["parameters"] = paramArray as AnyObject
        }
        
        group.enter()
        try networkManager.putCall(url: urlStr, path: path, parameters: whiskParameters, group: group)
        
    }
    
    
    func createRule(name: String, namespace: String, triggerName: String, actionName: String, group: DispatchGroup) throws {
        
        let urlStr: String = whiskBaseURL != nil ? whiskBaseURL! : DefaultBaseURL
        
        
        let path = "namespaces/\(namespace)/rules/\(name)"
        let whiskParameters = ["trigger": triggerName, "action": actionName]
        
        group.enter()
        try networkManager.putCall(url: urlStr, path: path, parameters: whiskParameters, group: group)
        
    }
    
    func enableRule(name: String, namespace: String, triggerName: String, actionName: String, group: DispatchGroup) throws {
        
        let urlStr: String = whiskBaseURL != nil ? whiskBaseURL! : DefaultBaseURL
        
        
        let path = "namespaces/\(namespace)/rules/\(name)"
        
        group.enter()
        
        try networkManager.postCall(url: urlStr, path: path, parameters: ["status":"active"], group: group) {
            response, error in
            if let error = error {
                print("Error enabling rule \(name), error \(error)")
            }
        }
        
    }
    
    func createSequence(qualifiedName: String, actions:[String], group: DispatchGroup) throws {
        let urlStr: String = whiskBaseURL != nil ? whiskBaseURL! : DefaultBaseURL
        
        let nameParts = try processQualifiedName(qName: qualifiedName)
        
        var path = ""
        if nameParts.package != nil {
            path = "namespaces/\(nameParts.namespace)/actions/\(nameParts.package!)/\(nameParts.name)"
        } else {
            path = "namespaces/\(nameParts.namespace)/actions/\(nameParts.name)"
        }
        
        let exec = ["kind":"nodejs", "code": SequenceCode.getSequenceCode()] as [String:String]
        let limits = ["timeout": 30000, "memory":256] as [String:AnyObject]
        
        var whiskParameters: [String:AnyObject] = ["exec":exec as AnyObject, "limits":limits as AnyObject]
        
        var paramArray = Array<[String:AnyObject]>()
        let actionList = ["key": "_actions", "value": actions as AnyObject]
        paramArray.append(actionList)
        whiskParameters["parameters"] = paramArray as AnyObject
        
        
        group.enter()
        try networkManager.putCall(url: urlStr, path: path, parameters: whiskParameters, group: group)
        
        
    }
    
    func deleteAction(qualifiedName: String, group: DispatchGroup) throws {
        let urlStr: String = whiskBaseURL != nil ? whiskBaseURL! : DefaultBaseURL
        
        let nameParts = try processQualifiedName(qName: qualifiedName)
        
        var path = ""
        if nameParts.package != nil {
            path = "namespaces/\(nameParts.namespace)/actions/\(nameParts.package!)/\(nameParts.name)"
        } else {
            path = "namespaces/\(nameParts.namespace)/actions/\(nameParts.name)"
        }
        
        group.enter()
        try networkManager.deleteCall(url: urlStr, path: path, group: group)
        
    }
    
    
    func deletePackage(name: String, namespace: String, group: DispatchGroup) throws {
        let urlStr: String = whiskBaseURL != nil ? whiskBaseURL! : DefaultBaseURL
        
        let path = "namespaces/\(namespace)/packages/\(name)"
        
        group.enter()
        try networkManager.deleteCall(url: urlStr, path: path, group: group)
        
    }
    
    func deleteTrigger(name: String, namespace: String, group: DispatchGroup) throws {
        let urlStr: String = whiskBaseURL != nil ? whiskBaseURL! : DefaultBaseURL
        
        let path = "namespaces/\(namespace)/triggers/\(name)"
        
        group.enter()
        try networkManager.deleteCall(url: urlStr, path: path, group: group)
        
    }
    
    func deleteRule(name: String, namespace: String, group: DispatchGroup) throws {
        let urlStr: String = whiskBaseURL != nil ? whiskBaseURL! : DefaultBaseURL
        
        let path = "namespaces/\(namespace)/rules/\(name)"
        
        group.enter()
        try networkManager.postCall(url: urlStr, path: path, parameters: ["status":"inactive"], group: group) { response, error in
            
            if let error = error {
                print("Error disabling rule \(name), error: \(error)")
            } else {
                print("Disable response for rule \(name): \(response)")
                
                DispatchQueue.main.after(when: DispatchTime.now() + 2.0) {
                    
                    do {
                        group.enter()
                        try self.networkManager.deleteCall(url: urlStr, path: path, group: group)
                    } catch {
                        print("Error deleting rule \(name), error: \(error)")
                    }
                    
                    
                }
            }
            
        }
        
    }
    
    
    
}

class WhiskNetworkManager {
    
    let whiskCredentials: WhiskCredentials!
    let urlSession: URLSession!
    
    init(credentials: WhiskCredentials, session: URLSession) {
        self.whiskCredentials = credentials
        self.urlSession = session
    }
    
    func putCall(url: String, path: String, parameters: [String:AnyObject]? = nil, group: DispatchGroup) throws {
        
        let overwritePath = path+"?overwrite=true"
        
        // encode path
        guard let encodedPath = overwritePath.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) else {
            throw WhiskNetworkError.MalformedUrlString(url: url, cause: "Cannot encode url path \(path)")
        }
        
        // create request
        guard let nsUrl = URL(string:url+encodedPath) else {
            throw WhiskNetworkError.MalformedUrlString(url: url, cause: "Cannot create URL from url String")
        }
        
        var request = URLRequest(url: nsUrl)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("Basic \(whiskCredentials.getBase64AuthString())", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        
        if let parameters = parameters {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters as AnyObject, options: JSONSerialization.WritingOptions())
        }
        
        let task = urlSession.dataTask(with: request) {
            data, response, error in
            
            let statusCode: Int!
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            } else {
                statusCode = -1
            }
            
            if let error = error {
                print("Error performing network call \(error), status: \(statusCode)")
                return
                
            } else {
                print("Success calling PUT \(url), status:\(statusCode)")
            }
            
            group.leave()
            
        }
        
        task.resume()
        
    }
    
    func deleteCall(url: String, path: String,group: DispatchGroup) throws {
        
        // encode path
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) else {
            throw WhiskNetworkError.MalformedUrlString(url: url, cause: "Cannot encode url path \(path)")
        }
        
        // create request
        guard let nsUrl = URL(string:url+encodedPath) else {
            throw WhiskNetworkError.MalformedUrlString(url: url, cause: "Cannot create URL from url String")
        }
        
        var request = URLRequest(url: nsUrl)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("Basic \(whiskCredentials.getBase64AuthString())", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        
        let task = urlSession.dataTask(with: request) {
            data, response, error in
            
            let statusCode: Int!
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            } else {
                statusCode = -1
            }
            
            if let error = error {
                print("Error performing network call \(error), status: \(statusCode)")
                return
                
            } else {
                print("Success calling DELETE \(url), status:\(statusCode)")
            }
            
            group.leave()
            
        }
        
        task.resume()
        
    }
    
    func postCall(url: String, path: String, parameters: [String:AnyObject]?, group: DispatchGroup, callback: (response: [String:Any]?, error: ErrorProtocol?) -> Void) throws {
        
        // encode path
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) else {
            throw WhiskNetworkError.MalformedUrlString(url: url, cause: "Cannot encode url path \(path)")
        }
        
        // create request
        guard let nsUrl = URL(string:url+encodedPath) else {
            throw WhiskNetworkError.MalformedUrlString(url: url, cause: "Cannot create URL from url String")
        }
        
        var request = URLRequest(url: nsUrl)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("Basic \(whiskCredentials.getBase64AuthString())", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        if let parameters = parameters {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters as AnyObject, options: JSONSerialization.WritingOptions())
        }
        
        let task = urlSession.dataTask(with: request) {
            data, response, error in
            
            let statusCode: Int!
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            } else {
                statusCode = -1
            }
            
            if let error = error {
                print("Error performing network call \(error), status: \(statusCode)")
                callback(response: nil, error: error)
                return
                
            } else {
                print("Success calling POST \(url), status:\(statusCode)")
                
                callback(response: ["status":statusCode, "description":"Post call success"], error: nil)
            }
            
            group.leave()
            
        }
        
        task.resume()
        
    }
}
