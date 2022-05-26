import XCTest

import M3U8Decoder
//@testable import M3U8Decoder


extension Error {
    var description: String {
        (self as NSError).description
    }
}

// https://datatracker.ietf.org/doc/html/draft-pantos-http-live-streaming-23#section-8
final class M3U8_RFC_Examples: XCTestCase {
    
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

// https://datatracker.ietf.org/doc/html/draft-pantos-http-live-streaming-23#section-8
final class M3U8_All: XCTestCase {
    
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
        let iv: String
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
        let assoc_language: String
        let autoselect: Bool
        let `default`: Bool
        let instream_id: String
        let channels: Int
        let forced: Bool
        let uri: String
        let characteristics: String
    }
    
    struct EXT_X_I_FRAME_STREAM_INF: Decodable {
        let bandwidth: Int
        let average_bandwidth: Int
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
        let hdcp_level: String
        let audio: String
        let video: String
        let subtitles: String
        let closed_captions: String
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
    
    func test_masterPlaylist() {
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
            XCTAssert(playlist.ext_x_media[0].autoselect)
            XCTAssert(playlist.ext_x_media[0].default)
            XCTAssert(playlist.ext_x_media[0].instream_id == "CC1")
            XCTAssert(playlist.ext_x_media[0].channels == 2)
            XCTAssert(playlist.ext_x_media[0].forced)
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

final class M3U8Tests_General: XCTestCase {
    
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
