import XCTest

import M3U8Decoder
//@testable import M3U8Decoder


extension Error {
    var description: String {
        (self as NSError).description
    }
}

// Media Playlist Tags

// #EXT-X-MAP:<attribute-list> - URI, BYTERANGE
struct EXT_X_MAP: Decodable {
    let uri: String
    let byterange: String // <n>[@<o>]
}

// #EXT-X-KEY:<attribute-list> - METHOD, URI, IV, KEYFORMAT, KEYFORMATVERSIONS
struct EXT_X_KEY: Decodable {
    let method: String
    let keyformat: String
    let keyformatversions: Int
    let uri: String
    let iv: String?
}

struct EXT_X_DATERANGE: Decodable {
    let id: String
    let `class`: String
    let start_date: Date
    let end_date: Date
    let duration: Double
    let planned_duration: Double
    let x_com_example_ad_id: String
    let scte35_out: String // SCTE35-CMD, SCTE35-OUT, SCTE35-IN
    let end_on_next: Bool
}

// #EXTINF:<duration>,[<title>]
struct EXTINF: Decodable {
    let duration: Double
    let title: String?
}

// #EXT-X-BYTERANGE:<n>[@<o>]
struct EXT_X_BYTERANGE: Decodable {
    let length: Int
    let start: Int?
}

// Master Playlist Tags

struct EXT_X_SESSION_DATA: Decodable {
    let data_id: String
    let value: String
    let uri: String
    let language: String
}

struct EXT_X_SESSION_KEY: Decodable {
    let method: String
    let keyformat: String
    let keyformatversions: Int
    let uri: String
}

struct EXT_X_START: Decodable {
    let time_offset: Int
    let precise: Bool
}

struct EXT_X_MEDIA: Decodable {
    let type: String
    let group_id: String
    let name: String
    let language: String
    let assoc_language: String?
    let autoselect: Bool?
    let `default`: Bool?
    let instream_id: String?
    let channels: Int?
    let forced: Bool?
    let uri: String?
    let characteristics: String?
}

struct EXT_X_I_FRAME_STREAM_INF: Decodable {
    let bandwidth: Int
    let average_bandwidth: Int?
    let resolution: String
    let codecs: String
    let uri: String
}

struct EXT_X_STREAM_INF: Decodable {
    let bandwidth: Int
    let average_bandwidth: Int
    let codecs: String
    let resolution: String
    let frame_rate: Double
    let hdcp_level: String?
    let audio: String?
    let video: String?
    let subtitles: String?
    let closed_captions: String
}


// https://datatracker.ietf.org/doc/html/draft-pantos-http-live-streaming-23#section-8
final class M3U8_All_Tags: XCTestCase {
    
    struct Playlist: Decodable {
        let extm3u: Bool
        let ext_x_version: Int // #EXT-X-VERSION:<n>
        
        let ext_x_targetduration: Int
        let ext_x_media_sequence: Int
        let ext_x_discontinuity_sequence: Int
        let ext_x_endlist: Bool
        let ext_x_playlist_type: String
        let ext_x_i_frames_only: Bool
        
        let ext_x_key: EXT_X_KEY
        let ext_x_map: EXT_X_MAP
        let ext_x_program_date_time: Date // YYYY-MM-DDThh:mm:ss.SSSZ
        let ext_x_daterange: EXT_X_DATERANGE
        let extinf: [EXTINF]
        let uri: [String]
        let ext_x_byterange: [EXT_X_BYTERANGE]
        let ext_x_discontinuity: Bool
    }
    
