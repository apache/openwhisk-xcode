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

class WhiskInstaller {
    
    let consoleIO = ConsoleIO()
    
    func staticMode() {
        let argCount = Process.argc
        let argument = Process.arguments[1]
        
        var offset = 0
        if argument.hasPrefix("--") {
            offset = 2
        } else if argument.characters.first == "-" {
            offset = 1
        }
        
        let skipDashIndex = argument.index(argument.startIndex, offsetBy: offset)
        let (option, value) = consoleIO.getOption(option: argument.substring(from: skipDashIndex))
        
        switch option {
        case .Build:
            do {
                if let pm = try setupProjectManager() {
                    try pm.deployProject()
                } else {
                    print("Error initializing wsktool")
                }
            } catch {
                print("Error installing OpenWhisk project \(error)")
            }
        case .Delete:
            do {
                if let pm = try setupProjectManager() {
                    try pm.deleteProject()
                } else {
                    print("Error initializing wsktool")
                }
            } catch {
                print("Error installing OpenWhisk project \(error)")
            }
        case .Help:
            ConsoleIO.printUsage()
        case .Undefined:
            ConsoleIO.printUsage()
        }
    }
    
    func getCurrentDirectory() -> String {
        //return FileManager.default.currentDirectoryPath
        return "/Users/pcastro/Desktop/ow-projects"
    }
    
    func setupProjectManager() throws -> ProjectManager? {
        
        let path = NSHomeDirectory() + "/"+".wskprops"
        do {
            let content = try String(contentsOfFile: path)
            let lines = content.components(separatedBy: CharacterSet.newlines)
            
            var tokens: [String]? = nil
            var namespace: String? = nil
            
            for line in lines {
                let nameValue = line.components(separatedBy: "=")
                if nameValue[0] == "AUTH" {
                    tokens = nameValue[1].components(separatedBy: ":")
                } else if nameValue[0] == "NAMESPACE" {
                    namespace = nameValue[1]
                }
            }
            
            if let tokens = tokens, namespace = namespace {
                let credentials = WhiskCredentials(accessKey: tokens[0], accessToken: tokens[1])
                return ProjectManager(path: getCurrentDirectory(), credentials: credentials, namespace: namespace)
            }
        } catch {
            print("Error reading ~/.wskprops")
        }
        
        return nil
    }
}
