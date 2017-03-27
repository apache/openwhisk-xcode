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

/*
 We have to create everything in a certain order:
 1. Packages
 2. Actions
 3. Triggers
 4. Rules
 */


public enum WhiskProjectError: Error {
    case duplicateNameError(name: String)
    case malformedManifestFile(name: String, cause: String)
    case ruleStateError(type: String, cause: String)
    case gitRequestError(cause: String)
    case unsupportedFeedType(cause: String)
}

enum Runtime {
    case swift
    case nodeJS
    case java
    case python
}

public struct Package {
    let name: NSString
    let bindTo: String?
    let parameters: Array<[String:AnyObject]>?
}

public struct Trigger {
    let name: NSString
    let feed: NSString?
    let parameters: Array<[String:AnyObject]>?
}

public struct Rule {
    let name: NSString
    let trigger: NSString
    let action: NSString
}

public struct Sequence {
    let name: NSString
    let actions: Array<String>
}

public struct Action {
    let name: NSString
    let path: NSString
    var runtime: Runtime
    var parameters: Array<[String:AnyObject]>?
}

public struct Dependency {
    let name: NSString
    let url: NSString
    let version: NSString
}


open class ProjectReader {
    
    let BindingsFileName = "root-manifest.json"
    let ManifestFileName = "manifest.json"
    let DependencyDirectoryName = "Packages"
    
    var projectPath: String!
    var packageDict = [NSString: Package]()
    var actionsDict = [NSString: Action]()
    var triggerDict = [NSString: Trigger]()
    var dependenciesDict = [NSString: Dependency]()
    var ruleDict = [NSString: Rule]()
    var sequenceDict = [NSString: Sequence]()
    var manifestDict = [NSString: NSString]()
    var bindingsDict = [NSString: NSString]()
    
    var target: String?
    
    
    
    public init(path: String, repo: String? = nil, release: String? = nil, target: String?) throws  {
        
        self.target = target
        
        if let repo = repo {
            
            if let release = release {
                do {
                    
                    let group = DispatchGroup()
                    
                    let zipFilePath = "\(repo)/archive/\(release).zip"
                    try Git.cloneGitRepo(zipFilePath, toPath: path, group: group)
                    
                    switch group.wait(timeout: DispatchTime.distantFuture) {
                    case DispatchTimeoutResult.success:
                        let projectName = (repo as NSString).lastPathComponent
                        projectPath = "\(path)/\(projectName)-\(release)/src"
                        break
                    case DispatchTimeoutResult.timedOut:
                        throw WhiskProjectError.gitRequestError(cause: "Failure cloning repo \(repo): request timed out.")
                    }
                    
                } catch {
                    print("Error cloning repo \(error)")
                }
            } else {
                throw WhiskProjectError.gitRequestError(cause: "Cannot clone, release version must be specified ")
            }
        } else {
            projectPath = path
        }
    }
    
    open func dumpProjectStructure() {
        print("Packages:")
        print("=========")
        for (name, package) in packageDict {
            print("   name:\(name), package: \(package)")
        }
        
        print("Actions:")
        print("=========")
        for (name, action) in actionsDict {
            print("   name:\(name), path:\(action.path), runtime: \(action.runtime), parameters: \(action.parameters)")
        }
        
        print("Sequences:")
        print("=========")
        for (name, sequence) in sequenceDict {
            print("   name:\(name), sequence: \(sequence)")
        }
        
        print("Triggers:")
        print("=========")
        for (name, trigger) in triggerDict {
            print("   name:\(name), trigger:\(trigger)")
        }
        
        print("Rules:")
        print("=========")
        for (name, rule) in ruleDict {
            print("   name:\(name), rule:\(rule)")
        }
        
        print("Bindings:")
        print("=========")
        for (name, path) in bindingsDict {
            print("   name: \(name), path: \(path)")
        }
        
        
        print("Manifest:")
        print("=========")
        for (name, path) in manifestDict {
            print("   name: \(name), path: \(path)")
        }
        
        print("Dependencies:")
        print("=============")
        for (name, dependency) in dependenciesDict {
            print("   name: \(name), dependency: \(dependency)")
        }
        
    }
    
