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

public class ProjectManager {
    
    let whisk: WhiskAPI!
    let path: String!
    let projectReader: ProjectReader!
    let namespace: String!
    
    
    public init(path: String, repo: String? = nil, release: String? = nil, xcodeDirectory: String? = nil, credentials: WhiskCredentials, namespace: String) {
        whisk = WhiskAPI(credentials: credentials)
        self.path = path
        self.namespace = namespace
        
        do {
            projectReader = try ProjectReader(path: path, repo: repo, release: release)
        } catch {
            projectReader = nil
            print("Error creating project \(error)")
        }
        
    }
    
    public func deployProject() throws {
        if (projectReader) != nil {
            
            let group = DispatchGroup()
            group.enter()
            
            let queue = DispatchQueue(label:"com.ibm.mobilefirst.deployProject")
            queue.async(qos: .userInitiated) {
                do {
                    self.projectReader?.clearAll()
                    
                    try self.projectReader?.readRootDependencies(clone: true)
                    try self.projectReader?.readProjectDirectory()
                    
                    self.projectReader?.dumpProjectStructure()
                    
                    try self.installPackages()
                    try self.installTriggers()
                    try self.installActions()
                    try self.installSequences()
                    try self.installRules()
                    try self.enableRules()
                    
                    group.leave()
                } catch {
                    print("Error \(error)")
                }
                
            }
            
            switch group.wait(timeout: DispatchTime.distantFuture) {
            case DispatchTimeoutResult.Success:
                break
            case DispatchTimeoutResult.TimedOut:
                break
                
            }
            
        } else {
            print("Cannot deploy project, error initializing project reader")
        }
    }
    
    public func deleteProject() throws {
        
        if projectReader != nil {
            let group = DispatchGroup()
            group.enter()
            
            let queue = DispatchQueue(label:"com.ibm.mobilefirst.deleteProject")
            queue.async(qos: .userInitiated) {
                do {
                    self.projectReader?.clearAll()
                    
                    try self.projectReader?.readRootDependencies(clone: false)
                    try self.projectReader?.readProjectDirectory()
                    self.projectReader?.dumpProjectStructure()
                    
                    try self.deleteRules()
                    try self.deleteActionsAndSequences()
                    try self.deleteTriggers()
                    try self.deletePackages()
                    
                    self.projectReader.clearAll()
                    
                    group.leave()
                } catch {
                    print("Error \(error)")
                }
                
            }
            
            switch group.wait(timeout: DispatchTime.distantFuture) {
            case DispatchTimeoutResult.Success:
                break
            case DispatchTimeoutResult.TimedOut:
                break
                
            }
        } else {
            print("Cannot uninstall project, error initializing project reader")
        }
    }
    
    
    public func installSequences() throws {
        let sequences = projectReader.sequenceDict
        
        let group = DispatchGroup()
        
        for (name, sequence) in sequences {
            try whisk.createSequence(qualifiedName: name as String, actions: sequence.actions, group: group)
        }
        
        switch group.wait(timeout: DispatchTime.distantFuture) {
        case DispatchTimeoutResult.Success:
            print("Install sequence success")
            break
        case DispatchTimeoutResult.TimedOut:
            print("Install sequence timed out")
            break
        }
        
        
    }
    public func installPackages() throws {
        let packages = projectReader.packageDict
        
        let group = DispatchGroup()
        
        for (name, package) in packages {
            try whisk.createPackage(name: name as String, bindTo: package.bindTo, namespace: namespace, parameters: package.parameters, group: group)
        }
        
        switch group.wait(timeout: DispatchTime.distantFuture) {
        case DispatchTimeoutResult.Success:
            print("Install packages success")
            break
        case DispatchTimeoutResult.TimedOut:
            print("Install pacakges timed out")
            break
        }
        
        
        
    }
    
    public func deletePackages() throws {
        let packages = projectReader.packageDict
        
        let group = DispatchGroup()
        
        for (name, _) in packages {
            try whisk.deletePackage(name: name as String, namespace: namespace, group: group)
        }
        
        switch group.wait(timeout: DispatchTime.distantFuture) {
        case DispatchTimeoutResult.Success:
            print("delete packages success")
            break
        case DispatchTimeoutResult.TimedOut:
            print("delete packages timed out")
            break
        }
        
        
    }
    
