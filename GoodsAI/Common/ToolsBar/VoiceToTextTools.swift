//
//  AudioRecorder.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/20.
//

import AVFoundation
import Speech


class VoiceToTextTools {

    var blockInputText:((String)->())?

    var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    
    func requestRecordPermission(){
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            guard granted else { return }
            SFSpeechRecognizer.requestAuthorization { status in
                guard status == .authorized else { return }
            }
        }
    }

    
    func startLiveTranscribe() {

        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            guard granted else { return }
            SFSpeechRecognizer.requestAuthorization { status in
                guard status == .authorized else { return }
            }
        }
        
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement)
        // 2. Create English recognizer
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
            recognizer.isAvailable else {
            print("English recognizer unavailable")
            return
        }
        
        let tempA = AVAudioEngine()
        audioEngine = tempA

        // 3. Configure audio input
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
               
        // 4. Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true // Enable real-time recognition
               
        // 5. Start engine
        audioEngine.prepare()
        try? audioEngine.start()

        // 6. Begin recognition task
        recognizer.recognitionTask(with: recognitionRequest!) { result, _ in
            guard let text = result?.bestTranscription.formattedString else { return }
            print("Recognition result: \(text)")
            if((self.blockInputText) != nil){
                self.blockInputText!(text)
            }
        }
    }
    
    
    func stopLiveTranscribe() {
        audioEngine.stop()
    }
    
    

}
