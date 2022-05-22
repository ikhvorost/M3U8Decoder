import XCTest

import M3U8Decoder
//@testable import M3U8Decoder

// #EXT-X-SESSION-KEY:METHOD=SAMPLE-AES,KEYFORMAT="com.apple.streamingkeydelivery",KEYFORMATVERSIONS="1",URI="skd://p-drmfp-vod.movetv.com/fairplay/d1acadbf70824d178601c2e55675b3b3"
public struct EXT_X_SESSION_KEY: Decodable {
    let METHOD: String
    let KEYFORMAT: String
    let KEYFORMATVERSIONS: Int
    let URI: String
}

// #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac_2_192_cdn_1",NAME="English",LANGUAGE="en",CHANNELS="2",AUTOSELECT=YES,DEFAULT=YES,URI="sample/audio_7_02_3_fairplay.m3u8"
public struct EXT_X_MEDIA: Decodable {
    let TYPE: String
    let GROUP_ID: String
    let NAME: String
    let LANGUAGE: String
    let AUTOSELECT: Bool?
    let DEFAULT: Bool?
    let INSTREAM_ID: String?
    let CHANNELS: Int?
    let URI: String?
}

// #EXT-X-STREAM-INF:BANDWIDTH=3679027,AVERAGE-BANDWIDTH=3063808,RESOLUTION=1280x720,FRAME-RATE=23.976,CODECS="avc1.640028,mp4a.40.2",CLOSED-CAPTIONS="cc",AUDIO="aac_2_192_cdn_1"
public struct EXT_X_STREAM_INF: Decodable {
    let BANDWIDTH: Int
    let AVERAGE_BANDWIDTH: Int
    let RESOLUTION: String
    let FRAME_RATE: Double
    let CODECS: String
    let CLOSED_CAPTIONS: String
    let AUDIO: String
    let URI: String?
}

// #EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=95828,RESOLUTION=512x288,CODECS="avc1.4d401f",URI="iframe_00.m3u8"
public struct EXT_X_I_FRAME_STREAM_INF: Decodable {
    let BANDWIDTH: Int
    let RESOLUTION: String
    let CODECS: String
    let URI: String
}

public struct MasterPlaylist: Decodable {
    let EXTM3U: Bool
    let EXT_X_VERSION: Int
    let EXT_X_INDEPENDENT_SEGMENTS: Bool
    let EXT_X_SESSION_KEY: EXT_X_SESSION_KEY
    let EXT_X_MEDIA: [EXT_X_MEDIA]
    let EXT_X_STREAM_INF: [EXT_X_STREAM_INF]
    let EXT_X_I_FRAME_STREAM_INF: EXT_X_I_FRAME_STREAM_INF
}

// #EXT-X-KEY:METHOD=SAMPLE-AES,KEYFORMAT="com.apple.streamingkeydelivery",KEYFORMATVERSIONS="1",URI="skd://p-drmfp-vod.movetv.com/fairplay/d1acadbf70824d178601c2e55675b3b3"
public struct EXT_X_KEY: Decodable {
    let METHOD: String
    let KEYFORMAT: String
    let KEYFORMATVERSIONS: Int
    let URI: String
}

// #EXTINF:<duration>,[<title>]
// TODO: duration and title
public struct EXTINF: Decodable {
    let URI: String
}

public struct VideoPlaylist: Decodable {
    let EXTM3U: Bool
    let EXT_X_VERSION: Int
    let EXT_X_TARGETDURATION: Int
    let EXT_X_PLAYLIST_TYPE: String
    let EXT_X_KEY: EXT_X_KEY
    let EXTINF: [EXTINF]
    let EXT_X_ENDLIST: Bool
}

final class M3U8Tests: XCTestCase {

    func test_master() {
        guard let url = Bundle.module.url(forResource: "master_7_3_fairplay", withExtension: "m3u8"),
              let data = try? Data(contentsOf: url),
              let playlist = try? M3U8Decoder().decode(MasterPlaylist.self, from: data)
        else {
            XCTFail()
            return
        }

        print(playlist)
    }

    func test_video() {
        guard let url = Bundle.module.url(forResource: "video_7_02_3_fairplay", withExtension: "m3u8"),
              let data = try? Data(contentsOf: url),
              let playlist = try? M3U8Decoder().decode(VideoPlaylist.self, from: data)
        else {
            XCTFail()
            return
        }

        print(playlist)
    }
}
