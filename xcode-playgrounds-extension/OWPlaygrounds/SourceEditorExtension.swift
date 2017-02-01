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
