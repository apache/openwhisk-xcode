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

//import Dispatch
import Foundation
import SwiftyJSON
import Conversation
import RestKit

//let json: JSON = "I'm a json"
// let json = JSON(["name":"Paul", "age": 25])
// if let name = json["name"].string {
//    print("Hello ", name);
// }

let username = "aa50bee6-a71b-47d3-8dca-e23b628315e3"
let password = "mtqVUlA5WCZy"
let version = "2016-07-19" // use today's date for the most recent version
let conversation = Conversation(username: username, password: password, version: version)

let workspaceID = "b4ff2246-c42f-407e-b172-72a631cf5498"
let failure = { (error: RestError) in print("error", error) }
var context: Context? // save context to continue conversation
var text = "hello"
conversation.message(workspaceID: workspaceID, text: text, failure: failure) { response in
    //print(response.output.text)
    print("response",response)
    context = response.context
}

// conversation.message(workspaceID: workspaceID, text: text, context: context, failure: failure) { response in
//     print(response.output.text)
//     context = response.context
// }