    public func installRules() throws {
        let rules = projectReader.ruleDict
        
        let group = DispatchGroup()
        
        for (name, rule) in rules {
            try whisk.createRule(name: name as String, namespace: namespace, triggerName: rule.trigger as String, actionName: rule.action as String, group: group)
        }
        
        switch group.wait(timeout: DispatchTime.distantFuture) {
        case DispatchTimeoutResult.Success:
            print("Install rules success")
            break
        case DispatchTimeoutResult.TimedOut:
            print("Install rules timed out")
            break
        }
        
        
        
    }
    
    public func enableRules() throws {
        let rules = projectReader.ruleDict
        
        let group = DispatchGroup()
        
        for (name, rule) in rules {
            try whisk.enableRule(name: name as String, namespace: namespace, triggerName: rule.trigger as String, actionName: rule.action as String, group: group)
        }
        
        switch group.wait(timeout: DispatchTime.distantFuture) {
        case DispatchTimeoutResult.Success:
            print("enable success")
            break
        case DispatchTimeoutResult.TimedOut:
            print("enable timed out")
            break
        }
        
        
        
    }
    
    
    
    public func deleteRules() throws {
        let rules = projectReader.ruleDict
        
        let group = DispatchGroup()
        
        for (name, _) in rules {
            try whisk.deleteRule(name: name as String, namespace: namespace, group: group)
        }
        
        switch group.wait(timeout: DispatchTime.distantFuture) {
        case DispatchTimeoutResult.Success:
            print("delete rules success")
            break
        case DispatchTimeoutResult.TimedOut:
            print("delete rules timed out")
            break
        }
        
        
        
    }
    
    public func installTriggers() throws {
        let triggers = projectReader.triggerDict
        
        let group = DispatchGroup()
        
        for (name, trigger) in triggers {
            if let _ = trigger.feed {
                try whisk.createFeed(name: name as String, namespace: namespace, trigger: trigger, group: group)
            } else {
                try whisk.createTrigger(name: name as String, namespace: namespace, parameters: trigger.parameters, group: group)
            }
        }
        
        switch group.wait(timeout: DispatchTime.distantFuture) {
        case DispatchTimeoutResult.Success:
            print("install triggers success")
            break
        case DispatchTimeoutResult.TimedOut:
            print("install timed out")
            break
        }
        
        
    }
    
    public func deleteTriggers() throws {
        let triggers = projectReader.triggerDict
        
        let group = DispatchGroup()
        
        for (name, _ ) in triggers {
            try whisk.deleteTrigger(name: name as String, namespace: namespace, group: group)
        }
        
        switch group.wait(timeout: DispatchTime.distantFuture) {
        case DispatchTimeoutResult.Success:
            print("delete triggers success")
            break
        case DispatchTimeoutResult.TimedOut:
            print("delete triggers timed out")
            break
        }
        
        
        
    }
    
    public func installActions() throws {
        let actions = projectReader.actionsDict
        
        let group = DispatchGroup()
        
        for (name, action) in actions {
            let sourceCodePath = action.path
            let runtime = action.runtime
            let parameters = action.parameters
            
            
            // read code
            let code = try String(contentsOfFile: sourceCodePath as String)
            
            var runtimeStr = "nodejs"
            switch runtime {
            case Runtime.Swift:
                runtimeStr = "swift"
            case Runtime.Swift3:
                runtimeStr = "swift:3"
            case Runtime.Python:
                runtimeStr = "python"
            case Runtime.Java:
                runtimeStr = "java"
            default:
                break
                
            }
            
            try whisk.createAction(qualifiedName: name as String, kind: runtimeStr, code: code as String, parameters: parameters, group: group)
        }
        
        switch group.wait(timeout: DispatchTime.distantFuture) {
        case DispatchTimeoutResult.Success:
            print("Install actions success")
            break
        case DispatchTimeoutResult.TimedOut:
            print("Install actions timed out")
            break
        }
        
        
        
    }
    
    public func deleteActionsAndSequences() throws {
        let actions = projectReader.actionsDict
        let group = DispatchGroup()
        for (name, _) in actions {
            try whisk.deleteAction(qualifiedName: name as String, group: group)
        }
        
        let sequences = projectReader.sequenceDict
        for (name, _) in sequences {
            try whisk.deleteAction(qualifiedName: name as String, group: group)
        }
        
        switch group.wait(timeout: DispatchTime.distantFuture) {
        case DispatchTimeoutResult.Success:
            print("delete actions and sequences success")
            break
        case DispatchTimeoutResult.TimedOut:
            print("delete actions and sequences timed out")
            break
        }
    }
    
}
