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

enum OptionType: String {
    case Build = "build"
    case Help = "help"
    case Delete = "delete"
    case Undefined
    
    init(value: String) {
        switch value {
        case "install":
            self = .Build
        case "uninstall":
            self = .Delete
        case "help":
            self = .Help
        case "h":
            self = .Help
        default:
            self = .Undefined
        }
    }
}

class ConsoleIO {
    class func printUsage() {
        let executableName = (Process.arguments[0] as NSString).lastPathComponent
        
        print ("usage:")
        print ("To install a project:")
        print ("=====================")
        print ("\(executableName) install (for current directory)")
        print ("or")
        print ("\(executableName) install <project directory>")
        print ("To uninstall a project:")
        print ("=======================")
        print ("\(executableName) uninstall (for current directory)")
        print ("or")
        print ("\(executableName) uninstall <project directory>")
        
        print ("Type \(executableName) -h or --help to show usage information")
    }
    
    func getOption(option: String) -> (option: OptionType, value: String) {
        return (OptionType(value: option), option)
    }
}
