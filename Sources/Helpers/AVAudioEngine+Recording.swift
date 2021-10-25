import Foundation
import AVFoundation
import Combine

public extension AVAudioEngine {

    var recordingBufferPublisher: AnyPublisher<AVAudioPCMBuffer, Never> {

        Deferred<AnyPublisher<AVAudioPCMBuffer, Never>> { [unowned self] in

            let subject = PassthroughSubject<AVAudioPCMBuffer, Never>()
            self.inputNode.installTap(onBus: 0,
                                      bufferSize: 4096,
                                      format: self.inputNode.outputFormat(forBus: 0)) { buffer, time in
                                        subject.send(buffer)
            }

            self.prepare()
            do {
                try self.start()
            } catch {
                assertionFailure("failed starting recording audio with error: \(error.localizedDescription)")
            }

            return subject
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    func cleanupRecording() {
        inputNode.removeTap(onBus: 0)
        stop()
        reset()
    }
}
