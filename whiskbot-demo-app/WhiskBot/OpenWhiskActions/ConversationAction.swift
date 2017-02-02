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

import KituraNet
import Dispatch
import Foundation
import SwiftyJSON

// MARK: - Constants
private func getConstants(key: String)->String? {
    var constants = [String:String]()
    
    // Conversation
    constants["conversation_username"] = "eaebcebc-def4-4497-a6a0-6b4dceef6348"
    //Does not require Colon seperating username and password
    constants["conversation_password"] = "IKRD6kjv8Fvu"
    constants["conversation_workspace_id"] = "ba7fb238-bd2d-4cb9-9daf-c33c07469636"

    // Translation
    constants["translation_username"] = "184ed675-a0ab-44d4-8fe7-851a35e31636"
    constants["translation_password"] = "XDMeMlwEnkdu"
    constants["translation_from_language"] = "en"
    
    // Translation supportedLanguages
    // -  In order to add more languages, check if they are supported (https://www.ibm.com/watson/developercloud/language-translator.html)
    // -  Add the language to the Entity @language, and modify the Dialog to be consistent with the language
    constants["translation_language_spanish"] = "es"
    constants["translation_language_french"] = "fr"
    constants["translation_language_arabic"] = "ar"
    constants["translation_language_korean"] = "ko"
    
    
    // Modify the URL Hooks in order to post to different teams  (https://api.slack.com/incoming-webhooks)
    // To add more channels, add them in the IBM Watson Conversation Entities, under @slack_channels.  Then add a response in Dialog for the different channels.
    constants["slack_channel_url_general"] = "https://hooks.slack.com/services/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"
    constants["slack_channel_url_random"] = "https://hooks.slack.com/services/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"
    
    return constants[key]
}

// MARK: - Main

