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

// https://datatracker.ietf.org/doc/html/draft-pantos-http-live-streaming-23#section-8
final class M3U8_PlaylistExamples: XCTestCase {
    
    // #EXT-X-KEY:METHOD=AES-128,URI="https://priv.example.com/key.php?r=52"
    struct EXT_X_KEY: Decodable {
        let method: String
        let uri: String
    }
    
    // #EXTINF:13.333,Sample artist - Sample title
    struct EXTINF: Decodable {
        let duration: Double
        let title: String?
        let uri: String
    }
    
    // #EXT-X-DATERANGE:ID="splice-6FFFFFF0",DURATION=59.993,SCTE35-IN=0xFC002A0000000000FF00000F056FFFFFF000401162802E6100000000000A0008029896F50000008700000000
    struct EXT_X_DATERANGE: Decodable {
        let id: String
        let start_date: Date
        let planned_duration: Double
        let scte35_out: String
    }
    
    struct Playlist: Decodable {
        let extm3u: Bool
        let ext_x_targetduration: Int
        let ext_x_version: Int
        let ext_x_media_sequence: Int
        let ext_x_key: EXT_X_KEY
        let ext_x_daterange: EXT_X_DATERANGE
        let extinf: [EXTINF]
        let ext_x_endlist: Bool
    }
    
    let playlistText = """
    #EXTM3U
    #EXT-X-TARGETDURATION:10
    #EXT-X-VERSION:3
    #EXT-X-MEDIA-SEQUENCE:2680
    
    #EXT-X-KEY:METHOD=AES-128,URI="https://priv.example.com/key.php?r=52"
    #EXT-X-DATERANGE:ID="splice-6FFFFFF0",START-DATE="2014-03-05T11:15:00Z",PLANNED-DURATION=59.993,SCTE35-OUT=0xFC002F0000000000FF000014056FFFFFF000E011622DCAFF000052636200000000000A0008029896F50000008700000000
    
    #EXTINF:9.009,
    http://media.example.com/first.ts
    #EXTINF:13.333,Sample artist - Sample title
    http://media.example.com/second.ts
    #EXTINF:3.003,
    http://media.example.com/third.ts
    
    #EXT-X-ENDLIST
    """
    
    func test_playlist() {
        do {
            let playlist = try M3U8Decoder().decode(Playlist.self, text: playlistText)
            print(playlist)
            
            XCTAssert(playlist.extm3u)
            XCTAssert(playlist.ext_x_targetduration == 10)
            XCTAssert(playlist.ext_x_version == 3)
            XCTAssert(playlist.ext_x_media_sequence == 2680)
            
            XCTAssert(playlist.ext_x_key.method == "AES-128")
            XCTAssert(playlist.ext_x_key.uri == "https://priv.example.com/key.php?r=52")
            
            XCTAssert(playlist.ext_x_daterange.id == "splice-6FFFFFF0")
            XCTAssert(playlist.ext_x_daterange.start_date.description == "2014-03-05 11:15:00 +0000")
            XCTAssert(playlist.ext_x_daterange.planned_duration == 59.993)
            XCTAssert(playlist.ext_x_daterange.scte35_out == "0xFC002F0000000000FF000014056FFFFFF000E011622DCAFF000052636200000000000A0008029896F50000008700000000")
            
            XCTAssert(playlist.extinf.count == 3)
            XCTAssert(playlist.extinf[0].duration == 9.009)
            XCTAssert(playlist.extinf[0].title == nil)
            XCTAssert(playlist.extinf[0].uri == "http://media.example.com/first.ts")
            XCTAssert(playlist.extinf[1].title == "Sample artist - Sample title")
            
            XCTAssert(playlist.ext_x_endlist)
        }
        catch {
            XCTFail(error.description)
        }
    }
    
    // #EXT-X-SESSION-DATA:DATA-ID="com.example.title",LANGUAGE="en",VALUE="This is an example"
    struct EXT_X_SESSION_DATA: Decodable {
        let data_id: String
        let language: String
        let value: String
    }
    
    //#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac",NAME="English",DEFAULT=YES,AUTOSELECT=YES,LANGUAGE="en",URI="main/english-audio.m3u8"
    struct EXT_X_MEDIA: Decodable {
        let type: String
        let group_id: String
        let name: String
        let `default`: Bool
        let autoselect: Bool
        let language: String
        let uri: String
    }
    