    let playlistText = """
    #EXTM3U
    #EXT-X-VERSION:7
    
    #EXT-X-TARGETDURATION:10
    #EXT-X-MEDIA-SEQUENCE:2680
    #EXT-X-DISCONTINUITY-SEQUENCE:0
    #EXT-X-PLAYLIST-TYPE:VOD
    #EXT-X-I-FRAMES-ONLY
    
    #EXT-X-KEY:METHOD=SAMPLE-AES,KEYFORMAT="com.apple.streamingkeydelivery",KEYFORMATVERSIONS="1",URI="skd://p-drmfp-vod.movetv.com/fairplay/d1acadbf70824d178601c2e55675b3b3",IV=0X99b74007b6254e4bd1c6e03631cad15b
    #EXT-X-MAP:URI="main.mp4",BYTERANGE="1118@0"
    
    #EXT-X-PROGRAM-DATE-TIME:2010-02-19T14:54:23.031+08:00
    #EXT-X-DATERANGE:ID="splice-6FFFFFF0",CLASS="com.xyz.dai.adbreak",START-DATE="2014-03-05T11:15:00Z",END-DATE="2014-03-05T11:15:00Z",DURATION=59.993,PLANNED-DURATION=59.993,X-COM-EXAMPLE-AD-ID="XYZ123",SCTE35-OUT=0xFC002F0000000000FF000014056FFFFFF000E011622DCAFF000052636200000000000A0008029896F50000008700000000,END-ON-NEXT=YES
    
    #EXTINF:13.333,Sample artist - Sample title
    #EXT-X-BYTERANGE:1700094@1118
    http://example.com/low.m3u8
    
    #EXT-X-DISCONTINUITY
    
    #EXTINF:8.00000,
    #EXT-X-BYTERANGE:1777588@3490693
    main.mp4
    
    #EXT-X-ENDLIST
    """
    
    func test_playlist() {
        do {
            let playlist = try M3U8Decoder().decode(Playlist.self, text: playlistText)
            print(playlist)
            
            // Basic Tags
            
            XCTAssert(playlist.extm3u)
            XCTAssert(playlist.ext_x_version == 7)
            
            // Media Playlist Tags
            
            XCTAssert(playlist.ext_x_targetduration == 10)
            XCTAssert(playlist.ext_x_media_sequence == 2680)
            XCTAssert(playlist.ext_x_discontinuity_sequence == 0)
            XCTAssert(playlist.ext_x_endlist)
            XCTAssert(playlist.ext_x_playlist_type == "VOD")
            XCTAssert(playlist.ext_x_i_frames_only)
            
            // Media Segment Tags
            
            XCTAssert(playlist.ext_x_key.method == "SAMPLE-AES")
            XCTAssert(playlist.ext_x_key.keyformat == "com.apple.streamingkeydelivery")
            XCTAssert(playlist.ext_x_key.keyformatversions == 1)
            XCTAssert(playlist.ext_x_key.uri == "skd://p-drmfp-vod.movetv.com/fairplay/d1acadbf70824d178601c2e55675b3b3")
            XCTAssert(playlist.ext_x_key.iv == "0X99b74007b6254e4bd1c6e03631cad15b")
            
            XCTAssert(playlist.ext_x_map.uri == "main.mp4")
            XCTAssert(playlist.ext_x_map.byterange == "1118@0")
            
            XCTAssert(playlist.ext_x_program_date_time.description == "2010-02-19 06:54:23 +0000")
            
            XCTAssert(playlist.ext_x_daterange.id == "splice-6FFFFFF0")
            XCTAssert(playlist.ext_x_daterange.class == "com.xyz.dai.adbreak")
            XCTAssert(playlist.ext_x_daterange.start_date.description == "2014-03-05 11:15:00 +0000")
            XCTAssert(playlist.ext_x_daterange.end_date.description == "2014-03-05 11:15:00 +0000")
            XCTAssert(playlist.ext_x_daterange.duration == 59.993)
            XCTAssert(playlist.ext_x_daterange.planned_duration == 59.993)
            XCTAssert(playlist.ext_x_daterange.x_com_example_ad_id == "XYZ123")
            XCTAssert(playlist.ext_x_daterange.scte35_out == "0xFC002F0000000000FF000014056FFFFFF000E011622DCAFF000052636200000000000A0008029896F50000008700000000")
            XCTAssert(playlist.ext_x_daterange.end_on_next)
            
            XCTAssert(playlist.extinf.count == 2)
            XCTAssert(playlist.extinf[0].duration == 13.333)
            XCTAssert(playlist.extinf[0].title == "Sample artist - Sample title")
            
            XCTAssert(playlist.ext_x_byterange.count == 2)
            XCTAssert(playlist.ext_x_byterange[0].length == 1700094)
            XCTAssert(playlist.ext_x_byterange[0].start == 1118)
            
            XCTAssert(playlist.uri.count == 2)
            XCTAssert(playlist.uri[0] == "http://example.com/low.m3u8")
            
            XCTAssert(playlist.ext_x_discontinuity)
        }
        catch {
            XCTFail(error.description)
        }
    }
        
