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
    var projectPath: String!
    var argumentTarget: String?
    
    init() {
        projectPath = getCurrentDirectory()
    }
    
    func staticMode() {
        let argCount = Int(CommandLine.argc)
        let argument = CommandLine.arguments[1]
        
        var i = 1
        var isBuild = true

        
        while (i < argCount) {
            let arg = CommandLine.arguments[i]
            
            var offset = 0
            if arg.hasPrefix("--") {
                offset = 2
            } else if arg.characters.first == "-" {
                offset = 1
            }
            
            let skipDashIndex = arg.index(argument.startIndex, offsetBy: offset)
            let (option, _) = consoleIO.getOption(arg.substring(from: skipDashIndex))
            
            switch option {
            case .Build:
                isBuild = true
                i = i + 1
                print("Got build")
            case .Delete:
                isBuild = false
                i = i + 1
                print("Got delete")
            case .Path:
                projectPath = CommandLine.arguments[i+1]
                i = i + 2
                print("Got path \(projectPath)")
            case .Target:
                argumentTarget = CommandLine.arguments[i+1]
                i = i + 2
                print("Got target \(argumentTarget)")
            case .Version:
                ConsoleIO.printVersion()
                i = i + 1
            case .Help:
                ConsoleIO.printUsage()
                i = i + 1
            case .Undefined:
                ConsoleIO.printUsage()
                i = i + 1

            }
        }
        
        if isBuild == true {
            
            do {
                if let pm = try setupProjectManager() {
                    try pm.deployProject(target: argumentTarget)
                } else {
                    print("Error initializing wsktool")
                }
            } catch {
                print("Error installing OpenWhisk project \(error)")
            }
        } else {
            do {
                if let pm = try setupProjectManager() {
                    try pm.deleteProject(target: argumentTarget)
                } else {
                    print("Error initializing wsktool")
                }
            } catch {
                print("Error installing OpenWhisk project \(error)")
            }
        }
        
    }
    
    func getCurrentDirectory() -> String {
        return FileManager.default.currentDirectoryPath
        //return "/Users/pcastro/Desktop/ow-projects"
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
            
            if let tokens = tokens, let namespace = namespace {
                let credentials = WhiskCredentials(accessKey: tokens[0], accessToken: tokens[1])
                return ProjectManager(path: projectPath!, credentials: credentials, namespace: namespace)
            }
        } catch {
            print("Error reading ~/.wskprops")
        }
        
        return nil
    }
}