    open func readRootDependencies(_ clone: Bool) throws {
        
        let path = projectPath+"/"+BindingsFileName
        let json = try ManifestReader.parseJson(path as NSString)
        
        
        if let dependencies = json["dependencies"] {
            for dependency in dependencies as! Array<[String:AnyObject]> {
                guard let url = dependency["url"] as? NSString else {
                    clearAll()
                    throw WhiskProjectError.malformedManifestFile(name: path as String, cause: "Declaration of dependency missing url")
                }
                
                var repo = url as String
                
                if url.pathExtension == "git" {
                    
                    repo = String((repo as String).characters.dropLast(4))
                }
                
                let name = (repo as NSString).lastPathComponent as NSString
                
                var ver = "master"
                if let version = dependency["version"] as? NSString {
                    ver = version as String
                }
                
                let dep = Dependency(name: name as NSString, url: repo as NSString, version: ver as NSString)
                dependenciesDict[name] = dep
            }
        }
        
        try readDependencies(clone)
    }
    
    open func readProjectDirectory() throws {
        // read project directory
        try readDirectory(projectPath, isDependency: false)
        
        // read independent directories
    }
    
    open func readDependencies(_ clone: Bool) throws {
        for (name, dependency) in dependenciesDict {
            
            let group = DispatchGroup()
            
            let zipFilePath = "\(dependency.url)/archive/\(dependency.version).zip"
            if clone == true {
                try Git.cloneGitRepo(zipFilePath, toPath: projectPath+"/Packages/", group: group)
            }
            
            switch group.wait(timeout: DispatchTime.distantFuture) {
            case DispatchTimeoutResult.success:
                let packagePath = (name as String)+"-"+(dependency.version as String)
                let depPath = projectPath+"/Packages/"+packagePath+"/src"
                try readDirectory(depPath, isDependency: true)
                break
            case DispatchTimeoutResult.timedOut:
                break
            }
            
        }
    }
    
