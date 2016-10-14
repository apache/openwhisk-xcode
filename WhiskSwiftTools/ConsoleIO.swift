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

let version = "0.3.0"

enum OptionType: String {
    case Build = "build"
    case Version = "version"
    case Help = "help"
    case Delete = "delete"
    case Path = "path"
    case Target = "target"
    case Undefined
    
    init(value: String) {
        switch value {
        case "install":
            self = .Build
        case "uninstall":
            self = .Delete
        case "version":
            self = .Version
        case "v":
            self = .Version
        case "help":
            self = .Help
        case "h":
            self = .Help
        case "path":
            self = .Path
        case "p":
            self = .Path
        case "target":
            self = .Target
        case "t":
            self = .Target

            
        default:
            self = .Undefined
        }
    }
}

class ConsoleIO {
    class func printUsage() {
        
        let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
        
        print ("usage:")
        print ("To install a project:")
        print ("=====================")
        print ("\(executableName) install (for current directory) -t <optional target name>")
        print ("or")
        print ("\(executableName) install -p <optional project path> -t <optional target name>")
        print ("To uninstall a project:")
        print ("=======================")
        print ("\(executableName) uninstall (for current directory) -t <optional target name>")
        print ("or")
        print ("\(executableName) uninstall -p <project directory> -t <optional target name>")
        
        print ("Type \(executableName) -h or --help to show usage information")
    }
    
    class func printVersion() {
        print("\(version)")
    }
    
    func getOption(_ option: String) -> (option: OptionType, value: String) {
        return (OptionType(value: option), option)
    }
}
