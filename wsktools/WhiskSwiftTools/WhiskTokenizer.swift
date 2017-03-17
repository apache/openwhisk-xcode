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

public struct ActionToken {
    var actionName: String
    var actionCode: String
}

public struct TriggerToken {
    var triggerName: String
}

public struct RuleToken {
    var ruleName: String
    var triggerName: String
    var actionName: String
}

public struct SequenceToken {
    var sequenceName: String
    var actionNames: [String]
}

enum TokenState {
    case inStarComment
    case inSlashComment
    case initial
    case inClass
    case inClassName
    case inClassQualifier
    case skippingBlock
    case parseAction
}

open class WhiskTokenizer {
    
    
    var atPath: String!
    var toPath: String!
    var projectFileName: NSString!
    var targetName: String!
    
    public init(from: String, to: String, projectFile: NSString, target: String? ) {
        atPath = from
        toPath = to
        if target != nil {
            targetName = target!
        } else {
            targetName = "OpenWhiskActions"
        }
        self.projectFileName = projectFile
    }
    
    func readTargetSourceFiles() -> [String]? {
        let pbxProject = PBXProject(file: projectFileName as String, targetName: targetName)
        
        var filesForTarget = pbxProject.filesForTarget
        for (target, files) in filesForTarget {
            print("target:\(target), files:\(files)")
        }
        
        return filesForTarget[targetName]
    }
    
    open func readXCodeProjectDirectory() throws -> (actions: [Action],triggers: [Trigger], rules: [Rule], sequences: [Sequence]) {
        let dir: FileManager = FileManager.default
        
        var whiskActionArray = [Action]()
        var whiskTriggerArray = [Trigger]()
        var whiskRuleArray = [Rule]()
        var whiskSequenceArray = [Sequence]()
        
        if let fileList = readTargetSourceFiles() {
            
            print("There are \(fileList.count) files for target \(targetName)")
            
            if let enumerator: FileManager.DirectoryEnumerator = dir.enumerator(atPath: atPath) {
                
                while let item = enumerator.nextObject() as? NSString {
                    
                    var isDir = ObjCBool(false)
                    let fullPath = atPath+"/\(item)"
                    
                    //print("===== inspecting \(item.lastPathComponent)")
                    if dir.fileExists(atPath: fullPath, isDirectory: &isDir) == true {
                        if isDir.boolValue == true {
                            
                        }  else if item.hasSuffix(".swift") {
                            
                            if fileList.contains(item.lastPathComponent as String) {
                                print("****Processing \(item.lastPathComponent)")
                                do {
                                    let fileStr = try String(contentsOfFile: fullPath)
                                    if let entityTuple = getWhiskEntities(str: fileStr) {
                                        
                                        for action in entityTuple.actions {
                                            do {
                                                
                                                let actionDirPath = toPath+"/\(targetName!)"
                                                
                                                try FileManager.default.createDirectory(atPath: actionDirPath, withIntermediateDirectories: true, attributes: nil)
                                                
                                                let actionPath = actionDirPath+"/\(action.actionName).swift"
                                                
                                                let fileUrl = URL(fileURLWithPath: actionPath)
                                                try action.actionCode.write(to: fileUrl, atomically: false, encoding: String.Encoding.utf8)
                                                
                                                let whiskAction = Action(name: action.actionName as NSString, path: actionPath as NSString, runtime: Runtime.swift3, parameters: nil)
                                                
                                                whiskActionArray.append(whiskAction)
                                                
                                            } catch {
                                                print("Error writing actions from Xcode \(error)")
                                            }
                                        }
                                        
                                        for trigger in entityTuple.triggers {
                                            let whiskTrigger = Trigger(name: trigger.triggerName as NSString, feed: nil, parameters: nil)
                                            whiskTriggerArray.append(whiskTrigger)
                                        }
                                        
                                        for rule in entityTuple.rules {
                                            let rule = Rule(name: rule.ruleName as NSString, trigger: rule.triggerName as NSString, action: rule.actionName as NSString)
                                            whiskRuleArray.append(rule)
                                        }
                                        
                                        for sequence in entityTuple.sequences {
                                            let seq = Sequence(name: sequence.sequenceName as NSString, actions: sequence.actionNames)
                                            whiskSequenceArray.append(seq)
                                        }
                                        
                                    }
                                    
                                } catch {
                                    print("Error \(error)")
                                }
                            }
                        }
                    }
                    
                }
            }
            
        } else {
            print("No files for given target \(targetName!)")
        }

        
        
        return (whiskActionArray, whiskTriggerArray, whiskRuleArray, whiskSequenceArray)
    }
    
