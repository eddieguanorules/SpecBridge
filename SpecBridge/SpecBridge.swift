import Foundation
import Combine
import AVFoundation
import HaishinKit
import RTMPHaishinKit
import VideoToolbox

@MainActor
class TwitchManager: ObservableObject {
    // The connection to the Twitch Server
    private var rtmpConnection = RTMPConnection()
    // The stream object that sends the data (Now an Actor in v2.0)
    private var rtmpStream: RTMPStream!
    
    @Published var isBroadcasting = false
    @Published var connectionStatus = "Disconnected"
    
    init() {
        rtmpStream = RTMPStream(connection: rtmpConnection)
    }
    
    func startBroadcast(streamKey: String) async {
        let twitchURL = "rtmp://live.twitch.tv/app"
        connectionStatus = "Connecting..."
        
        do {
            // 1. Configure Video Settings for 720p Vertical (9:16)
            // This prevents the "1x1" or "Landscape" default issue
            let videoSettings = VideoCodecSettings(
                videoSize: .init(width: 720, height: 1280),
                bitRate: 2500 * 1000, // 2.5 Mbps
                profileLevel: kVTProfileLevel_H264_High_3_1 as String,
                scalingMode: .trim,
                maxKeyFrameIntervalDuration: 2, // Twitch standard
                expectedFrameRate: 24
            )
            try await rtmpStream.setVideoSettings(videoSettings)
            
            // 2. Connect
            try await rtmpConnection.connect(twitchURL)
            
            // 3. Publish
            try await rtmpStream.publish(streamKey)
            
            connectionStatus = "Live on Twitch!"
            isBroadcasting = true
        } catch {
            connectionStatus = "Connection Failed: \(error.localizedDescription)"
            isBroadcasting = false
        }
    }
    
    func stopBroadcast() async {
        do {
            try await rtmpConnection.close()
        } catch {
            print("Error closing stream: \(error)")
        }
        isBroadcasting = false
        connectionStatus = "Disconnected"
    }
    
    // FIX: Handles the "Actor-isolated" error
    func processVideoFrame(_ buffer: CMSampleBuffer) {
        // REMOVED: guard isBroadcasting else { return }
        // Why? We must send frames to the stream actor even before we are live.
        // This allows HaishinKit to detect the video format (width/height) from the buffer
        // so that when we do call 'publish', the metadata contains the correct dimensions.
        // If we don't do this, metadata is sent as "0x0" or "1x1".
        
        Task {
            // We use 'try? await' to safely send data to the background streamer
            // If not live, HaishinKit will just update its internal format state without sending data.
            try? await rtmpStream.append(buffer)
        }
    }
}