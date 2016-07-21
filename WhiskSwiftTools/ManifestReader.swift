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

class ManifestReader {
    
    class func readManifest(atPath: NSString) throws -> [String: AnyObject] {
         
        return try ManifestReader.parseJson(atPath: atPath)
        
    }
    
    class func parseJson(atPath: NSString) throws -> [String:AnyObject]  {
        do {
            
            let jsonStr = try NSString(contentsOfFile: atPath as String, encoding: String.Encoding.utf8.rawValue)
            if let jsonData = jsonStr.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: true) {
                if let result = try JSONSerialization.jsonObject(with: jsonData, options: [])  as? [String:AnyObject] {
                    
                    if let openwhisk = result["openwhisk"] as? [String:AnyObject] {
                        return openwhisk
                    } else {
                        throw WhiskProjectError.MalformedManifestFile(name: atPath as String, cause: "root of manifest file should be a JSON object called 'openwhisk'")
                    }
                } else {
                    throw WhiskProjectError.MalformedManifestFile(name: atPath as String, cause: "JSON file does not appear to be an object.  Is in an array?")
                }
            }
        } catch {
            throw WhiskProjectError.MalformedManifestFile(name: atPath as String, cause: "Error parsing JSON file contents \(error)")
        }
        
        return [String:AnyObject]()
    }
    
}
