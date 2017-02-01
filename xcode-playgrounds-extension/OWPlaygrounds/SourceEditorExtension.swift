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
//  SourceEditorExtension.swift
//  OWPlaygrounds
//
//  Created by whisk on 1/30/17.
//  Copyright © 2017 Avery Lamp. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    
    
    func extensionDidFinishLaunching() {
        print("Hello extension")
        // If your extension needs to do any work at launch, implement this optional method.
    }
 
    
    
    var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
        // If your extension needs to return a collection of command definitions that differs from those in its Info.plist, implement this optional property getter.
        let productIdentifier = Bundle.main.infoDictionary![kCFBundleIdentifierKey as String] as! String
        
        func definitionForClassNamed(_ className: String, commandName: String) -> [XCSourceEditorCommandDefinitionKey: Any] {
            
            return [XCSourceEditorCommandDefinitionKey.identifierKey: productIdentifier + className,
                    XCSourceEditorCommandDefinitionKey.classNameKey: className,
                    XCSourceEditorCommandDefinitionKey.nameKey: commandName]
        }
        
        let myDefinitions : [[XCSourceEditorCommandDefinitionKey: Any]] = [definitionForClassNamed(EditFunctionCommand.className(),commandName: NSLocalizedString("Run function in OWPlayground", comment:""))]
        
        return myDefinitions
    }
 
    
}
