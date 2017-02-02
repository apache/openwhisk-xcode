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
//  SpeechRecognizer.swift
//  WhiskBot
//
//  Created by whisk on 1/18/17.
//  Copyright © 2017 Avery Lamp. All rights reserved.
//

import UIKit
import Speech

protocol appleSpeechFeedbackProtocall: class {
    func finalAppleRecognitionRecieved( phrase: String)
    func partialAppleRecognitionRecieved( phrase: String)
    func errorAppleRecieved(error: String)
}


class SpeechRecognizer: NSObject, SFSpeechRecognizerDelegate  {
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    var recognitionRequest : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask : SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    var delegate: appleSpeechFeedbackProtocall?
    var speechAuthorized = false
    var isRecording = false
    
    func setupSpeechRecognition(){
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            OperationQueue.main.addOperation {
                switch authStatus{
                case .authorized:
                    print("Recording Authorized")
                    self.speechAuthorized = true
                case .denied:
                    print("Recording Denied")
                default:
                    print("Something went wrong")
                }
            }
        }
    }
    
    func startRecording() {
        if isRecording{
            isRecording = false
            self.audioEngine.stop()
            audioEngine.inputNode?.removeTap(onBus: 0)
            self.recognitionRequest = nil
            self.recognitionTask = nil
            print("Stopped Recording")
            return
        }else{
            print("Started Recording")
            isRecording = true
        }
        if speechAuthorized == false{
            setupSpeechRecognition()
        }
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try  audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        }catch {
            print("Error creating audio session")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let input = audioEngine.inputNode else { fatalError("Audio Engine has no input") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create SFSpeechAudioBuffer") }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            if let result = result {
                for transcription in result.transcriptions {
                    print(transcription.formattedString)
                }
                let partialText = result.bestTranscription.formattedString
                if result.isFinal == true {
                    self.audioEngine.stop()
                    input.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    self.delegate?.finalAppleRecognitionRecieved(phrase: result.bestTranscription.formattedString)
                }else{
                    self.delegate?.partialAppleRecognitionRecieved(phrase: partialText)
                }
            }
            
            if error != nil {
                print("Error recieved - \(error)")
                self.delegate?.errorAppleRecieved(error: "\(error)")
            }
        })
        
        let recordingFormat = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, time) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        }catch{
            print("Unable to start audio engine")
        }
        
    }

}
