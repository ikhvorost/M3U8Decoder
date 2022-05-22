import XCTest

import M3U8Decoder
//@testable import M3U8Decoder


extension Error {
    var description: String {
        (self as NSError).description
    }
}

// #EXT-X-SESSION-KEY:METHOD=SAMPLE-AES,KEYFORMAT="com.apple.streamingkeydelivery",KEYFORMATVERSIONS="1",URI="skd://p-drmfp-vod.movetv.com/fairplay/d1acadbf70824d178601c2e55675b3b3"
public struct EXT_X_SESSION_KEY: Decodable {
    let method: String
    let keyformat: String
    let keyformatversions: Int
    let uri: String
}

// #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac_2_192_cdn_1",NAME="English",LANGUAGE="en",CHANNELS="2",AUTOSELECT=YES,DEFAULT=YES,URI="sample/audio_7_02_3_fairplay.m3u8"
public struct EXT_X_MEDIA: Decodable {
    let type: String
    let group_id: String
    let name: String
    let language: String
    let autoselect: Bool?
    let `default`: Bool?
    let instream_id: String?
    let channels: Int?
    let uri: String?
}

// #EXT-X-STREAM-INF:BANDWIDTH=3679027,AVERAGE-BANDWIDTH=3063808,RESOLUTION=1280x720,FRAME-RATE=23.976,CODECS="avc1.640028,mp4a.40.2",CLOSED-CAPTIONS="cc",AUDIO="aac_2_192_cdn_1"
public struct EXT_X_STREAM_INF: Decodable {
    let bandwidth: Int
    let average_bandwidth: Int
    let resolution: String
    let frame_rate: Double
    let codecs: String
    let closed_captions: String
    let audio: String
    let subtitles: String?
    let uri: String?
}

// #EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=95828,RESOLUTION=512x288,CODECS="avc1.4d401f",URI="iframe_00.m3u8"
public struct EXT_X_I_FRAME_STREAM_INF: Decodable {
    let bandwidth: Int
    let average_bandwidth: Int?
    let resolution: String
    let codecs: String
    let uri: String
}

public struct MasterPlaylist: Decodable {
    let extm3u: Bool
    let ext_x_version: Int
    let ext_x_independent_segments: Bool
    let ext_x_session_key: EXT_X_SESSION_KEY?
    let ext_x_media: [EXT_X_MEDIA]
    let ext_x_stream_inf: [EXT_X_STREAM_INF]
    let ext_x_i_frame_stream_inf: EXT_X_I_FRAME_STREAM_INF //[EXT_X_I_FRAME_STREAM_INF]
}

public struct MasterPlaylistCamelCase: Decodable {
    let extm3u: Bool
    let extXVersion: Int
    let extXIndependentSegments: Bool
}

public struct MasterPlaylistCustomKey: Decodable {
    let m3u: Bool
    let version: Int
    let independent_segments: Bool
}

// #EXT-X-KEY:METHOD=SAMPLE-AES,KEYFORMAT="com.apple.streamingkeydelivery",KEYFORMATVERSIONS="1",URI="skd://p-drmfp-vod.movetv.com/fairplay/d1acadbf70824d178601c2e55675b3b3"
public struct EXT_X_KEY: Decodable {
    let method: String
    let keyformat: String
    let keyformatversions: Int
    let uri: String
}

// #EXT-X-MAP:URI="main.mp4",BYTERANGE="1118@0"
public struct EXT_X_MAP: Decodable {
    let uri: String
    let byterange: String
}

// #EXTINF:<duration>,[<title>]
// TODO: duration and title
public struct EXTINF: Decodable {
    let uri: String
}

public struct VideoPlaylist: Decodable {
    let extm3u: Bool
    let ext_x_version: Int
    let ext_x_targetduration: Int
    let ext_x_media_sequence: Int?
    let ext_x_playlist_type: String
    let ext_x_independent_segments: Bool?
    let ext_x_map: EXT_X_MAP?
    let ext_x_key: EXT_X_KEY?
    //let extinf: [EXTINF]
    let ext_x_endlist: Bool
}

final class M3U8Tests: XCTestCase {
    
    static let masterPlaylistUrl = Bundle.module.url(forResource: "master_7_3_fairplay", withExtension: "m3u8")!

    func test_master() {
        do {
            let playlist = try M3U8Decoder().decode(MasterPlaylist.self, url: Self.masterPlaylistUrl)
            print(playlist)
        }
        catch {
            XCTFail(error.description)
        }
    }
    
    func test_master_camelCase() {
        do {
            let decoder = M3U8Decoder()
            decoder.keyDecodingStrategy = .camelCase
            let playlist = try decoder.decode(MasterPlaylistCamelCase.self, url: Self.masterPlaylistUrl)
            print(playlist)
        }
        catch {
            XCTFail(error.description)
        }
    }
    
    func test_master_customKey() {
        do {
            let decoder = M3U8Decoder()
            decoder.keyDecodingStrategy = .custom { key in
                return key
                    .lowercased()
                    .replacingOccurrences(of: "ext", with: "")
                    .replacingOccurrences(of: "-x-", with: "")
                    .replacingOccurrences(of: "-", with: "_")
            }
            let playlist = try decoder.decode(MasterPlaylistCustomKey.self, url: Self.masterPlaylistUrl)
            print(playlist)
        }
        catch {
            XCTFail(error.description)
        }
    }

    func test_video() {
        guard let url = Bundle.module.url(forResource: "video_7_02_3_fairplay", withExtension: "m3u8") else {
            XCTFail()
            return
        }
        
        do {
            let playlist = try M3U8Decoder().decode(VideoPlaylist.self, url: url)
            print(playlist)
        }
        catch {
            XCTFail(error.description)
        }
    }
    
    func test_master_url() {
        do {
            let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
            let playlist = try M3U8Decoder().decode(MasterPlaylist.self, url: url)
            print(playlist)
        }
        catch {
            XCTFail(error.description)
        }
    }
    
    func test_video_url() {
        do {
            let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/v5/prog_index.m3u8")!
            let playlist = try M3U8Decoder().decode(VideoPlaylist.self, url: url)
            print(playlist)
        }
        catch {
            XCTFail(error.description)
        }
    }
}