    struct MaterPlaylist: Decodable {
        let extm3u: Bool
        let ext_x_independent_segments: Bool
        let ext_x_start: EXT_X_START
        let ext_x_session_data: EXT_X_SESSION_DATA
        let ext_x_session_key: EXT_X_SESSION_KEY
        let ext_x_media: [EXT_X_MEDIA]
        let ext_x_i_frame_stream_inf: [EXT_X_I_FRAME_STREAM_INF]
        let ext_x_stream_inf: [EXT_X_STREAM_INF]
        let uri: [String]
    }
    
    let masterPlaylistText = """
    #EXTM3U
    #EXT-X-INDEPENDENT-SEGMENTS
    
    #EXT-X-START:TIME-OFFSET=25,PRECISE=YES
    
    #EXT-X-SESSION-DATA:DATA-ID="com.example.title",LANGUAGE="en",VALUE="This is an example",URI="data.json"
    #EXT-X-SESSION-KEY:METHOD=SAMPLE-AES,KEYFORMAT="com.apple.streamingkeydelivery",KEYFORMATVERSIONS="1",URI="skd://p-drmfp-vod.movetv.com/fairplay/d1acadbf70824d178601c2e55675b3b3"
    
    #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac_2_192_cdn_1",NAME="English",LANGUAGE="en",ASSOC-LANGUAGE="fr",CHANNELS="2",INSTREAM-ID="CC1",AUTOSELECT=YES,DEFAULT=YES,FORCED=YES,CHARACTERISTICS="public.accessibility.describes-music-and-sound",URI="sample/audio_7_02_3_fairplay.m3u8"
    
    #EXT-X-I-FRAME-STREAM-INF:AVERAGE-BANDWIDTH=928091,BANDWIDTH=1015727,CODECS="avc1.640028",RESOLUTION=1920x1080,URI="tp5/iframe_index.m3u8"
    
    #EXT-X-STREAM-INF:BANDWIDTH=3679027,AVERAGE-BANDWIDTH=3063808,RESOLUTION=1280x720,FRAME-RATE=23.976,CODECS="avc1.640028,mp4a.40.2",HDCP-LEVEL="TYPE-0",CLOSED-CAPTIONS="cc",AUDIO="aac_2_192_cdn_1",VIDEO="aac_2_192_cdn_1",SUBTITLES="sub1"
    http://example.com/low.m3u8
    """
    