    func getWhiskEntities(str: String) -> (actions: [ActionToken], triggers: [TriggerToken], rules: [RuleToken], sequences: [SequenceToken])? {
        
        let scanner = Scanner(string: str)
        
        var line: NSString?
        var state = TokenState.initial
        var actionArray = [ActionToken]()
        var triggerArray = [TriggerToken]()
        var ruleArray = [RuleToken]()
        var sequenceArray = [SequenceToken]()
        
        var actionName = ""
        var actionCode = ""
        var leftBracketCount = 0
        var rightBracketCount = 0
        
        
        while scanner.scanUpToCharacters(from: CharacterSet.newlines, into: &line) {
            
            // print("Scan location is \(scanner.scanLocation)")
            
            guard let line = line else {
                print("Xcode To Whisk: Error, line from tokenizer is nil, aborting.")
                return nil
            }
            
            var trimmedLine = line.trimmingCharacters(in: CharacterSet.whitespaces)
            
            if trimmedLine.hasPrefix("//") {
                //print("Skipping comment")
            } else if trimmedLine.hasPrefix("/*") {
                state = TokenState.inStarComment
            } else {
                
                switch state {
                case .initial:
                    if trimmedLine.range(of: "let") != nil && trimmedLine.range(of: "WhiskTrigger()") != nil {
                        
                        let classStr = trimmedLine.components(separatedBy: "=")
                        // get actionName
                        let letStr = classStr[0].components(separatedBy: .whitespaces)
                        let triggerName = letStr[1]
                        let triggerToken = TriggerToken(triggerName: triggerName)
                        triggerArray.append(triggerToken)
                        
                    } else if trimmedLine.range(of: "let") != nil && trimmedLine.range(of: "WhiskRule(") != nil && trimmedLine.range(of: "trigger:") != nil && trimmedLine.range(of: "action:") != nil{
                        var classStr = trimmedLine.components(separatedBy: "=")
                        let letStr = classStr[0].components(separatedBy: .whitespaces)
                        let ruleName = letStr[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        let paramStr = classStr[1].replacingOccurrences(of: "WhiskRule", with: "").components(separatedBy: ",")
                        let triggerStr = paramStr[0].components(separatedBy: ":")
                        let triggerName = triggerStr[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        var actionStr = paramStr[1].components(separatedBy: ":")
                        let actionName = actionStr[1].replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").trimmingCharacters(in: .whitespaces)
                        
                        
                        
                        print("Got trigger:\(triggerName), action:\(actionName)")
                        
                        let rule = RuleToken(ruleName: ruleName, triggerName: triggerName, actionName: actionName)
                        ruleArray.append(rule)
                        
                    } else if trimmedLine.range(of: "let") != nil && trimmedLine.range(of: "WhiskSequence(") != nil {
                        var classStr = trimmedLine.components(separatedBy: "=")
                        let letStr = classStr[0].components(separatedBy: .whitespaces)
                        let sequenceName = letStr[1]
                        
                        let paramStr = classStr[1].replacingOccurrences(of: "WhiskSequence", with: "").components(separatedBy: ":")
                        
                        let actionNames = paramStr[1].replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: " ", with: "")
                        
                        print("Got sequence \(actionNames)")
                        let names = actionNames.components(separatedBy: ",")
                        var sequenceActions = [String]()
                        for name in names {
                            sequenceActions.append(name)
                        }
                        let sequence = SequenceToken(sequenceName: sequenceName, actionNames: sequenceActions)
                        sequenceArray.append(sequence)
                        
                    } else if trimmedLine.range(of: "OpenWhiskAction") == nil && trimmedLine.range(of: "class") != nil && trimmedLine.range(of: ":") != nil && trimmedLine.range(of: "WhiskAction") != nil {
                        
                        let classStr = trimmedLine.components(separatedBy: ":")
                        
                        // get actionName
                        let classIndex = classStr[0].characters.index(classStr[0].startIndex, offsetBy: 6)
                        
                        actionName = classStr[0].substring(from: classIndex).trimmingCharacters(in: CharacterSet.whitespaces)
                        
                        state = TokenState.parseAction
                        var tok = trimmedLine.components(separatedBy: "{")
                        leftBracketCount = tok.count - 1
                        tok = trimmedLine.components(separatedBy: "}")
                        rightBracketCount = tok.count - 1
                        
                    }
                case .parseAction:
                    
                    var lookingForLeftBracket = false
                    if leftBracketCount == 0 {
                        lookingForLeftBracket = true
                    }
                    var tok = trimmedLine.components(separatedBy: "{")
                    leftBracketCount = leftBracketCount + (tok.count - 1)
                    tok = trimmedLine.components(separatedBy: "}")
                    rightBracketCount = rightBracketCount + (tok.count - 1)
                    
                    if leftBracketCount == rightBracketCount {
                        
                        // drop extra bracket
                        let lastLine = String(trimmedLine.characters.dropLast())
                        
                        if lookingForLeftBracket == false {
                            actionCode = actionCode + "\n" + lastLine
                        }
                        
                        let newAction = ActionToken(actionName: actionName, actionCode: actionCode)
                        
                        actionArray.append(newAction)
                        state = TokenState.initial
                        actionName = ""
                        actionCode = ""
                        
                        leftBracketCount = 0
                        rightBracketCount = 0
                        
                        state = TokenState.initial
                        
                    } else {
                        
                        let range = trimmedLine.range(of: "func run(")
                        if range != nil {
                            trimmedLine.replaceSubrange(range!, with: "func main(")
                        }
                        
                        if lookingForLeftBracket == false {
                            actionCode = actionCode + "\n"+trimmedLine
                        }
                    }
                    
                case .inStarComment:
                    if trimmedLine.hasSuffix("*/") {
                        state = TokenState.initial
                    }
                default:
                    //print("Don't care")
                    break
                }
            }
            
        }
        
        if state == .parseAction {
            let code = String(actionCode.characters.dropLast())
            let newAction = ActionToken(actionName: actionName, actionCode: code)
            actionArray.append(newAction)
            
        }
        
        return (actions: actionArray, triggers: triggerArray, rules: ruleArray, sequences: sequenceArray)
    }
    
}
