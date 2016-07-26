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

class Git {
    
    static let TempZipFile = "/tmp/openwhiskproject.zip"
    
    class func cloneGitRepo(repo: String, toPath: String, group: DispatchGroup) throws {
        guard let nsUrl = NSURL(string:repo) else {
            throw WhiskNetworkError.MalformedUrlString(url: repo, cause: "Cannot create URL from url String")
        }
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: nsUrl as URL)
        request.httpMethod = "GET"
        
        group.enter()
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: NSError?) -> Void in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("Repo \(repo) successfully cloned with status code: \(statusCode)")
                
                // This is your file-variable:
                // data
                if let data = data {
                    let zipPath = TempZipFile
                    let zipUrl = URL(fileURLWithPath: TempZipFile)
                    do {
                        try data.write(to: zipUrl)
                        // unzip this
                        SSZipArchive.unzipFile(atPath: zipPath, toDestination: toPath)
                        
                        let fileManager = FileManager.default
                        
                        
                        try fileManager.removeItem(atPath: zipPath)
                    } catch {
                        print("Error extracting zip file at \(zipPath)")
                    }
                    
                } else {
                    print("Failure when cloning repo \(repo). Response has no data.")
                }
            } else {
                // Failure
                print("Failure cloning \(repo): %@", error?.localizedDescription);
            }
            
            group.leave()
        })
        task.resume()
    }
}