    func test_master() {
        do {
            let playlist = try M3U8Decoder().decode(MaterPlaylist.self, text: masterPlaylistText)
            print(playlist)
            
            XCTAssert(playlist.extm3u)
            XCTAssert(playlist.ext_x_independent_segments)
            
            XCTAssert(playlist.ext_x_start.time_offset == 25)
            XCTAssert(playlist.ext_x_start.precise)
            
            XCTAssert(playlist.ext_x_session_data.data_id == "com.example.title")
            XCTAssert(playlist.ext_x_session_data.value == "This is an example")
            XCTAssert(playlist.ext_x_session_data.uri == "data.json")
            XCTAssert(playlist.ext_x_session_data.language == "en")
            
            XCTAssert(playlist.ext_x_session_key.method == "SAMPLE-AES")
            XCTAssert(playlist.ext_x_session_key.keyformat == "com.apple.streamingkeydelivery")
            XCTAssert(playlist.ext_x_session_key.keyformatversions == 1)
            XCTAssert(playlist.ext_x_session_key.uri == "skd://p-drmfp-vod.movetv.com/fairplay/d1acadbf70824d178601c2e55675b3b3")
            
            XCTAssert(playlist.ext_x_media.count == 1)
            XCTAssert(playlist.ext_x_media[0].type == "AUDIO")
            XCTAssert(playlist.ext_x_media[0].group_id == "aac_2_192_cdn_1")
            XCTAssert(playlist.ext_x_media[0].name == "English")
            XCTAssert(playlist.ext_x_media[0].language == "en")
            XCTAssert(playlist.ext_x_media[0].assoc_language == "fr")
            XCTAssert(playlist.ext_x_media[0].autoselect == true)
            XCTAssert(playlist.ext_x_media[0].default == true)
            XCTAssert(playlist.ext_x_media[0].instream_id == "CC1")
            XCTAssert(playlist.ext_x_media[0].channels == 2)
            XCTAssert(playlist.ext_x_media[0].forced == true)
            XCTAssert(playlist.ext_x_media[0].uri == "sample/audio_7_02_3_fairplay.m3u8")
            XCTAssert(playlist.ext_x_media[0].characteristics == "public.accessibility.describes-music-and-sound")
            
            XCTAssert(playlist.ext_x_i_frame_stream_inf.count == 1)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].bandwidth == 1015727)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].average_bandwidth == 928091)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].resolution == "1920x1080")
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].codecs == "avc1.640028")
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].uri == "tp5/iframe_index.m3u8")
            
            XCTAssert(playlist.ext_x_stream_inf.count == 1)
            XCTAssert(playlist.ext_x_stream_inf[0].bandwidth == 3679027)
            XCTAssert(playlist.ext_x_stream_inf[0].average_bandwidth == 3063808)
            XCTAssert(playlist.ext_x_stream_inf[0].codecs == "avc1.640028,mp4a.40.2")
            XCTAssert(playlist.ext_x_stream_inf[0].resolution == "1280x720")
            XCTAssert(playlist.ext_x_stream_inf[0].frame_rate == 23.976)
            XCTAssert(playlist.ext_x_stream_inf[0].hdcp_level == "TYPE-0")
            XCTAssert(playlist.ext_x_stream_inf[0].audio == "aac_2_192_cdn_1")
            XCTAssert(playlist.ext_x_stream_inf[0].video == "aac_2_192_cdn_1")
            XCTAssert(playlist.ext_x_stream_inf[0].subtitles == "sub1")
            XCTAssert(playlist.ext_x_stream_inf[0].closed_captions == "cc")
            
            XCTAssert(playlist.uri.count == 1)
            XCTAssert(playlist.uri[0] == "http://example.com/low.m3u8")
        }
        catch {
            XCTFail(error.description)
        }
    }
}

final class M3U8Tests_File: XCTestCase {
    
    struct MasterPlaylist: Decodable {
        let extm3u: Bool
        let ext_x_version: Int
        let ext_x_independent_segments: Bool
        let ext_x_session_key: EXT_X_SESSION_KEY
        let ext_x_media: [EXT_X_MEDIA]
        let ext_x_stream_inf: [EXT_X_STREAM_INF]
        let ext_x_i_frame_stream_inf: [EXT_X_I_FRAME_STREAM_INF]
        let uri: [String]
        
        var variantStreams: [(EXT_X_STREAM_INF, String)] {
            Array(zip(ext_x_stream_inf, uri))
        }
    }

