import XCTest
import Combine
import M3U8Decoder
//@testable import M3U8Decoder


extension Error {
    var description: String {
        (self as NSError).description
    }
}

extension XCTestCase {
    func wait(_f: String = #function, _ body: (XCTestExpectation) -> Void)  {
        let expectation = expectation(description: #function)
        body(expectation)
        waitForExpectations(timeout: 3)
    }
}

// https://datatracker.ietf.org/doc/html/draft-pantos-http-live-streaming-23#section-8
final class M3U8_All: XCTestCase {
    
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
    #EXT-X-BYTERANGE:1777588
    main.mp4
    
    #EXTINF:10
    next.mp4
    
    #EXT-X-ENDLIST
    """
    
    func test_error_baddata() {
        do {
            _ = try M3U8Decoder().decode(Playlist.self, from: "")
            XCTFail()
        }
        catch {
            XCTAssert(error.localizedDescription == "Bad data.")
        }
        
        do {
            _ = try M3U8Decoder().decode(Playlist.self, from: Data([255]))
            XCTFail()
        }
        catch {
            XCTAssert(error.localizedDescription == "Bad data.")
        }
        
        do {
            let text = """
            # coment 1
            # coment 2
            """
            _ = try M3U8Decoder().decode(Playlist.self, from: text)
            XCTFail()
        }
        catch {
            XCTAssert(error.localizedDescription == "Bad data.")
        }
        
        do {
            let text = """
            #EXT-X-PROGRAM-DATE-TIME:2010-02-19
            """
            
            struct BadPlaylist: Decodable {
                let ext_x_program_date_time: Date // YYYY-MM-DDThh:mm:ss.SSSZ
            }
            _ = try M3U8Decoder().decode(BadPlaylist.self, from: text)
            XCTFail()
        }
        catch {
            XCTAssert(error.localizedDescription == "The data couldn’t be read because it isn’t in the correct format.")
        }
    }
    
    func test_double_attributes() {
        struct Playlist: Decodable {
            let ext_x_map: EXT_X_MAP
        }
        
        let m3u8 = """
        #EXTM3U
        #EXT-X-VERSION:7
        #EXT-X-MAP:URI="main1.mp4",BYTERANGE="1118@0",URI="main2.mp4"
        """
        
        do {
            let playlist = try M3U8Decoder().decode(Playlist.self, from: m3u8)
            
            XCTAssert(playlist.ext_x_map.byterange?.length == 1118)
            XCTAssert(playlist.ext_x_map.byterange?.start == 0)
            XCTAssert(playlist.ext_x_map.uri == "main2.mp4")
        }
        catch {
            XCTFail(error.description)
        }
    }
    
    func test_custom() {
        let m3u8 = """
        #EXTM3U
        #EXT-CUSTOM-TAG1:1
        #EXT-CUSTOM-TAG2:VALUE1=1,VALUE2="Text",VALUE3=""
        #EXT-CUSTOM-ARRAY:1
        #EXT-CUSTOM-ARRAY:2
        #EXT-CUSTOM-ARRAY:3
        