func main(args:[String:Any])-> [String:Any]{
    var convoResponse: [String:Any]!
    
    print("Input recieved - \(args["input"])")
    
    let invokeGroup = DispatchGroup()
    invokeGroup.enter()
    
    let queue = DispatchQueue(label: "PostRequestQueue", qos: DispatchQoS.userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    
    queue.async  {
        
        post(params:args){ result in
            print("Post response recieved - \(result["output"])")
            convoResponse = result
            invokeGroup.leave()
        }
        
    }
    
    switch invokeGroup.wait(timeout:DispatchTime.now() + 15) {
    case DispatchTimeoutResult.success:
        break
    case DispatchTimeoutResult.timedOut:
        convoResponse = ["Error":"Timeout"]
        break
    }
    convoResponse =  checkForSlackPost(convoResponse: JSON(convoResponse)).dictionaryObject!
    convoResponse =  checkForTranslation(convoResponse: JSON(convoResponse)).dictionaryObject!
    return convoResponse
    
}

private func checkForTranslation(convoResponse: JSON) -> JSON{
    if convoResponse["output"]["nodes_visited"].arrayObject?.first! as? String  == "Language Choice"{
        var editedResponse: JSON?
        do{
            editedResponse = try JSON(data: convoResponse.rawData())
            let entities =  editedResponse?["entities"].arrayObject!
            for entity in entities!{
                if let dict = entity as? [String:Any]{
                    if dict["entity"] as? String == "language" {
                        let entityValue = dict["value"] as! String
                        if let language = getConstants(key:"translation_language_\(entityValue.lowercased())") {
                            editedResponse!["context"]["current_language_translation"].string = language
                            print("Language detected - \(entityValue)")
                        }else{
                            print("Language not detected - Put spanish as default language")
                            editedResponse!["context"]["current_language_translation"].string = "es"
                        }
                    }
                }
            }
        }catch{
            return convoResponse
        }
        return editedResponse!
    }
    
    if convoResponse["output"]["nodes_visited"].arrayObject?.first! as? String  == "Translate Text", let text = convoResponse["input"]["text"].string, let language = convoResponse["context"]["current_language_translation"].string {
        //print(convoResponse)
        let translation = translateMessage(text: text, language: language)
        var editedResponse: JSON?
        do{
            editedResponse = try JSON(data: convoResponse.rawData())
            let currentOutput = editedResponse!["output"]["text"].arrayObject!.first as! String
            print("Translation - \(translation) - \(currentOutput)")
            editedResponse!["output"]["text"] = ["\(currentOutput) \(translation)"]
            return editedResponse!
        }catch {
            print("Unable to edit JSON")
            return convoResponse
        }
    }
    return convoResponse
}

private func translateMessage(text:String, language: String) -> String{
    var translatedMessage = ""
    
    print("Translating \(text) into - \(language)")
    var initialParams = [String:Any]()
    initialParams["payload"] = text
    initialParams["translateTo"] = language
    if let translateFrom = getConstants(key:"translation_from_language"), let translationUsername = getConstants(key:"translation_username"), let translationPassword = getConstants(key:"translation_password"){
        initialParams["translateFrom"] = translateFrom
        initialParams["username"] = translationUsername
        initialParams["password"] = translationPassword
        
        let translation: JSON = JSON(Whisk.invoke(actionNamed: "TranslatorAction", withParameters: initialParams))
        
        if let translatedText =  translation["response"]["result"]["payload"].string {
            translatedMessage = translatedText
            print("Translated to - \(translatedText)")
        }
    }else{
        print("Some of the required Translation constants were not found")
    }
    
    return translatedMessage
}

private func checkForSlackPost(convoResponse: JSON) -> JSON{
    
    if convoResponse["output"]["nodes_visited"].arrayObject?.first! as? String  == "Slack Channel"{
        var editedResponse: JSON?
        do{
            editedResponse = try JSON(data: convoResponse.rawData())
            let entities =  editedResponse?["entities"].arrayObject!
            for entity in entities!{
                if let dict = entity as? [String:Any]{
                    if dict["entity"] as? String == "slack_channels" {
                        let slackChannel = dict["value"] as! String
                        editedResponse!["context"]["current_slack_channel"].string = slackChannel
                        print("Channel detected - \(slackChannel)")
                    }
                }
            }
        }catch{
            return convoResponse
        }
        return editedResponse!
    }
    if convoResponse["output"]["nodes_visited"].arrayObject?.first! as? String  == "Slack Post Text", let text = convoResponse["input"]["text"].string, let channel = convoResponse["context"]["current_slack_channel"].string {
        postToSlack(text: text, channel: channel)
    }
    
    return convoResponse
}

private func postToSlack(text: String, channel: String){
    print("Posting to Slack, channel - \(channel) - \(text)")
    var initialMessageParam = [String:Any]()
    initialMessageParam["text"] = text
    initialMessageParam["channel"] = channel
    initialMessageParam["username"] = "WhiskBot"
    
    if let channelURL = getConstants(key:"slack_channel_url_\(channel.lowercased())"){
        initialMessageParam["url"] = channelURL
        
        if text.contains("to Slack"){
            initialMessageParam["text"] = text.components(separatedBy: "to Slack").last
        }
        
        Whisk.invoke(actionNamed: "PostToSlack", withParameters: initialMessageParam)
    }else{
        print("Slack Channel URL not found in constants")
    }
}

private func post(params : [String:Any], callback : @escaping([String:Any]) -> Void) {
    if let username = getConstants(key:"conversation_username"), let password = getConstants(key:"conversation_password"), let workspaceId = getConstants(key:"conversation_workspace_id"){
        
        print("Convo url - \("/conversation/api/v1/workspaces/\(workspaceId)/message?version=2017-01-18")")
        
        let authString = "\(username):\(password)"
        
        let authData = authString.data(using: String.Encoding.utf8)
        let authValue = "Basic \(authData!.base64EncodedString())"
        
        
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : authValue]
        
        
        let requestOptions = [ClientRequest.Options.schema("https://"),
                              ClientRequest.Options.method("POST"),
                              ClientRequest.Options.hostname("gateway.watsonplatform.net"),
                              ClientRequest.Options.port(443),
                              ClientRequest.Options.path("/conversation/api/v1/workspaces/\(workspaceId)/message?version=2017-01-18"),
                              ClientRequest.Options.headers(headers),
                              ClientRequest.Options.disableSSLVerification]
        
        let request = HTTP.request(requestOptions) { response in
            if response != nil {
                do {
                    // this is odd, but that's just how KituraNet has you get
                    // the response as NSData
                    var jsonData = Data()
                    try response!.readAllData(into: &jsonData)
                    
                    //let resp = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    //callback(resp as! [String:Any])
                    
                    switch WhiskJsonUtils.getJsonType(jsonData: jsonData) {
                    case .Dictionary:
                        if let resp = WhiskJsonUtils.jsonDataToDictionary(jsonData: jsonData) {
                            callback(resp)
                        } else {
                            callback(["error": "Could not parse a valid JSON response."])
                            
                        }
                    case .Array:
                        if let resp = WhiskJsonUtils.jsonDataToArray(jsonData: jsonData) {
                            callback(["error": "Response is an array, expecting dictionary."])
                        } else {
                            callback(["error": "Could not parse a valid JSON response."])
                            
                        }
                    case .Undefined:
                        callback(["error": "Could not parse a valid JSON response."])
                    }
                } catch {
                    callback(["error": "Could not parse a valid JSON response."])
                }
            } else {
                callback(["error": "Did not receive a response."])
            }
        }
        
        // turn params into JSON data
        if let jsonData = WhiskJsonUtils.dictionaryToJsonString(jsonDict: params) {
            request.write(from: jsonData)
            request.end()
        } else {
            callback(["error": "Could not parse parameters."])
        }
    }else{
        print("You are missing a required constant to access the Conversation API")
    }
}