    struct MasterPlaylistCamelCase: Decodable {
        let extm3u: Bool
        let extXVersion: Int
        let extXIndependentSegments: Bool
        let extXSessionKey: EXT_X_SESSION_KEY
    }

    struct MasterPlaylistCustomKey: Decodable {
        let m3u: Bool
        let version: Int
        let independent_segments: Bool
        let session_key: EXT_X_SESSION_KEY
    }

    struct VideoPlaylist: Decodable {
        let extm3u: Bool
        let ext_x_version: Int
        let ext_x_targetduration: Int
        let ext_x_playlist_type: String
        let ext_x_key: EXT_X_KEY
        let extinf: [EXTINF]
        let uri: [String]
        let ext_x_endlist: Bool
        
        var mediaSegments: [(EXTINF, String)] {
            Array(zip(extinf, uri))
        }
    }
    
    static let masterPlaylistUrl = Bundle.module.url(forResource: "master_7_3_fairplay", withExtension: "m3u8")!
    static let videoPlaylistUrl = Bundle.module.url(forResource: "video_7_02_3_fairplay", withExtension: "m3u8")!

    func test_master() {
        do {
            let playlist = try M3U8Decoder().decode(MasterPlaylist.self, url: Self.masterPlaylistUrl)
            print(playlist)
            
            XCTAssert(playlist.extm3u)
            XCTAssert(playlist.ext_x_version == 7)
            XCTAssert(playlist.ext_x_independent_segments)
            
            // #EXT-X-SESSION-KEY
            
            XCTAssert(playlist.ext_x_session_key.method == "SAMPLE-AES")
            XCTAssert(playlist.ext_x_session_key.keyformat == "com.apple.streamingkeydelivery")
            XCTAssert(playlist.ext_x_session_key.keyformatversions == 1)
            XCTAssert(playlist.ext_x_session_key.uri == "skd://p-drmfp-vod.movetv.com/fairplay/d1acadbf70824d178601c2e55675b3b3")

            // #EXT-X-MEDIA
            
            XCTAssert(playlist.ext_x_media.count == 5)
            XCTAssert(playlist.ext_x_media[0].type == "CLOSED-CAPTIONS")
            XCTAssert(playlist.ext_x_media[0].group_id == "cc")
            XCTAssert(playlist.ext_x_media[0].name == "CC1")
            XCTAssert(playlist.ext_x_media[0].language == "en")
            XCTAssert(playlist.ext_x_media[0].autoselect == true)
            XCTAssert(playlist.ext_x_media[0].default == true)
            XCTAssert(playlist.ext_x_media[0].instream_id == "CC1")
            
            XCTAssert(playlist.ext_x_media[2].type == "AUDIO")
            XCTAssert(playlist.ext_x_media[2].group_id == "aac_2_192_cdn_1")
            XCTAssert(playlist.ext_x_media[2].name == "English")
            XCTAssert(playlist.ext_x_media[2].language == "en")
            XCTAssert(playlist.ext_x_media[2].channels == 2)
            XCTAssert(playlist.ext_x_media[2].autoselect == true)
            XCTAssert(playlist.ext_x_media[2].default == true)
            XCTAssert(playlist.ext_x_media[2].uri == "sample/audio_7_02_3_fairplay.m3u8")
            
            // #EXT-X-STREAM-INF
            
            XCTAssert(playlist.ext_x_stream_inf.count == 18)
            XCTAssert(playlist.ext_x_stream_inf[0].bandwidth == 3679027)
            XCTAssert(playlist.ext_x_stream_inf[0].average_bandwidth == 3063808)
            XCTAssert(playlist.ext_x_stream_inf[0].resolution == "1280x720")
            XCTAssert(playlist.ext_x_stream_inf[0].frame_rate == 23.976)
            XCTAssert(playlist.ext_x_stream_inf[0].codecs == "avc1.640028,mp4a.40.2")
            XCTAssert(playlist.ext_x_stream_inf[0].closed_captions == "cc")
            XCTAssert(playlist.ext_x_stream_inf[0].audio == "aac_2_192_cdn_1")
            
            XCTAssert(playlist.ext_x_stream_inf[2].bandwidth == 8225587)
            XCTAssert(playlist.ext_x_stream_inf[2].average_bandwidth == 6852608)
            XCTAssert(playlist.ext_x_stream_inf[2].resolution == "1920x1080")
            XCTAssert(playlist.ext_x_stream_inf[2].frame_rate == 23.976)
            XCTAssert(playlist.ext_x_stream_inf[2].codecs == "avc1.640028,mp4a.40.2")
            XCTAssert(playlist.ext_x_stream_inf[2].closed_captions == "cc")
            XCTAssert(playlist.ext_x_stream_inf[2].audio == "aac_2_192_cdn_1")
            
            // URI
            XCTAssert(playlist.uri.count == 18)
            XCTAssert(playlist.uri[0] == "sample/video_7_03_3_fairplay.m3u8")
            XCTAssert(playlist.uri[2] == "sample/video_7_05_3_fairplay.m3u8")
            
            // Variant Streams
            XCTAssert(playlist.variantStreams.count == 18)
            XCTAssert(playlist.variantStreams[0].0.bandwidth == 3679027)
            
            // #EXT-X-I-FRAME-STREAM-INF
            
            XCTAssert(playlist.ext_x_i_frame_stream_inf.count == 1)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].bandwidth == 95828)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].average_bandwidth == nil)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].resolution == "512x288")
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].codecs == "avc1.4d401f")
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].uri == "iframe_00.m3u8")
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

    func test_playlist() {
        do {
            let playlist = try M3U8Decoder().decode(VideoPlaylist.self, url: Self.videoPlaylistUrl)
            print(playlist)
            
            XCTAssert(playlist.extm3u)
            XCTAssert(playlist.ext_x_version == 7)
            XCTAssert(playlist.ext_x_targetduration == 3)
            XCTAssert(playlist.ext_x_playlist_type == "VOD")
            
            // #EXT-X-KEY
            XCTAssert(playlist.ext_x_key.method == "SAMPLE-AES")
            XCTAssert(playlist.ext_x_key.keyformat == "com.apple.streamingkeydelivery")
            XCTAssert(playlist.ext_x_key.keyformatversions == 1)
            XCTAssert(playlist.ext_x_key.uri == "skd://p-drmfp-vod.movetv.com/fairplay/d1acadbf70824d178601c2e55675b3b3")
            XCTAssert(playlist.ext_x_key.iv == nil)
            
            // #EXTINF
            XCTAssert(playlist.extinf.count == 1461)
            XCTAssert(playlist.extinf[0].duration == 2.048)
            XCTAssert(playlist.extinf[0].title == nil)
            
            // URI
            XCTAssert(playlist.uri.count == 1461)
            XCTAssert(playlist.uri[0] == "/22001/vod/dyn/f24d38bc60a411ec88b4005056a5d12f/sample/v0200000001.ts")
            XCTAssert(playlist.uri[2] == "/22001/vod/dyn/f24d38bc60a411ec88b4005056a5d12f/sample/v0200000003.ts")
            
            // Media segments
            XCTAssert(playlist.mediaSegments.count == 1461)
            
            XCTAssert(playlist.ext_x_endlist)
        }
        catch {
            XCTFail(error.description)
        }
    }
}

