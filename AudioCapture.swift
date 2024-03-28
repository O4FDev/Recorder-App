import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreMedia

let outputFilePath = CommandLine.arguments[1]

var stream: SCStream?
var audioOutput: AVAudioFile?
var audioFormat: AVAudioFormat?

func startAudioCapture() async {
    let streamConfig = SCStreamConfiguration()
    streamConfig.capturesAudio = true
    streamConfig.excludesCurrentProcessAudio = true

    let shareableContent = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    let mainDisplay = shareableContent?.displays.first(where: { $0.frame.origin == .zero })
    let contentFilter = SCContentFilter(display: mainDisplay!, excludingApplications: [], exceptingWindows: [])

    do {
        stream = SCStream(filter: contentFilter, configuration: streamConfig, delegate: nil)

        audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 44100, channels: 2, interleaved: true)
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        audioOutput = try AVAudioFile(forWriting: URL(fileURLWithPath: outputFilePath), settings: audioSettings)

        try stream?.addStreamOutput(StreamOutputDelegate(), type: .audio, sampleHandlerQueue: .main)
        try await stream?.startCapture()

        print("Audio capture started")
    } catch {
        print("Error starting audio capture: \(error.localizedDescription)")
    }
}

func stopAudioCapture() {
    stream?.stopCapture()

    if audioOutput != nil {
        print("Audio capture stopped. Audio saved to: \(outputFilePath)")
    } else {
        print("Audio capture stopped. No audio file available.")
    }
}

class StreamOutputDelegate: NSObject, SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }

        var audioBufferList = AudioBufferList()
        var blockBuffer: CMBlockBuffer?

        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: &blockBuffer
        )

        guard status == noErr else {
            print("Error getting audio buffer list: \(status)")
            return
        }

        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat!, bufferListNoCopy: &audioBufferList) else {
            print("Error creating PCM buffer")
            return
        }

        do {
            try audioOutput?.write(from: pcmBuffer)
        } catch {
            print("Error writing audio: \(error.localizedDescription)")
        }
    }
}

Task {
    await startAudioCapture()
    _ = readLine() // Wait for user input to stop the capture
    stopAudioCapture()
}

RunLoop.main.run()