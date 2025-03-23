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
        // 2. 创建英文识别器
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
            recognizer.isAvailable else {
            print("英文识别器不可用")
            return
        }
        
        let tempA = AVAudioEngine()
        audioEngine = tempA

        // 3. 配置音频输入
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
               
        // 4. 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true // 启用实时识别
               
        // 5. 启动引擎
        audioEngine.prepare()
        try? audioEngine.start()

        // 6. 开始识别任务
        recognizer.recognitionTask(with: recognitionRequest!) { result, _ in
            guard let text = result?.bestTranscription.formattedString else { return }
            print("识别结果: \(text)")
            if((self.blockInputText) != nil){
                self.blockInputText!(text)
            }
        }
    }
    
    
    func stopLiveTranscribe() {
        audioEngine.stop()
    }
    
    

}