final class M3U8Tests_URL: XCTestCase {
    
    static let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
    
    struct MasterPlaylist: Decodable {
        let extm3u: Bool
        let ext_x_version: Int
        let ext_x_independent_segments: Bool
        let ext_x_media: [EXT_X_MEDIA]
        let ext_x_stream_inf: [EXT_X_STREAM_INF]
        let ext_x_i_frame_stream_inf: [EXT_X_I_FRAME_STREAM_INF]
        let uri: [String]

        var variantStreams: [(EXT_X_STREAM_INF, String)] {
            Array(zip(ext_x_stream_inf, uri))
        }
    }
    
    func testMasterPlaylist(_ playlist: MasterPlaylist) {
        //print(playlist)
        
        XCTAssert(playlist.extm3u)
        XCTAssert(playlist.ext_x_version == 6)
        XCTAssert(playlist.ext_x_independent_segments)
        
        // #EXT-X-MEDIA
        XCTAssert(playlist.ext_x_media.count == 5)
        XCTAssert(playlist.ext_x_media[3].type == "CLOSED-CAPTIONS")
        XCTAssert(playlist.ext_x_media[3].group_id == "cc1")
        XCTAssert(playlist.ext_x_media[3].language == "en")
        XCTAssert(playlist.ext_x_media[3].name == "English")
        XCTAssert(playlist.ext_x_media[3].autoselect == true)
        XCTAssert(playlist.ext_x_media[3].default == true)
        XCTAssert(playlist.ext_x_media[3].instream_id == "CC1")
        
        // #EXT-X-I-FRAME-STREAM-INF
        XCTAssert(playlist.ext_x_i_frame_stream_inf.count == 6)
        XCTAssert(playlist.ext_x_i_frame_stream_inf[2].average_bandwidth == 97767)
        XCTAssert(playlist.ext_x_i_frame_stream_inf[2].bandwidth == 101378)
        XCTAssert(playlist.ext_x_i_frame_stream_inf[2].codecs == "avc1.640020")
        XCTAssert(playlist.ext_x_i_frame_stream_inf[2].resolution == "960x540")
        XCTAssert(playlist.ext_x_i_frame_stream_inf[2].uri == "v5/iframe_index.m3u8")
        
        // #EXT-X-STREAM-INF
        XCTAssert(playlist.ext_x_stream_inf.count == 24)
        XCTAssert(playlist.ext_x_stream_inf[2].average_bandwidth == 6170000)
        XCTAssert(playlist.ext_x_stream_inf[2].bandwidth == 6312875)
        XCTAssert(playlist.ext_x_stream_inf[2].codecs == "avc1.64002a,mp4a.40.2")
        XCTAssert(playlist.ext_x_stream_inf[2].resolution == "1920x1080")
        XCTAssert(playlist.ext_x_stream_inf[2].frame_rate == 60.000)
        XCTAssert(playlist.ext_x_stream_inf[2].closed_captions == "cc1")
        XCTAssert(playlist.ext_x_stream_inf[2].audio == "aud1")
        XCTAssert(playlist.ext_x_stream_inf[2].subtitles == "sub1")
        
        // URI
        XCTAssert(playlist.uri.count == 24)
        XCTAssert(playlist.uri[2] == "v8/prog_index.m3u8")
        
        XCTAssert(playlist.variantStreams.count == 24)
    }
    
    func test_master_completion() {
        let expectation = self.expectation(description: #function)
        
        M3U8Decoder().decode(MasterPlaylist.self, url: Self.url) { playlist, error in
            guard error == nil else {
                XCTFail(error!.description)
                return
            }
            
            guard let playlist = playlist else {
                XCTFail("No playlist")
                return
            }

            self.testMasterPlaylist(playlist)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func test_master_async() {
        let expectation = self.expectation(description: #function)
        
        Task {
            let playlist = try await M3U8Decoder().decode(MasterPlaylist.self, from: Self.url)
            self.testMasterPlaylist(playlist)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
//    func test_video_url() {
//        do {
//            let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/v5/prog_index.m3u8")!
//            let playlist = try M3U8Decoder().decode(VideoPlaylist.self, url: url)
//            print(playlist)
//        }
//        catch {
//            XCTFail(error.description)
//        }
//    }
}
