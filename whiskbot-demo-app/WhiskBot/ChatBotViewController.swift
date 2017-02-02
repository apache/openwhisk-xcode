//
//  ChatBotViewController.swift
//  WhiskBot
//
//  Created by whisk on 1/18/17.
//  Copyright © 2017 Avery Lamp. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import OpenWhisk
import SwiftyJSON
import EventKit

class ChatBotViewController: JSQMessagesViewController, appleSpeechFeedbackProtocall{
    
    var messageData = [JSQMessage]()
    
    var context: JSON? // save context to continue conversation
    var whisk: Whisk?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let whiskCreds = WhiskCredentials(accessKey: "0f4acfd7-5717-4315-aefe-729d654209e3", accessToken: "9MuYZ2UQ9bLPxw7qjzAsaBvfXHyexvO5Fi6iPemJvPoUA9f415nRNhClEfTy7moe")
        whisk = Whisk(credentials: whiskCreds)
        
        self.senderId = "User"
        self.senderDisplayName = "Client"
        self.finishSendingMessage(animated: true)
        
        initialMessageFromConversation()
        speechRecognizer.setupSpeechRecognition()
        speechRecognizer.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.eventStore = EKEventStore()
        self.reminders = [EKReminder]()
        
        self.eventStore.requestAccess(to: .reminder) { (granted, error) in
            if granted{
                let predicate = self.eventStore.predicateForReminders(in: nil)
                self.eventStore.fetchReminders(matching: predicate, completion: { (reminders) in
                    self.reminders = reminders
                })
            }else {
                print("Permission not granted for reminders")
            }
        }
    }
    
    func initialMessageFromConversation(){
        
        let initialMessageParam = [String:Any]()
        do{
            try whisk?.invokeAction(name: "Conversation", package: "", namespace: "", parameters: initialMessageParam as AnyObject?, hasResult: true, callback: { (result, error) in
                if error == nil{
                    let jsonResult = JSON(result!)
                    //print("Result - \(jsonResult["result"]["output"]["text"])")
                    let incomingString = jsonResult["result"]["output"]["text"].arrayObject?.first as? String
                    let incomingMessage = JSQMessage(senderId: "Bluemix", displayName: "Bluemix", text: incomingString)
                    self.messageData.append(incomingMessage!)
                    DispatchQueue.main.async {
                        self.finishSendingMessage(animated: true)
                        self.context = jsonResult["result"]["context"]
                        self.context?["current_slack_channel"] = "general"
                        self.context?["last_reminder_text"] = "Reminder text"
                    }
                }else{
                    print("error invoking - \(error)")
                }
            })
        }catch{
            print("Error thrown invoking whisk action")
        }
        
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        print("Send message - \(text)")
        messageData.append(JSQMessage(senderId: "User", displayName: "Client", text: text))
        
        var initialMessageParam = [String:Any]()
        initialMessageParam["input"] = ["text":text]
        initialMessageParam["context"] = self.context?.dictionaryObject
        //print("Context - \(self.context?.dictionaryObject)")
        do{
            try whisk?.invokeAction(name: "Conversation", package: "", namespace: "", parameters: initialMessageParam as AnyObject?, hasResult: true, callback: { (result, error) in
                if error == nil{
                    
                    let jsonResult = JSON(result!)
                    let incomingString = jsonResult["result"]["output"]["text"].arrayObject?.first as? String
                    if incomingString != nil && incomingString != "" {
                        let incomingMessage = JSQMessage(senderId: "Bluemix", displayName: "Bluemix", text: incomingString)
                        self.messageData.append(incomingMessage!)
                        DispatchQueue.main.async {
                            self.finishSendingMessage(animated: true)
                            self.context = jsonResult["result"]["context"]
                            self.processActions(text: text, jsonResult: jsonResult)
                            if (incomingString?.contains("Translation -"))! {
                                let timeAfterOpen = 1.0
                                DispatchQueue.main.asyncAfter(
                                    deadline: DispatchTime.now() + Double(Int64(timeAfterOpen * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                                        print("Followup")
                                        let followUpMessage = JSQMessage(senderId: "Bluemix", displayName: "Bluemix", text: "Is there anything else you would like me to do?")
                                        self.messageData.append(followUpMessage!)
                                        self.finishSendingMessage(animated: true)
                                })

                            }
                        }
                    }
                    
                }else{
                    print("error invoking - \(error)")
                }
            })
        }catch{
            
            print("Error thrown invoking whisk action")
        }
        self.finishSendingMessage(animated: true)
    }
    
    func processActions(text: String, jsonResult: JSON){
        let lastNodeVisited = jsonResult["result"]["output"]["nodes_visited"].arrayObject?.first! as? String
        print("Last Node - \(lastNodeVisited)")
        
        if lastNodeVisited == "Reminder Text" {
            self.context?["last_reminder_text"].string = text
        }
        
        if lastNodeVisited == "Reminder Time" {
            let entities =  jsonResult["result"]["entities"]
            var dateString = ""
            var timeString = ""
            
            for entity in entities.arrayObject!{
                if let dict = entity as? [String:Any]{
                    if dict["entity"] as? String == "sys-time" {
                        print("Sys-time - \(dict["value"] as! String)")
                        timeString = dict["value"] as! String
                    }
                    if dict["entity"] as? String == "sys-date" {
                        print("Sys-date - \(dict["value"] as! String)")
                        dateString = dict["value"] as! String
                    }
                }
            }
            let todaysDate = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if dateString == ""{
                dateString = dateFormatter.string(from: todaysDate)
            }
            if timeString == "" {
                timeString = "18:00:00"
            }
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let dateToRemind = dateFormatter.date(from: "\(dateString) \(timeString)"){
                print("Date to remind - \(dateToRemind)")
                self.createReminder(text: (self.context?["last_reminder_text"].string)!, date: dateToRemind)
            }
        }
    }
    
    var isListening = false
    var textBeforeSpeech = ""
    var speechRecognizer = SpeechRecognizer()
    override func didPressAccessoryButton(_ sender: UIButton!) {
        print("Accessory button pressed")
        isListening = true
        
        speechRecognizer.startRecording()
        
    }
    
    //MARK : - UICollectionView Data source
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messageData.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = self.messageData[indexPath.item]
        if !message.isMediaMessage{
            cell.textView.textColor = UIColor.black
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messageData[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = self.messageData[indexPath.item]
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        if message.senderId == self.senderId{
            return bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor.black)
        }else{
            return bubbleFactory?.incomingMessagesBubbleImage(with: UIColor.lightGray)
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = self.messageData[indexPath.item]
        
        let  bluemixAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: #imageLiteral(resourceName: "bluemixLogo"), diameter: 30)
        let clientAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: #imageLiteral(resourceName: "openwhiskLogo"), diameter: 30)
        if message.senderId == self.senderId{
            return clientAvatar
        }else{
            return bluemixAvatar
        }
    }
    
    var eventStore: EKEventStore!
    var reminders: [EKReminder]!
    
    func createReminder(text: String, date: Date){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d, h:mm"
        let alert  = UIAlertController(title: "Create Reminder?", message: "Would you like to create the reminder: \(text) - at \(dateFormatter.string(from: date))", preferredStyle: .actionSheet)
        let confirmAction = UIAlertAction(title: "Yes", style: .default) { (action) in
            let reminder = EKReminder(eventStore: self.eventStore)
            reminder.title = text
            reminder.calendar = self.eventStore.defaultCalendarForNewReminders()

            reminder.addAlarm(EKAlarm(absoluteDate: date))
            //reminder.completionDate = date
            do {
                try self.eventStore.save(reminder, commit: true)
                print("Reminder set - \(text) - at \(dateFormatter.string(from: date))")
            }catch{
                print("Error creating and saving reminder - \(error)")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (action) in
            print("Reminder creation canceled")
        }
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK : - Speech Recognition Delegates
    
    func finalAppleRecognitionRecieved(phrase: String) {
        print("Final Speech recieved - \(phrase)")
    }
    
    func partialAppleRecognitionRecieved(phrase: String) {
        print("Partial Speech recieved - \(phrase)")
    }
    
    func errorAppleRecieved(error: String) {
        print("SPEECH ERROR - \(error)")
    }
    
}