        #EXTINF:10,title="Dark Horse",artist="Katy Perry / Juicy J",song_spot=\"M\" MediaBaseId=\"1971116\" itunesTrackId=\"0\" amgTrackId=\"-1\" amgArtistId=\"0\" TAID=\"35141\" TPID=\"23894643\" cartcutId=\"0729388001\" amgArtworkURL=\"http://assets.iheart.com/images/1080/MI0003667474\" length=\"00:03:32\" unsID=\"-1\"
        main.mp4
        """
        
        struct CustomAttributes: Decodable {
            let value1: Int
            let value2: String
            let value3: String
        }
        
        struct CustomExtInf: Decodable {
            let duration: Double
            let title: String
            let artist: String
            let song_spot: String
            let mediabaseid: String
            let itunestrackid: String
            let amgtrackid: String
            let amgartistid: String
            let taid: String
            let tpid: String
            let cartcutid: String
            let amgartworkurl: String
            let length: String
            let unsid: String
        }
        
        struct CustomPlaylist: Decodable {
            let ext_custom_tag1: Int
            let ext_custom_tag2: CustomAttributes
            let ext_custom_array: [Int]
            let extinf: [CustomExtInf]
        }
        
        do {
            let playlist = try M3U8Decoder().decode(CustomPlaylist.self, from: m3u8)
            
            XCTAssert(playlist.ext_custom_tag1 == 1)
            XCTAssert(playlist.ext_custom_tag2.value1 == 1)
            XCTAssert(playlist.ext_custom_tag2.value2 == "Text")
            XCTAssert(playlist.ext_custom_tag2.value3 == "")
            XCTAssert(playlist.ext_custom_array.count == 3)
            XCTAssert(playlist.ext_custom_array == [1, 2, 3])
            
            // EXTINF
            XCTAssert(playlist.extinf[0].duration == 10)
            XCTAssert(playlist.extinf[0].title == "Dark Horse")
            XCTAssert(playlist.extinf[0].artist == "Katy Perry / Juicy J")
            XCTAssert(playlist.extinf[0].song_spot == "M")
            XCTAssert(playlist.extinf[0].mediabaseid == "1971116")
            XCTAssert(playlist.extinf[0].itunestrackid == "0")
            XCTAssert(playlist.extinf[0].amgtrackid == "-1")
            XCTAssert(playlist.extinf[0].amgartistid == "0")
            XCTAssert(playlist.extinf[0].taid == "35141")
            XCTAssert(playlist.extinf[0].tpid == "23894643")
            XCTAssert(playlist.extinf[0].cartcutid == "0729388001")
            XCTAssert(playlist.extinf[0].amgartworkurl == "http://assets.iheart.com/images/1080/MI0003667474")
            XCTAssert(playlist.extinf[0].length == "00:03:32")
            XCTAssert(playlist.extinf[0].unsid == "-1")
        }
        catch {
            XCTFail(error.description)
        }
    }
    
    func test_playlist() {
        do {
            let playlist = try M3U8Decoder().decode(Playlist.self, from: playlistText)
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
            XCTAssert(playlist.ext_x_key.keyformatversions == "1")
            XCTAssert(playlist.ext_x_key.uri == "skd://p-drmfp-vod.movetv.com/fairplay/d1acadbf70824d178601c2e55675b3b3")
            XCTAssert(playlist.ext_x_key.iv == "0X99b74007b6254e4bd1c6e03631cad15b")
            
            XCTAssert(playlist.ext_x_map.uri == "main.mp4")
            XCTAssert(playlist.ext_x_map.byterange?.length == 1118)
            XCTAssert(playlist.ext_x_map.byterange?.start == 0)
            
            XCTAssert(playlist.ext_x_program_date_time.description == "2010-02-19 06:54:23 +0000")
            
            XCTAssert(playlist.ext_x_daterange.id == "splice-6FFFFFF0")
            XCTAssert(playlist.ext_x_daterange.class == "com.xyz.dai.adbreak")
            XCTAssert(playlist.ext_x_daterange.start_date.description == "2014-03-05 11:15:00 +0000")
            XCTAssert(playlist.ext_x_daterange.end_date?.description == "2014-03-05 11:15:00 +0000")
            XCTAssert(playlist.ext_x_daterange.duration == 59.993)
            XCTAssert(playlist.ext_x_daterange.planned_duration == 59.993)
            //XCTAssert(playlist.ext_x_daterange.x_com_example_ad_id == "XYZ123")
            XCTAssert(playlist.ext_x_daterange.scte35_out == "0xFC002F0000000000FF000014056FFFFFF000E011622DCAFF000052636200000000000A0008029896F50000008700000000")
            XCTAssert(playlist.ext_x_daterange.end_on_next == true)
            
            XCTAssert(playlist.extinf.count == 3)
            XCTAssert(playlist.extinf[0].duration == 13.333)
            XCTAssert(playlist.extinf[0].title == "Sample artist - Sample title")
            XCTAssert(playlist.extinf[1].duration == 8.0)
            XCTAssert(playlist.extinf[1].title == nil)
            XCTAssert(playlist.extinf[2].duration == 10.0)
            XCTAssert(playlist.extinf[2].title == nil)
            
            XCTAssert(playlist.ext_x_byterange.count == 2)
            XCTAssert(playlist.ext_x_byterange[0].length == 1700094)
            XCTAssert(playlist.ext_x_byterange[0].start == 1118)
            XCTAssert(playlist.ext_x_byterange[1].length == 1777588)
            XCTAssert(playlist.ext_x_byterange[1].start == nil)
            
            XCTAssert(playlist.uri.count == 3)
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
        let ext_x_session_key: EXT_X_KEY
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
            let playlist = try M3U8Decoder().decode(MaterPlaylist.self, from: masterPlaylistText)
            print(playlist)
            
            XCTAssert(playlist.extm3u)
            XCTAssert(playlist.ext_x_independent_segments)
            
            XCTAssert(playlist.ext_x_start.time_offset == 25)
            XCTAssert(playlist.ext_x_start.precise == true)
            
            XCTAssert(playlist.ext_x_session_data.data_id == "com.example.title")
            XCTAssert(playlist.ext_x_session_data.value == "This is an example")
            XCTAssert(playlist.ext_x_session_data.uri == "data.json")
            XCTAssert(playlist.ext_x_session_data.language == "en")
            
            XCTAssert(playlist.ext_x_session_key.method == "SAMPLE-AES")
            XCTAssert(playlist.ext_x_session_key.keyformat == "com.apple.streamingkeydelivery")
            XCTAssert(playlist.ext_x_session_key.keyformatversions == "1")
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
            XCTAssert(playlist.ext_x_media[0].channels == "2")
            XCTAssert(playlist.ext_x_media[0].forced == true)
            XCTAssert(playlist.ext_x_media[0].uri == "sample/audio_7_02_3_fairplay.m3u8")
            XCTAssert(playlist.ext_x_media[0].characteristics == "public.accessibility.describes-music-and-sound")
            
            XCTAssert(playlist.ext_x_i_frame_stream_inf.count == 1)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].bandwidth == 1015727)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].average_bandwidth == 928091)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].resolution?.width == 1920)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].resolution?.height == 1080)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].codecs.count == 1)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].codecs[0] == "avc1.640028")
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].uri == "tp5/iframe_index.m3u8")
            
            XCTAssert(playlist.ext_x_stream_inf.count == 1)
            XCTAssert(playlist.ext_x_stream_inf[0].bandwidth == 3679027)
            XCTAssert(playlist.ext_x_stream_inf[0].average_bandwidth == 3063808)
            XCTAssert(playlist.ext_x_stream_inf[0].codecs.count == 2)
            XCTAssert(playlist.ext_x_stream_inf[0].codecs[0] == "avc1.640028")
            XCTAssert(playlist.ext_x_stream_inf[0].codecs[1] == "mp4a.40.2")
            XCTAssert(playlist.ext_x_stream_inf[0].resolution?.width == 1280)
            XCTAssert(playlist.ext_x_stream_inf[0].resolution?.height == 720)
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
        let ext_x_session_key: EXT_X_KEY
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
        let extXSessionKey: EXT_X_KEY
    }

    struct MasterPlaylistCustomKey: Decodable {
        let m3u: Bool
        let version: Int
        let independent_segments: Bool
        let session_key: EXT_X_KEY
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
            let playlist = try M3U8Decoder().decode(MasterPlaylist.self, from: Self.masterPlaylistUrl)
            print(playlist)
            
            XCTAssert(playlist.extm3u)
            XCTAssert(playlist.ext_x_version == 7)
            XCTAssert(playlist.ext_x_independent_segments)
            
            // #EXT-X-SESSION-KEY
            
            XCTAssert(playlist.ext_x_session_key.method == "SAMPLE-AES")
            XCTAssert(playlist.ext_x_session_key.keyformat == "com.apple.streamingkeydelivery")
            XCTAssert(playlist.ext_x_session_key.keyformatversions == "1")
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
            XCTAssert(playlist.ext_x_media[2].channels == "2")
            XCTAssert(playlist.ext_x_media[2].autoselect == true)
            XCTAssert(playlist.ext_x_media[2].default == true)
            XCTAssert(playlist.ext_x_media[2].uri == "sample/audio_7_02_3_fairplay.m3u8")
            
            // #EXT-X-STREAM-INF
            
            XCTAssert(playlist.ext_x_stream_inf.count == 18)
            XCTAssert(playlist.ext_x_stream_inf[0].bandwidth == 3679027)
            XCTAssert(playlist.ext_x_stream_inf[0].average_bandwidth == 3063808)
            XCTAssert(playlist.ext_x_stream_inf[0].resolution?.width == 1280)
            XCTAssert(playlist.ext_x_stream_inf[0].resolution?.height == 720)
            XCTAssert(playlist.ext_x_stream_inf[0].frame_rate == 23.976)
            XCTAssert(playlist.ext_x_stream_inf[0].codecs.count == 2)
            XCTAssert(playlist.ext_x_stream_inf[0].codecs[0] == "avc1.640028")
            XCTAssert(playlist.ext_x_stream_inf[0].codecs[1] == "mp4a.40.2")
            XCTAssert(playlist.ext_x_stream_inf[0].closed_captions == "cc")
            XCTAssert(playlist.ext_x_stream_inf[0].audio == "aac_2_192_cdn_1")
            
            XCTAssert(playlist.ext_x_stream_inf[2].bandwidth == 8225587)
            XCTAssert(playlist.ext_x_stream_inf[2].average_bandwidth == 6852608)
            XCTAssert(playlist.ext_x_stream_inf[2].resolution?.width == 1920)
            XCTAssert(playlist.ext_x_stream_inf[2].resolution?.height == 1080)
            XCTAssert(playlist.ext_x_stream_inf[2].frame_rate == 23.976)
            XCTAssert(playlist.ext_x_stream_inf[2].codecs.count == 2)
            XCTAssert(playlist.ext_x_stream_inf[2].codecs[0] == "avc1.640028")
            XCTAssert(playlist.ext_x_stream_inf[2].codecs[1] == "mp4a.40.2")
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
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].resolution?.width == 512)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].resolution?.height == 288)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].codecs.count == 1)
            XCTAssert(playlist.ext_x_i_frame_stream_inf[0].codecs[0] == "avc1.4d401f")
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
            let playlist = try decoder.decode(MasterPlaylistCamelCase.self, from: Self.masterPlaylistUrl)
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
            let playlist = try decoder.decode(MasterPlaylistCustomKey.self, from: Self.masterPlaylistUrl)
            print(playlist)
        }
        catch {
            XCTFail(error.description)
        }
    }

    func test_playlist() {
        do {
            let playlist = try M3U8Decoder().decode(VideoPlaylist.self, from: Self.videoPlaylistUrl)
            print(playlist)
            
            XCTAssert(playlist.extm3u)
            XCTAssert(playlist.ext_x_version == 7)
            XCTAssert(playlist.ext_x_targetduration == 3)
            XCTAssert(playlist.ext_x_playlist_type == "VOD")
            
            // #EXT-X-KEY
            XCTAssert(playlist.ext_x_key.method == "SAMPLE-AES")
            XCTAssert(playlist.ext_x_key.keyformat == "com.apple.streamingkeydelivery")
            XCTAssert(playlist.ext_x_key.keyformatversions == "1")
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
    
    static let bipbopURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
    
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
        XCTAssert(playlist.ext_x_i_frame_stream_inf[2].codecs.count == 1)
        XCTAssert(playlist.ext_x_i_frame_stream_inf[2].codecs[0] == "avc1.640020")
        XCTAssert(playlist.ext_x_i_frame_stream_inf[2].resolution?.width == 960)
        XCTAssert(playlist.ext_x_i_frame_stream_inf[2].resolution?.height == 540)
        XCTAssert(playlist.ext_x_i_frame_stream_inf[2].uri == "v5/iframe_index.m3u8")
        
        // #EXT-X-STREAM-INF
        XCTAssert(playlist.ext_x_stream_inf.count == 24)
        XCTAssert(playlist.ext_x_stream_inf[2].average_bandwidth == 6170000)
        XCTAssert(playlist.ext_x_stream_inf[2].bandwidth == 6312875)
        XCTAssert(playlist.ext_x_stream_inf[2].codecs.count == 2)
        XCTAssert(playlist.ext_x_stream_inf[2].codecs[0] == "avc1.64002a")
        XCTAssert(playlist.ext_x_stream_inf[2].codecs[1] == "mp4a.40.2")
        XCTAssert(playlist.ext_x_stream_inf[2].resolution?.width == 1920)
        XCTAssert(playlist.ext_x_stream_inf[2].resolution?.height == 1080)
        XCTAssert(playlist.ext_x_stream_inf[2].frame_rate == 60.000)
        XCTAssert(playlist.ext_x_stream_inf[2].closed_captions == "cc1")
        XCTAssert(playlist.ext_x_stream_inf[2].audio == "aud1")
        XCTAssert(playlist.ext_x_stream_inf[2].subtitles == "sub1")
        
        // URI
        XCTAssert(playlist.uri.count == 24)
        XCTAssert(playlist.uri[2] == "v8/prog_index.m3u8")
        
        XCTAssert(playlist.variantStreams.count == 24)
    }
    
    func test_url_error() {
        wait { expectation in
            M3U8Decoder().decode(MasterPlaylist.self, from: URL(string: "https://somedomain.com/playlist.m3u8")!) { result in
                if case let .failure(error) = result {
                    XCTAssert(error.localizedDescription.hasPrefix("The certificate for this server is invalid.") == true)
                    expectation.fulfill()
                }
            }
        }
    }
    
    func test_url_error_404() {
        wait { expectation in
            M3U8Decoder().decode(MasterPlaylist.self, from: URL(string: "https://google.com/playlist.m3u8")!) { result in
                if case let .failure(error) = result {
                    XCTAssert(error.localizedDescription.hasPrefix("The operation couldn’t be completed.") == true)
                    expectation.fulfill()
                }
            }
        }
    }
    
    func test_url_error_baddata() {
        wait { expectation in
            M3U8Decoder().decode(MasterPlaylist.self, from: URL(string: "https://google.com")!) { result in
                if case let .failure(error) = result {
                    XCTAssert(error.localizedDescription == "Bad data.")
                    expectation.fulfill()
                }
            }
        }
    }
    
    func test_url_error_async() {
        wait { expectation in
            Task {
                do {
                    let _ = try await M3U8Decoder().decode(MasterPlaylist.self, from: URL(string: "https://google.com/playlist.m3u8")!)
                }
                catch {
                    XCTAssert(error.localizedDescription.hasPrefix("The operation couldn’t be completed.") == true)
                    expectation.fulfill()
                }
            }
        }
    }
    
    func test_master_completion() {
        wait { expectation in
            M3U8Decoder().decode(MasterPlaylist.self, from: Self.bipbopURL) { result in
                if case let .success(playlist) = result {
                    self.testMasterPlaylist(playlist)
                    expectation.fulfill()
                }
            }
        }
    }
    
    func test_master_async() {
        wait { expectation in
            Task {
                do {
                    let playlist = try await M3U8Decoder().decode(MasterPlaylist.self, from: Self.bipbopURL)
                    self.testMasterPlaylist(playlist)
                    expectation.fulfill()
                }
                catch {
                    XCTFail(error.description)
                }
            }
        }
    }
    
    var cancellable: Cancellable?
    
    // https://developer.apple.com/documentation/foundation/urlsession/processing_url_session_data_task_results_with_combine
    func test_master_combine() {
        wait { expectation in
            cancellable = URLSession.shared.dataTaskPublisher(for: Self.bipbopURL)
                .map(\.data)
                .decode(type: MasterPlaylist.self, decoder: M3U8Decoder())
                .sink (
                    receiveCompletion: { print($0) },
                    receiveValue: { playlist in
                        self.testMasterPlaylist(playlist)
                        expectation.fulfill()
                    }
                )
        }
    }
    
    struct VideoPlaylist: Decodable {
        let extm3u: Bool
        let ext_x_targetduration: Int
        let ext_x_version: Int
        let ext_x_media_sequence: Int
        let ext_x_playlist_type: String
        let ext_x_independent_segments: Bool
        let ext_x_map: EXT_X_MAP
        let extinf: [EXTINF]
        let ext_x_byterange: [EXT_X_BYTERANGE]
        let uri: [String]
        let ext_x_endlist: Bool

        typealias MediaSegment = (inf: EXTINF, byterange: EXT_X_BYTERANGE, uri: String)
        var mediaSegments: [MediaSegment] {
            var items = [MediaSegment]()
            for (inf, (byterange, uri)) in zip(extinf, zip(ext_x_byterange, uri)) {
                items.append((inf, byterange, uri))
            }
            return items
        }
    }
    
    func test_video_variant() {
        wait { expectation in
            Task {
                do {
                    let masterPlaylist = try await M3U8Decoder().decode(MasterPlaylist.self, from: Self.bipbopURL)
                    
                    guard let uri = masterPlaylist.uri.first else {
                        throw  "No video variant"
                    }
                    
                    let url = Self.bipbopURL.deletingLastPathComponent().appendingPathComponent(uri)
                    let videoPlaylist = try await M3U8Decoder().decode(VideoPlaylist.self, from: url)
                    
                    XCTAssert(videoPlaylist.extm3u)
                    XCTAssert(videoPlaylist.ext_x_version == 7)
                    
                    XCTAssert(videoPlaylist.extm3u)
                    XCTAssert(videoPlaylist.ext_x_targetduration == 6)
                    XCTAssert(videoPlaylist.ext_x_version == 7)
                    XCTAssert(videoPlaylist.ext_x_media_sequence == 1)
                    XCTAssert(videoPlaylist.ext_x_playlist_type == "VOD")
                    XCTAssert(videoPlaylist.ext_x_independent_segments)
                    
                    XCTAssert(videoPlaylist.ext_x_map.uri == "main.mp4")
                    XCTAssert(videoPlaylist.ext_x_map.byterange?.length == 719)
                    XCTAssert(videoPlaylist.ext_x_map.byterange?.start == 0)
                    
                    XCTAssert(videoPlaylist.extinf.count == 100)
                    XCTAssert(videoPlaylist.extinf[0].duration == 6.00000)
                    
                    XCTAssert(videoPlaylist.ext_x_byterange.count == 100)
                    XCTAssert(videoPlaylist.ext_x_byterange[0].length == 1508000)
                    XCTAssert(videoPlaylist.ext_x_byterange[0].start == 719)
                    
                    XCTAssert(videoPlaylist.uri.count == 100)
                    XCTAssert(videoPlaylist.uri[0] == "main.mp4")
                    
                    XCTAssert(videoPlaylist.mediaSegments.count == 100)
                    XCTAssert(videoPlaylist.mediaSegments[0].inf.duration == 6.00000)
                    XCTAssert(videoPlaylist.mediaSegments[0].byterange.length == 1508000)
                    XCTAssert(videoPlaylist.mediaSegments[0].uri == "main.mp4")
                    
                    XCTAssert(videoPlaylist.ext_x_endlist)
                    
                    expectation.fulfill()
                }
                catch {
                    XCTFail(error.description)
                }
            }
        }
    }
}
