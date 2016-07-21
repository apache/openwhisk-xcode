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

// WhiskKit protocols
public protocol WhiskAction {
    func run(args: [String:Any]) -> [String:Any]
}


// WhiskKit implementations
public class WhiskRule {
    public init(trigger: WhiskTrigger, action: WhiskAction) {
        trigger.mapAction(action: action)
    }
    
    public func setRule(trigger: WhiskTrigger, action: WhiskAction) {
        trigger.mapAction(action: action)
    }
}

public class WhiskTrigger {
    
    var actions = [WhiskAction]()
    
    func mapAction(action: WhiskAction) {
        actions.append(action)
    }
    
    public func fire(args: [String:Any]) {
        for action in actions {
            let _ = action.run(args: args)
        }
    }
}

public class WhiskSequence {
    
    var actions = [WhiskAction]()
    
    public func setActions(actions: [WhiskAction]) {
        self.actions = actions
    }
    
    public func run(args:[String:Any]) -> [String:Any] {
        
        var result = args
        for action in actions {
            result = action.run(args: result)
        }
        
        return result
    }
}

