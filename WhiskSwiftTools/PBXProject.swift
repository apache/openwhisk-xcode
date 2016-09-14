//
//  PBXProject.swift
//  WhiskSwiftTools
//
//  Created by Paul Castro on 9/2/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

enum PBXParseState {
    case inital
    case inTarget
    case inNamedTarget
    case inSources
    case inResources
    case inFiles
    case parseFileNames
    case done
}

class PBXProject {
    
    let fullPath: String!
    let targetName: String!
    var filesForTarget = [String:[String]]()
    
    init(file: String, targetName: String) {
        self.fullPath = file+"/project.pbxproj"
        self.targetName = targetName
        parseFile()
    }
    
    func parseFile() {
        filesForTarget.removeAll()
        
        do {
            let fileStr = try String(contentsOfFile: fullPath)
            let scanner = Scanner(string: fileStr)
            var line: NSString?
            var targetKey: String?
            
            var parseState = PBXParseState.inital
            while scanner.scanUpToCharacters(from: CharacterSet.newlines, into: &line) {
                
                guard let line = line else {
                    print("PBXParse: Error, line from parseFile is nil, aborting.")
                    return
                }
                var trimmedLine = line.trimmingCharacters(in: CharacterSet.whitespaces)
                
                switch parseState {
                case .inital:
                    if trimmedLine.range(of: "/* Begin PBXNativeTarget section */") != nil {
                        parseState = .inTarget
                        
                    }
                case .inTarget:
                    if trimmedLine.range(of: "PBXNativeTarget \"\(targetName!)\" */;") != nil {
                        parseState = .inNamedTarget
                    }
                case .inNamedTarget:
                    if trimmedLine.range(of: "/* Sources */") != nil {
                        parseState = .inSources
                        let components = trimmedLine.components(separatedBy: CharacterSet.whitespaces)
                        targetKey = components[0]
                    } else if trimmedLine.range(of: "/* Resources */") != nil {
                        parseState = .inResources
                        let components = trimmedLine.components(separatedBy: CharacterSet.whitespaces)
                        targetKey = components[0]
                    }

                case .inSources:
                    let token = "\(targetKey!) /* Sources */"
                    if trimmedLine.range(of: token ) != nil {
                        parseState = .inFiles
                    }
                case .inResources:
                    let token = "\(targetKey!) /* Resources */"
                    if trimmedLine.range(of: token ) != nil {
                        parseState = .inFiles
                    }
                case .inFiles:
                    if trimmedLine.range(of: "files = (") != nil {
                        parseState = .parseFileNames
                    }
                case .parseFileNames:
                    if (trimmedLine.range(of: "in Sources */") != nil) || (trimmedLine.range(of: "in Resources */") != nil) {
                        let components = trimmedLine.components(separatedBy: CharacterSet.whitespaces)
                        let fileName = components[2]                        
                        if var files = filesForTarget[targetName] {
                            files.append(fileName)
                            filesForTarget[targetName] = files
                        } else {
                            var files = [String]()
                            files.append(fileName)
                            filesForTarget[targetName] = files
                        }
                    } else if (trimmedLine.range(of: ");") != nil) {
                        parseState = .done
                    }
                case .done:
                    return
                }
            }
            
        } catch {
            print("Error parsing file \(error)")
        }
    }
    
}