    open func detectXcode(_ path: String) -> (isXcode: Bool, projectName: NSString?) {
        let fileManager = FileManager.default
        if let enumerator: FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: path) {
            while let item = enumerator.nextObject() as? NSString {
                if item.pathComponents.count == 1 {
                    if item.pathExtension == "xcodeproj" {
                        return (isXcode: true, projectName: "\(path)/\(item)" as NSString)
                    }
                }
            }
        }
        return (isXcode: false, projectName: nil)
    }
    
    open func readDirectory(_ dirPath: String, isDependency: Bool) throws {
        
        let isXcode = detectXcode(dirPath)
        
        if isXcode.isXcode == false {
            let dir: FileManager = FileManager.default
            
            if let enumerator: FileManager.DirectoryEnumerator = dir.enumerator(atPath: dirPath) {
                
                var packageDir = "/"
                var maxDepth = 2
                
                if isDependency == true {
                    maxDepth = 4
                }
                while let item = enumerator.nextObject() as? NSString {
                    
                    // only check 2 levels down
                    if item.pathComponents.count <= maxDepth {
                        var isDir = ObjCBool(false)
                        let fullPath = dirPath+"/\(item)"
                        
                        if dir.fileExists(atPath: fullPath, isDirectory: &isDir) == true {
                            if isDir.boolValue == true {
                                
                                if item.pathComponents[0] != packageDir && item.pathComponents[0] != DependencyDirectoryName {
                                    packageDir = item.pathComponents[0]
                                    if packageDir.hasPrefix(".") == false {
                                        packageDict[item] = Package(name: item, bindTo: nil, parameters: nil)
                                    }
                                }
                                
                            }  else if item.hasSuffix(".swift") {
                                try addAction(fullPath as NSString, item: item, runtime: .swift)
                            }  else if item.hasSuffix(".js") {
                                try addAction(fullPath as NSString, item: item, runtime: .nodeJS)
                            } else if item.hasSuffix(".json") {
                                
                                // in subdirectories we only look for manifest files
                                if item.pathComponents.count > 1 {
                                    
                                    // ignore hidden directories
                                    if item.pathComponents[0].hasPrefix(".") == false {
                                        
                                        let name = item.lastPathComponent
                                        let package = item.pathComponents[0]
                                        let qualifiedName = "\(package)/\(name)" as NSString
                                        
                                        if name == "\(package)-\(ManifestFileName)" {
                                            manifestDict[qualifiedName] = fullPath as NSString
                                        }
                                    }
                                } else {
                                    
                                    // in root dir, we look for bindings and manifest files
                                    if item == BindingsFileName as NSString {
                                        bindingsDict[item] = fullPath as NSString
                                    }
                                }
                            }
                        }
                    }
                    
                }
                
                try self.processManifestFiles(self.bindingsDict)
                try self.processManifestFiles(self.manifestDict)
            }
        } else {
            
            print("Found xcode directory \(isXcode.projectName!)" )
            let xcodeProject = WhiskTokenizer(from: dirPath, to:projectPath, projectFile: isXcode.projectName!, target: target)
            
            do {
                let xcodeTuple = try xcodeProject.readXCodeProjectDirectory()
                
                for entity in xcodeTuple.actions{
                    actionsDict[entity.name] = entity
                }
                
                for entity in xcodeTuple.triggers {
                    triggerDict[entity.name] = entity
                }
                
                for entity in xcodeTuple.rules {
                    print("Processing rule \(entity.name)")
                    ruleDict[entity.name] = entity
                }
                
                for entity in xcodeTuple.sequences {
                    sequenceDict[entity.name] = entity
                }
                
                
            } catch {
                print("Error reading xcode project \(error)")
            }
        }
    }
    
    func addAction(_ fullPath: NSString, item: NSString, runtime: Runtime) throws {
        
        let name = (item.lastPathComponent as NSString).deletingPathExtension
        
        if item.pathComponents.count > 1 {
            if item.pathComponents[0].hasPrefix(".") == false {
                
                let package = item.pathComponents[0]
                
                let fullName = "\(package)/\(name)" as NSString
                if !nameExists(fullName) {
                    actionsDict[fullName] = Action(name: fullName, path: fullPath, runtime: runtime, parameters: nil)
                } else {
                    clearAll()
                    throw WhiskProjectError.duplicateNameError(name:fullName as String)
                }
            }
        } else {
            if !nameExists(name as NSString) {
                actionsDict[name as NSString] = Action(name: name as NSString, path: fullPath, runtime: runtime, parameters: nil)
            } else {
                clearAll()
                throw WhiskProjectError.duplicateNameError(name: name)
            }
        }
    }
    
    func nameExists(_ name: NSString) -> Bool {
        if actionsDict[name] != nil || packageDict[name] != nil || triggerDict[name] != nil || ruleDict[name] != nil || sequenceDict[name] != nil {
            return true
        }
        
        return false
    }
    
    func processManifestFiles(_ manifest: [NSString: NSString]) throws {
        
        for (name, path) in manifest {
            
            let json = try ManifestReader.parseJson(path)
            
            var prefix = ""
            if name.pathComponents.count > 1 {
                prefix = name.pathComponents[0] + "/"
            }
            
            // Check these items for a root manifest only
            if prefix == "" {
                
                // process packages
                if let packages = json["bindings"] {
                    for package in packages as! Array<[String:AnyObject]> {
                        
                        guard let itemName = package["name"] as? String, let bindTo = (package["bindTo"]) as? String else {
                            clearAll()
                            throw WhiskProjectError.malformedManifestFile(name: path as String, cause: "Declaration of package binding missing name or bindTo")
                        }
                        
                        let parameters = package["parameters"] as? Array<[String:AnyObject]>
                        let item = Package(name: itemName as NSString, bindTo: bindTo, parameters: parameters)
                        packageDict[itemName as NSString] = item
                        
                    }
                }
                
                // process triggers
                if let triggers = json["triggers"] {
                    for trigger in triggers as! Array<[String:AnyObject]> {
                        
                        guard let itemName = trigger["name"] as? String else {
                            clearAll()
                            throw WhiskProjectError.malformedManifestFile(name: path as String, cause: "Declaration of trigger missing name")
                        }
                        
                        let parameters = trigger["parameters"] as? Array<[String:AnyObject]>

                        let feed = trigger["feed"] as? NSString
                        let item = Trigger(name: itemName as NSString, feed: feed, parameters: parameters)
                        triggerDict[itemName as NSString] = item
                    }
                    
                }
                
                
                // process rules
                if let rules = json["rules"] {
                    for rule in rules as! Array<[String:AnyObject]> {
                        
                        guard let itemName = rule["name"] as? String, let triggerName = rule["trigger"] as? String, let actionName = rule["action"] as? String else {
                            clearAll()
                            throw WhiskProjectError.malformedManifestFile(name: path as String, cause: "Declaration of rule missing name, trigger, or action")
                        }
                        
                        let item = Rule(name: itemName as NSString, trigger: triggerName as NSString, action: actionName as NSString)
                        ruleDict[itemName as NSString] = item
                    }
                    
                }
            }
            
            
            // check these for all manifest files
            // process sequences
            if let sequences = json["sequences"] {
                for sequence in sequences as! Array<[String:AnyObject]> {
                    
                    guard let itemName = sequence["name"] as? String, let actions = sequence["actions"] as? Array<String> else {
                        clearAll()
                        throw WhiskProjectError.malformedManifestFile(name: path as String, cause: "Declaration of sequence missing name or action list")
                    }
                    
                    let item = Sequence(name: prefix+itemName as NSString, actions: actions)
                    sequenceDict[ (prefix+itemName) as NSString] = item
                }
            }
            
            // process package parameters
            if let packageParams = json["packageParameters"] as? Array<[String:AnyObject]> {
                let packageName = name.pathComponents[0] as NSString
                if let item = packageDict[packageName] {
                    packageDict[packageName] = Package(name: packageName, bindTo: item.bindTo, parameters: packageParams)
                }
            }
            
            // process action parameters
            if let actionParams = json["actionParameters"] {
                for action in actionParams as! Array<[String:AnyObject]> {
                    
                    guard let itemName = action["action"] as? String else {
                        clearAll()
                        throw WhiskProjectError.malformedManifestFile(name: path as String, cause: "Declaration of action parameters in manfiest file is missing \'action\' attribute")
                    }
                    
                    if let item = actionsDict[(prefix+itemName) as NSString] {
                        var runtime = item.runtime
                        if let kind = action["kind"] as? String {
                            // swift:default == swift:3 at the moment
                            if runtime == Runtime.swift && kind == "swift:3" {
                                runtime = Runtime.swift
                            }
                        }
                        
                        let parameters = action["parameters"] as? Array<[String:AnyObject]>
                        actionsDict[(prefix+itemName) as NSString] = Action(name: (prefix+itemName) as NSString, path: item.path, runtime: runtime, parameters: parameters)
                        
                    } else {
                        clearAll()
                        throw WhiskProjectError.malformedManifestFile(name: path as String, cause: "Setting parameters for an action \(itemName) that does not exist")
                    }
                    
                }
            }
        }
    }
    
    func clearAll() {
        packageDict.removeAll()
        actionsDict.removeAll()
        triggerDict.removeAll()
        ruleDict.removeAll()
        sequenceDict.removeAll()
        manifestDict.removeAll()
        bindingsDict.removeAll()
        dependenciesDict.removeAll()
    }
}

