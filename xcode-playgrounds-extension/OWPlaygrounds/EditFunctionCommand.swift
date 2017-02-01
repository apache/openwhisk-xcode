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
//
//  EditFunctionCommand.swift
//  ExtensionTest
//
//  Created by whisk on 1/13/17.
//  Copyright © 2017 whisk. All rights reserved.
//

import Foundation
import XcodeKit
import AppKit

class EditFunctionCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        let selections = invocation.buffer.selections
        
        for item in selections {
            if let rangeElement = item as? XCSourceTextRange{
                let lineStart = rangeElement.start.line
                let lineEnd = rangeElement.end.line
                var curlyCount = 0
                var curlyCountActive = false
                
                var startFunc = -1
                var endFunc = -1
                
                // Checking for function header
                for lineNum in lineStart...lineEnd{
                    let line = invocation.buffer.lines[lineNum] as! String
                    if line.contains("func"){
                        curlyCountActive = true
                        startFunc = lineNum
                        break
                    }
                }
                
                if startFunc == -1{
                    displayAlert(message: "No function signature detected.  Please select a function header.")
                    completionHandler(nil)
                    return
                }
                
                //Looking for end of function
                var lineNum = startFunc
                while lineNum < invocation.buffer.lines.count {
                    let line = invocation.buffer.lines[lineNum] as! String
                    if line.contains("{"){
                        curlyCount += 1
                    }
                    if line.contains("}"){
                        curlyCount -= 1
                    }
                    if curlyCount == 0 {
                        endFunc = lineNum
                        break
                    }
                    lineNum += 1
                }
                
                if endFunc == -1{
                    displayAlert(message: "Error finding function")
                    completionHandler(nil)
                    return
                }
                var fullFunc = ""
                
                let paramValues = checkUpdateParameters(startLine: startFunc, endLine: endFunc, lines: invocation.buffer.lines)
                if paramValues.count > 0{
                    // get the param values
                    do{
                        print("Params - \(paramValues["params"])")
                        let jsonParamData =  try JSONSerialization.data(withJSONObject: paramValues["params"]!, options: .prettyPrinted)
                        let jsonParamString = NSString(data: jsonParamData, encoding: String.Encoding.ascii.rawValue) as! String
                        fullFunc += jsonParamString
                        
                        let jsonOutputData =  try JSONSerialization.data(withJSONObject: paramValues["expectedOut"], options: .prettyPrinted)
                        let jsonOutputString = NSString(data: jsonOutputData, encoding: String.Encoding.ascii.rawValue) as! String
                        fullFunc += jsonOutputString
                        
                        //Check if OWPlayground is open already
                        let owPlaygroundFound = self.checkForOWPlayground()
                        //Open OWPlayground Background version if it is not open
                        if owPlaygroundFound == false{
                            self.openOWPlayground()
                        }
                        
                        // Get path to files to monitor
                        //Comes from Info.plist
                        let dictionary = Bundle.main.infoDictionary
                        let playgroundPath = dictionary!["PLAYGROUND_PATH"] as! String
                        print("Playground Path - \(playgroundPath)")
                        print("Expected Output - \(jsonOutputString)")
                        
                        //open URL for OWPlayground
                        let urlString : String = "http://localhost:6018/?name=\(playgroundPath)&paramaters=\(jsonParamString)&results=\(jsonOutputString)".replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\n", with: "")
                        let urlStringEncoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                        let url = URL(string: urlStringEncoded!)
                        
                        
                        //Delays the opening of the url if the owPlayground isnt found
                        
                        let invokeGroup = DispatchGroup()
                        invokeGroup.enter()
                        //Fancy queues and functions to make the url open after the app is opened/server is running
                        let queue = DispatchQueue(label: "OpenURLQueue", qos: DispatchQoS.userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
                        queue.async{
                            while true {
                                var found = false
                                DispatchQueue.main.sync {
                                    let OWFound = self.checkForOWPlayground()
                                    if OWFound {
                                        found = true
                                        let timeAfterOpen = 1.0
                                        DispatchQueue.main.asyncAfter(
                                            deadline: DispatchTime.now() + Double(Int64(timeAfterOpen * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                                                print("opening url")
                                                NSWorkspace.shared().open(url!)
                                                invokeGroup.leave()
                                        })
                                    }
                                }
                                if found {
                                    break
                                }
                            }
                        }
                        
                        switch invokeGroup.wait(timeout: DispatchTime.now() + 10) {
                        case DispatchTimeoutResult.success:
                            break
                        case DispatchTimeoutResult.timedOut:
                            print("Unable to open url as server has not launched")
                            break
                        }
                    }catch{
                        print("Didn't work")
                    }
                }else{
                    // wait for user to fill out param values
                }
                print(fullFunc)
                //displayAlert(message: fullFunc)
            }
        }
        completionHandler(nil)
    }
    
    
    
    /// Checks for parameters above the function and adds parameters with initial values if none are found
    ///
    /// - Parameters:
    ///   - startLine: the beginning of the function : 21123r1231
    ///   - endLine: the end of the function
    ///   - lines: the lines of the file
    /// - Returns: return true if documentation was created, false if documentation existed already
    func checkUpdateParameters(startLine: Int, endLine: Int, lines: NSMutableArray)-> [String: Any]{
        
        // - Look for args that are used
        var argsFound = [String]()
        for lineNum in startLine...endLine{
            if let line = lines[lineNum] as? String {
                if let startRange = line.range(of:"args[\""),
                    let substringFrom = line.substring(from: startRange.upperBound) as? String,
                    let endRange = substringFrom.range(of: "\"]"),
                    let finalParamater = substringFrom.substring(to:endRange.lowerBound) as? String {
                    if !argsFound.contains(finalParamater){
                        argsFound.append(finalParamater)
                    }
                }
            }
        }
        
        if argsFound.count > 0 {
            argsFound.sort()
            // Determine if placeholders were already created
            var lineNum = startLine - 1
            var startDocumentation = -1
            var createDocumentation = true
            while lineNum > 0{
                if let line = lines[lineNum] as? String{
                    if !line.contains("///"){
                        startDocumentation = lineNum + 1
                        break
                    }
                    lineNum -= 1
                }
            }
            
            if startDocumentation == -1 {
                startDocumentation = 0
            }
            var paramsFound = 0
            var paramFoundLines = [String]()
            for lineNum in startDocumentation..<startLine {
                if let line = lines[lineNum] as? String{
                    argsFound.forEach{
                        if line.contains("- \($0):"){
                            paramsFound += 1
                            paramFoundLines.append(line)
                        }
                    }
                }
            }
            if paramsFound == argsFound.count{
                createDocumentation = false
                var paramValues = [String:Any]()
                var paramsDict = [String:String]()
                paramValues["params"] = paramsDict
                for paramLine in paramFoundLines{
                    
                    let components = paramLine.components(separatedBy: ":")
                    if components.count == 3{
                        //Strip Param documentation lines for values
                        var testValue = components[2]
                        ["\n", " ", "#>", "<#", "\""].forEach{
                            testValue = testValue.replacingOccurrences(of: $0, with: "")
                        }
                        var paramName = components[0]
                        ["/", " ", "-"].forEach{
                            paramName = paramName.replacingOccurrences(of: $0, with: "")
                        }
                        paramsDict[paramName] = testValue
                        
                    }else{
                        createDocumentation = true
                        break
                    }
                }
                paramValues["params"] = paramsDict
                if createDocumentation == false{
                    // Look for expected output
                    for lineNum in startDocumentation ..< startLine {
                        if let line = lines[lineNum] as? String{
                            if line.contains("Expected Output --"){
                                var expectedOutString = line.components(separatedBy: "--").last!
                                ["\n", " ", "#>", "<#"].forEach({
                                    expectedOutString = expectedOutString.replacingOccurrences(of: $0, with: "")
                                })
                                do{
                                    let expectedOutJSON = try JSONSerialization.jsonObject(with: expectedOutString.data(using: String.Encoding.utf8)!, options: .mutableContainers)
                                    paramValues["expectedOut"] = expectedOutJSON as! [String : Any]
                                }catch{
                                    print("Expected output could not be parsed")
                                    paramValues["expectedOut"] = [:]
                                }
                            }
                        }
                    }
                    return paramValues
                }
            }
            
            // Create documentation placeholders if placeholders not found
            if createDocumentation{
                var indentation = ""
                let funcLine = lines[startLine] as! String
                let funcLineComponents = funcLine.components(separatedBy: "func")
                if funcLineComponents.count > 1 {
                    indentation = funcLineComponents[0]
                }
                
                var textToAdd = ""
                textToAdd += "\(indentation)/// <#Description#> \n"
                textToAdd += "\(indentation)/// \n"
                if argsFound.count > 0{
                    textToAdd += "\(indentation)/// - Parameters: \n"
                    argsFound.forEach { textToAdd += "\(indentation)///   - \($0): <# description #> : <# test value #> \n" }
                }
                textToAdd += "\(indentation)/// - Returns: <# return value description #> \n"
                textToAdd += "\(indentation)/// - Expected Output -- <#Put expected JSON here (optional)#> \n"
                lines.insert(textToAdd, at: startLine)
                return [:]
            }
            return [:]
        }else{
            return [:]
        }
    }
    
    func checkForOWPlayground()->Bool{
        let runningApps = NSWorkspace.shared().runningApplications
        var OWPlaygroundFound = false
        for app in runningApps{
            if app.bundleIdentifier == "com.electron.openwhisk-playground-osx"{
                OWPlaygroundFound = true
            }
        }
        return OWPlaygroundFound
    }
    
    func openOWPlayground(){
        
        let args = [ "-a",  "openwhisk-playground-osx", "--args", "asdfasdfddd"]
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = args
        
        task.launch()
    }
    
    /// Displays a pop up alert for debugging
    ///
    /// - Parameter message: message description
    func displayAlert(message: String){
        DispatchQueue.main.sync {
            let alert = NSAlert()
            alert.messageText = message
            alert.window.level = 999
            
            NSApp.beginModalSession(for: alert.window)
            NSApp.activate(ignoringOtherApps: true)
            alert.window.makeKeyAndOrderFront(nil)
            alert.runModal()
            
        }
    }
}