    // #EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=86000,URI="low/iframe.m3u8"
    struct EXT_X_I_FRAME_STREAM_INF: Decodable {
        let bandwidth: Int
        let uri: String
    }
    
    // #EXT-X-STREAM-INF:BANDWIDTH=1280000,AVERAGE-BANDWIDTH=1000000
    struct EXT_X_STREAM_INF: Decodable {
        let bandwidth: Int
        let average_bandwidth: Int?
        let codecs: String?
        let audio: String
        let uri: String?
    }
    
    struct MasterPlaylist: Decodable {
        let extm3u: Bool
        let ext_x_session_data: EXT_X_SESSION_DATA
        let ext_x_media: [EXT_X_MEDIA]
        let ext_x_stream_inf: [EXT_X_STREAM_INF]
        let ext_x_i_frame_stream_inf: EXT_X_I_FRAME_STREAM_INF
    }
    
    let masterPlaylistText = """
    #EXTM3U
    
    #EXT-X-SESSION-DATA:DATA-ID="com.example.title",LANGUAGE="en",VALUE="This is an example"
    
    #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac",NAME="English",DEFAULT=YES,AUTOSELECT=YES,LANGUAGE="en",URI="main/english-audio.m3u8"
    #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac",NAME="Deutsch",DEFAULT=NO,AUTOSELECT=YES,LANGUAGE="de",URI="main/german-audio.m3u8"
    #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac",NAME="Commentary",DEFAULT=NO,AUTOSELECT=NO,LANGUAGE="en",URI="commentary/audio-only.m3u8"
    
    #EXT-X-STREAM-INF:BANDWIDTH=1280000,AVERAGE-BANDWIDTH=1000000,AUDIO="aac"
    http://example.com/low.m3u8
    
    #EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=86000,URI="low/iframe.m3u8"
    
    #EXT-X-STREAM-INF:BANDWIDTH=2560000,AVERAGE-BANDWIDTH=2000000,AUDIO="aac"
    http://example.com/mid.m3u8
    #EXT-X-STREAM-INF:BANDWIDTH=7680000,AVERAGE-BANDWIDTH=6000000,AUDIO="aac"
    http://example.com/hi.m3u8
    #EXT-X-STREAM-INF:BANDWIDTH=65000,CODECS="mp4a.40.5",AUDIO="aac"
    http://example.com/audio-only.m3u8
    """
    
    func test_masterPlaylist() {
        do {
            let playlist = try M3U8Decoder().decode(MasterPlaylist.self, text: masterPlaylistText)
            print(playlist)
            
            XCTAssert(playlist.extm3u)
            
            XCTAssert(playlist.ext_x_session_data.data_id == "com.example.title")
            XCTAssert(playlist.ext_x_session_data.language == "en")
            XCTAssert(playlist.ext_x_session_data.value == "This is an example")
            
            XCTAssert(playlist.ext_x_media.count == 3)
            XCTAssert(playlist.ext_x_media[0].type == "AUDIO")
            XCTAssert(playlist.ext_x_media[0].group_id == "aac")
            XCTAssert(playlist.ext_x_media[0].name == "English")
            XCTAssert(playlist.ext_x_media[0].default)
            XCTAssert(playlist.ext_x_media[0].autoselect)
            XCTAssert(playlist.ext_x_media[0].language == "en")
            XCTAssert(playlist.ext_x_media[0].uri == "main/english-audio.m3u8")
            
            XCTAssert(playlist.ext_x_stream_inf.count == 4)
            XCTAssert(playlist.ext_x_stream_inf[0].bandwidth == 1280000)
            XCTAssert(playlist.ext_x_stream_inf[0].average_bandwidth == 1000000)
            XCTAssert(playlist.ext_x_stream_inf[0].uri == "http://example.com/low.m3u8")
            XCTAssert(playlist.ext_x_stream_inf[0].audio == "aac")
            XCTAssert(playlist.ext_x_stream_inf[3].codecs == "mp4a.40.5")
            
            XCTAssert(playlist.ext_x_i_frame_stream_inf.bandwidth == 86000)
            XCTAssert(playlist.ext_x_i_frame_stream_inf.uri == "low/iframe.m3u8")
        }
        catch {
            XCTFail(error.description)
        }
    }
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
