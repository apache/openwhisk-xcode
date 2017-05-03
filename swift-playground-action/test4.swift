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

//var serviceURL = "https://jsonplaceholder.typicode.com"

let username = "aa50bee6-a71b-47d3-8dca-e23b628315e3"
let password = "mtqVUlA5WCZy"
let version = "2016-07-19" 

var serviceURL = "https://gateway.watsonplatform.net/conversation/api"

var queryParameters = [URLQueryItem]()
queryParameters.append(URLQueryItem(name: "version", value: version))

let request = RestRequest(
        method: .GET,
        url: serviceURL + "/v1/workspaces",
        acceptType: "application/json",
        contentType: "application/json",
        queryParameters: queryParameters,
        username: username,
        password: password         
    )

let failure = { (error: RestError) in print("error", error) }

let success = { (msg) in print("success", msg) }

// execute REST request
request.responseJSON { response in
    switch response {
    case .success(let json): success(json)
    case .failure(let error): failure(error)
    }
}
