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

public enum WhiskNetworkError: Error {
    case malformedUrlString(url: String, cause: String)
    case qualifiedNameFormat(description: String)
}


/* Type of Whisk operation requested */
enum WhiskCallType {
    case action
    case trigger
    case package
    case rule
    case sequence
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
        
        let loginData: Data = loginString.data(using: String.Encoding.utf8.rawValue)!
        let base64LoginString = loginData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        
        return base64LoginString
    }
    
}


class WhiskAPI {
    
    // Default value for Whisk backend
    var DefaultBaseURL = "https://openwhisk.ng.bluemix.net/api/v1/"
    
    // supported Feeds
    let AlarmTriggerFeed = "/whisk.system/alarms/alarm"
    
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
                throw WhiskNetworkError.qualifiedNameFormat(description: "Cannot parse \(qName)")
            }
        } else {
            if pathParts.count == 1 {
                name = pathParts[0]
            } else if pathParts.count == 2 {
                package = pathParts[0]
                name = pathParts[1]
            } else {
                throw WhiskNetworkError.qualifiedNameFormat(description: "Cannot parse \(qName)")
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
    
    func createFeed(name: String, namespace: String, trigger: Trigger, group: DispatchGroup) throws {
        
        switch trigger.feed as! String  {
        case AlarmTriggerFeed:
            try createAlarmsFeed(name: name, namespace: namespace, trigger: trigger, group: group)
        default:
            throw WhiskProjectError.unsupportedFeedType(cause: "Feed trigger \(trigger.feed) not supported")
        }
    }
    
    func createAlarmsFeed(name: String, namespace: String, trigger: Trigger, group: DispatchGroup) throws {
        let urlStr: String = whiskBaseURL != nil ? whiskBaseURL! : DefaultBaseURL
        let path = "namespaces/\(namespace)/triggers/\(name)"
        
        let annotations: [String:AnyObject] = ["value": trigger.feed!, "key": "feed" as AnyObject]
        let parameters: [String: [[String:AnyObject]]] = ["annotations": [annotations]]
        
        group.enter()
        try networkManager.putCall(url: urlStr, path: path, parameters: parameters as [String : AnyObject]?, group: group) { response, error in
            
            if let error = error {
                print("Error creating trigger \(name) for feed \(trigger.feed), error: \(error)")
            } else {
                group.enter()
                //DispatchQueue.main.after(when: DispatchTime.now() + 0.5) {
                
                let feedPath = "namespaces/whisk.system/actions/alarms/alarm"
                do {
                    
                    var params: [String:AnyObject]? = nil
                    
                    if let feedParams = trigger.parameters {
                        params = [String:AnyObject]()
                        for obj in feedParams {
                            let dict = obj as [String:AnyObject]
                            for (name, value) in dict {
                                if name.lowercased() == "cron" {
                                    params?["cron"] = value
                                } else if name == "trigger_payload" {
                                    params?["trigger_payload"] = value
                                }
                            }
                        }
                        
                        params?["authKey"] = "\(self.networkManager.whiskCredentials.accessKey):\(self.networkManager.whiskCredentials.accessToken)" as AnyObject
                        params?["lifecycleEvent"] = "CREATE" as AnyObject
                        params?["triggerName"] = ("/"+namespace+"/"+name) as AnyObject
                    }
                    
                    
                    try self.networkManager.postCall(url: urlStr, path: feedPath, parameters: params, group: group) {
                        response, error in
                        
                        if let error = error {
                            print("Error creating feed for trigger \(name), error: \(error)")
                        }
                        
                    }
                } catch {
                    print("Error creating feed for trigger \(name), error: \(error)")
                }
                
                
                // }
            }
            
        }
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
        let limits = ["timeout": 30000 as AnyObject, "memory":256 as AnyObject] as [String:AnyObject]
        
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
        try networkManager.putCall(url: urlStr, path: path, parameters: whiskParameters as [String : AnyObject]?, group: group)
        
    }
    
    func enableRule(name: String, namespace: String, triggerName: String, actionName: String, group: DispatchGroup) throws {
        
        let urlStr: String = whiskBaseURL != nil ? whiskBaseURL! : DefaultBaseURL
        
        
        let path = "namespaces/\(namespace)/rules/\(name)"
        
        group.enter()
        
        try networkManager.postCall(url: urlStr, path: path, parameters: ["status":"active" as AnyObject], group: group) {
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
        let limits = ["timeout": 30000 as AnyObject, "memory":256 as AnyObject] as [String:AnyObject]
        
        var whiskParameters: [String:AnyObject] = ["exec":exec as AnyObject, "limits":limits as AnyObject]
        
        var paramArray = Array<[String:AnyObject]>()
        let actionList = ["key": "_actions", "value": actions as AnyObject] as [String : Any]
        paramArray.append(actionList as [String : AnyObject])
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
        try networkManager.deleteCall(url: urlStr, path: path, group: group) { response, error in
            
            if let error = error {
                print("Error deleting trigger \(name), \(error)")
            } else if let response = response {
                
                if let annotations = response["annotations"] as? [[String:AnyObject]] {
                    for note in annotations {
                        
                        var isFeed = false
                        var feed = ""
                        for (att, value) in note {
                            if att == "key" {
                                if value as! String == "feed" {
                                    isFeed = true
                                }
                            } else if att == "value" {
                                feed = value as! String
                            }
                        }
                        
                        if isFeed == true {
                            // delete the alarm
                            if feed == self.AlarmTriggerFeed {
                                do {
                                    try self.deleteAlarmsFeed(namespace: namespace, name: name, group: group)
                                } catch {
                                    print("Error deleting trigger feed \(name): \(error)")
                                }
                            }
                        }
                        
                    }
                }
                
            }
            
        }
        
    }
    
    func deleteAlarmsFeed(namespace: String, name: String, group: DispatchGroup) throws {
        var params = [String:AnyObject]()
        
        params["authKey"] = (self.networkManager.whiskCredentials.accessKey+":"+self.networkManager.whiskCredentials.accessToken) as AnyObject
        params["lifecycleEvent"] = "DELETE" as AnyObject
        params["triggerName"] = (namespace+"/"+name) as AnyObject
        
        let urlStr: String = whiskBaseURL != nil ? whiskBaseURL! : DefaultBaseURL
        let path = "namespaces/whisk.system/actions/alarms/alarm"
        
        group.enter()
        try networkManager.postCall(url: urlStr, path: path, parameters: params, group: group) { response, error in
            
            if let error = error {
                print("Error deleting alarm feed \(error)")
            } else {
                print("Succes deleting alarm feed \(response)")
            }
            
        }
        
    }
    
    func deleteRule(name: String, namespace: String, group: DispatchGroup) throws {
        let urlStr: String = whiskBaseURL != nil ? whiskBaseURL! : DefaultBaseURL
        
        let path = "namespaces/\(namespace)/rules/\(name)"
        
        group.enter()
        try networkManager.postCall(url: urlStr, path: path, parameters: ["status":"inactive" as AnyObject], group: group) { response, error in
            
            if let error = error {
                print("Error disabling rule \(name), error: \(error)")
            } else {
                
                group.enter()
                //DispatchQueue.main.after(when: DispatchTime.now() + 0.5) {
                
                do {
                    try self.networkManager.deleteCall(url: urlStr, path: path, group: group)
                } catch {
                    print("Error deleting rule \(name), error: \(error)")
                }
                
                
                // }
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
    
    func putCall(url: String, path: String, parameters: [String:AnyObject]? = nil, group: DispatchGroup, callback: (([String:Any]?, Error?) -> Void)? = nil) throws  {
        
        let overwritePath = path+"?overwrite=true"
        
        // encode path
        guard let encodedPath = overwritePath.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) else {
            throw WhiskNetworkError.malformedUrlString(url: url, cause: "Cannot encode url path \(path)")
        }
        
        // create request
        guard let nsUrl = URL(string:url+encodedPath) else {
            throw WhiskNetworkError.malformedUrlString(url: url, cause: "Cannot create URL from url String")
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
                if let callback = callback {
                    callback(nil, error)
                } else {
                    return
                }
                
            } else {
                if let callback = callback {
                    callback(["status":statusCode, "msg":"PUT call success"], nil)
                }
            }
            
            group.leave()
            
        }
        
        task.resume()
        
    }
    
    func deleteCall(url: String, path: String,group: DispatchGroup, callback: (([String:AnyObject]?, Error?) -> Void)? = nil) throws {
        
        // encode path
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) else {
            throw WhiskNetworkError.malformedUrlString(url: url, cause: "Cannot encode url path \(path)")
        }
        
        // create request
        guard let nsUrl = URL(string:url+encodedPath) else {
            throw WhiskNetworkError.malformedUrlString(url: url, cause: "Cannot create URL from url String")
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
            }
            
            
            
            if let callback = callback {
                if let data = data {
                    do {
                        if let resp = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as? [String:AnyObject] {
                            callback(resp, nil)
                        }
                    } catch {
                        print("Error in DELETE \(error)")
                    }
                } else {
                    callback(["status":statusCode as AnyObject], nil)
                }
                
            }
            
            group.leave()
            
        }
        
        task.resume()
        
    }
    
    func postCall(url: String, path: String, parameters: [String:AnyObject]?, group: DispatchGroup?, callback: @escaping ([String:Any]?, Error?) -> Void) throws {
        
        // encode path
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) else {
            throw WhiskNetworkError.malformedUrlString(url: url, cause: "Cannot encode url path \(path)")
        }
        
        // create request
        guard let nsUrl = URL(string:url+encodedPath) else {
            throw WhiskNetworkError.malformedUrlString(url: url, cause: "Cannot create URL from url String")
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
                callback(nil, error)
                return
                
            } else {
                
                callback(["status":statusCode, "description":"Post call success"], nil)
            }
            
            if let group = group {
                group.leave()
            }
            
        }
        
        task.resume()
        
    }
}
