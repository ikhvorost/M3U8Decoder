import XCTest
import Combine
/*@testable*/ import M3U8Decoder


final class M3U8_All: XCTestCase {
  
  func test_error_empty() {
    struct Playlist: Decodable {
      let extm3u: Bool
    }
    XCTAssertThrowsError(try M3U8Decoder().decode(Playlist.self, from: "")) {
      XCTAssert($0 as! M3U8Decoder.Error == .notPlaylist)
    }
  }
  
  func test_error_data() {
    struct Playlist: Decodable {
      let extm3u: Bool
    }
    XCTAssertThrowsError(try M3U8Decoder().decode(Playlist.self, from: Data([255, 255, 255]))) {
      XCTAssert($0 as! M3U8Decoder.Error == .badData)
    }
  }
  
  func test_error_not_playlist() {
    let text =
      """
      # coment 1
      #EXTM3U
      """
    
    struct Playlist: Decodable {
      let extm3u: Bool
    }
    
    XCTAssertThrowsError(try M3U8Decoder().decode(Playlist.self, from: text)) {
      XCTAssert($0 as! M3U8Decoder.Error == .notPlaylist)
    }
  }
  
  func test_error_bad_format() {
    struct BadPlaylist: Decodable {
      let extm3u: Bool
      let segments: [MediaSegment]
    }
    let text =
      """
      #EXTM3U
      #EXTINF:13.333,Sample artist - Sample title
      #EXT-X-PROGRAM-DATE-TIME:2010-02-19
      http://example.com/low.m3u8
      """
    
    XCTAssertThrowsError(try M3U8Decoder().decode(BadPlaylist.self, from: text)) {
      if case let .dataCorrupted(context) = $0 as! DecodingError {
        XCTAssert(context.debugDescription == "Invalid date: 2010-02-19")
      }
      else {
        XCTFail()
      }
    }
  }
  
  func test_default() throws {
    let text =
      """
       #EXTM3U
      #comment 1
      #EXT-X-VERSION:7
      
      # comment 2
      #EXTINF:10
      segment-0.mp4
      
      #     comment 3
      ## Created with Unified Streaming Platform(version=1.8.4)
      #USP-X-TIMESTAMP-MAP:MPEGTS=3013867424,LOCAL=2024-02-24T08:12:35.200000Z
      #EXTINF:10
         segment-1.mp4
      """
    
    struct Playlist: Decodable {
      let ext_x_version: Int
      let segments: [MediaSegment]
      let comments: [String]
    }
    
    let playlist = try M3U8Decoder().decode(Playlist.self, from: text)
    
    XCTAssert(playlist.ext_x_version == 7)
    
    XCTAssert(playlist.segments.count == 2)
    XCTAssert(playlist.segments[0].uri == "segment-0.mp4")
    XCTAssert(playlist.segments[1].uri == "segment-1.mp4")
    
    XCTAssert(playlist.comments.count == 5)
    XCTAssert(playlist.comments[0] == "comment 1")
    XCTAssert(playlist.comments[1] == "comment 2")
    XCTAssert(playlist.comments[2] == "comment 3")
    XCTAssert(playlist.comments[3] == "Created with Unified Streaming Platform(version=1.8.4)")
    XCTAssert(playlist.comments[4] == "USP-X-TIMESTAMP-MAP:MPEGTS=3013867424,LOCAL=2024-02-24T08:12:35.200000Z")
  }
  
  func test_custom_attributes() throws {
    let text =
      #"""
      #EXTM3U
      
      #EXTINF:10,title="Law Office Of Michael S Lamonsoff*Power Only*",artist="Angie Martinez",url="song_spot=\"T\" MediaBaseId=\"-1\" itunesTrackId=\"0\" amgTrackId=\"-1\" amgArtistId=\"0\" TAID=\"-1\" TPID=\"-1\" cartcutId=\"8003384001\" amgArtworkURL=\"\" length=\"00:00:58\" unsID=\"-1\" spotInstanceId=\"46787245\""
      http://cdn-chunks.prod.ihrhls.com/1481/4qgsCGy7Amkp-154241599-10031.aac
      
      #EXTINF:11.0,title="Law Office Of Michael S Lamonsoff*Power Only*",artist="Angie Martinez",url="song_spot=\"T\" MediaBaseId=\"-1\" itunesTrackId=\"0\" amgTrackId=\"-1\" amgArtistId=\"0\" TAID=\"-1\" TPID=\"-1\" cartcutId=\"8003384001\" amgArtworkURL=\"\" length=\"00:00:58\" unsID=\"-1\" spotInstanceId=\"46787245\""
      http://cdn-chunks.prod.ihrhls.com/1481/ei6nb06Xxlqp-154241600-9984.aac
      
      #EXTINF:12.2,title="Bjs Wholesale Club",artist="Bjs Wholesale Club",url="song_spot=\"T\" MediaBaseId=\"-1\" itunesTrackId=\"0\" amgTrackId=\"-1\" amgArtistId=\"0\" TAID=\"-1\" TPID=\"-1\" cartcutId=\"8006354001\" amgArtworkURL=\"\" length=\"00:00:14\" unsID=\"-1\" spotInstanceId=\"48319279\""
      http://cdn-chunks.prod.ihrhls.com/1481/360uKI2auRup-154241601-9984.aac
      """#
    
    struct CustomExtInf: Decodable {
      let duration: Double
      let title: String
      let artist: String
      let url: String
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
      let spotinstanceid: String
    }
    
    struct CustomMediaSegment: Decodable {
      let extinf: CustomExtInf
      let uri: String
    }
    
    struct Playlist: Decodable {
      let segments: [CustomMediaSegment]
    }
    
    let playlist = try M3U8Decoder().decode(Playlist.self, from: text)
    
    XCTAssert(playlist.segments.count == 3)
    
    XCTAssert(playlist.segments[0].extinf.duration == 10)
    XCTAssert(playlist.segments[0].extinf.title == "Law Office Of Michael S Lamonsoff*Power Only*")
    XCTAssert(playlist.segments[0].extinf.artist == "Angie Martinez")
    XCTAssert(playlist.segments[0].extinf.url == "song_spot=")
    XCTAssert(playlist.segments[0].extinf.mediabaseid == "-1")
    XCTAssert(playlist.segments[0].extinf.itunestrackid == "0")
    XCTAssert(playlist.segments[0].extinf.amgtrackid == "-1")
    XCTAssert(playlist.segments[0].extinf.amgartistid == "0")
    XCTAssert(playlist.segments[0].extinf.taid == "-1")
    XCTAssert(playlist.segments[0].extinf.tpid == "-1")
    XCTAssert(playlist.segments[0].extinf.cartcutid == "8003384001")
    XCTAssert(playlist.segments[0].extinf.amgartworkurl == "")
    XCTAssert(playlist.segments[0].extinf.length == "00:00:58")
    XCTAssert(playlist.segments[0].extinf.unsid == "-1")
    XCTAssert(playlist.segments[0].extinf.spotinstanceid == "46787245")
    XCTAssert(playlist.segments[0].uri == "http://cdn-chunks.prod.ihrhls.com/1481/4qgsCGy7Amkp-154241599-10031.aac")

    
    XCTAssert(playlist.segments[1].extinf.duration == 11.0)
    XCTAssert(playlist.segments[1].extinf.title == "Law Office Of Michael S Lamonsoff*Power Only*")
    XCTAssert(playlist.segments[1].extinf.artist == "Angie Martinez")
    XCTAssert(playlist.segments[1].extinf.url == "song_spot=")
    XCTAssert(playlist.segments[1].extinf.mediabaseid == "-1")
    XCTAssert(playlist.segments[1].extinf.itunestrackid == "0")
    XCTAssert(playlist.segments[1].extinf.amgtrackid == "-1")
    XCTAssert(playlist.segments[1].extinf.amgartistid == "0")
    XCTAssert(playlist.segments[1].extinf.taid == "-1")
    XCTAssert(playlist.segments[1].extinf.tpid == "-1")
    XCTAssert(playlist.segments[1].extinf.cartcutid == "8003384001")
    XCTAssert(playlist.segments[1].extinf.amgartworkurl == "")
    XCTAssert(playlist.segments[1].extinf.length == "00:00:58")
    XCTAssert(playlist.segments[1].extinf.unsid == "-1")
    XCTAssert(playlist.segments[1].extinf.spotinstanceid == "46787245")
    XCTAssert(playlist.segments[1].uri == "http://cdn-chunks.prod.ihrhls.com/1481/ei6nb06Xxlqp-154241600-9984.aac")
    
    XCTAssert(playlist.segments[2].extinf.duration == 12.2)
    XCTAssert(playlist.segments[2].extinf.title == "Bjs Wholesale Club")
    XCTAssert(playlist.segments[2].extinf.artist == "Bjs Wholesale Club")
    XCTAssert(playlist.segments[2].extinf.url == "song_spot=")
    XCTAssert(playlist.segments[2].extinf.mediabaseid == "-1")
    XCTAssert(playlist.segments[2].extinf.itunestrackid == "0")
    XCTAssert(playlist.segments[2].extinf.amgtrackid == "-1")
    XCTAssert(playlist.segments[2].extinf.amgartistid == "0")
    XCTAssert(playlist.segments[2].extinf.taid == "-1")
    XCTAssert(playlist.segments[2].extinf.tpid == "-1")
    XCTAssert(playlist.segments[2].extinf.cartcutid == "8006354001")
    XCTAssert(playlist.segments[2].extinf.amgartworkurl == "")
    XCTAssert(playlist.segments[2].extinf.length == "00:00:14")
    XCTAssert(playlist.segments[2].extinf.unsid == "-1")
    XCTAssert(playlist.segments[2].extinf.spotinstanceid == "48319279")
    XCTAssert(playlist.segments[2].uri == "http://cdn-chunks.prod.ihrhls.com/1481/360uKI2auRup-154241601-9984.aac")
  }
  
  func test_custom_tags() throws {
    let text =
      """
      #EXTM3U
      #EXT-CUSTOM-TAG1:1
      #EXT-CUSTOM-TAG2:a=a,b="b",c=\"c\" d='d' e=\'e\' f=
      #EXT-CUSTOM-ARRAY:2
      #EXT-CUSTOM-ARRAY:3
      #EXT-CUSTOM-ARRAY:4
      """
    
    struct CustomAttributes: Decodable {
      let a: String
      let b: String
      let c: String
      let d: String
      let e: String
      let f: String?
    }
    
    struct CustomPlaylist: Decodable {
      let ext_custom_tag1: Int
      let ext_custom_tag2: CustomAttributes
      let ext_custom_array: [Int]
    }
    
    let playlist = try M3U8Decoder().decode(CustomPlaylist.self, from: text)
    
    XCTAssert(playlist.ext_custom_tag1 == 1)
    
    XCTAssert(playlist.ext_custom_tag2.a == "a")
    XCTAssert(playlist.ext_custom_tag2.b == "b")
    XCTAssert(playlist.ext_custom_tag2.c == "c")
    XCTAssert(playlist.ext_custom_tag2.d == "d")
    XCTAssert(playlist.ext_custom_tag2.e == "e")
    XCTAssert(playlist.ext_custom_tag2.f == nil)
    
    XCTAssert(playlist.ext_custom_array.count == 3)
    XCTAssert(playlist.ext_custom_array == [2, 3, 4])
  }
  
  func test_custom_parse() throws {
    let text =
      #"""
      #EXTM3U
      #EXT-CUSTOM-TAG:{"duration": 10.3, "title": "Title", "id": 12345}
      """#
    
    struct CustomTag: Decodable {
      let duration: Double
      let title: String
      let id: Int
    }
    
    struct MediaPlaylist: Decodable {
      let ext_custom_tag: CustomTag
    }
    
    let decoder = M3U8Decoder()
    decoder.parseHandler = { (tag: String, attributes: String) -> M3U8Decoder.ParseAction in
      if tag == "EXT-CUSTOM-TAG" {
        do {
          if let data = attributes.data(using: .utf8) {
            let dict = try JSONSerialization.jsonObject(with: data)
            return .apply(dict)
          }
        }
        catch {
          print(error)
        }
      }
      return .parse
    }
    
    let playlist = try decoder.decode(MediaPlaylist.self, from: text)
    
    XCTAssert(playlist.ext_custom_tag.duration == 10.3)
    XCTAssert(playlist.ext_custom_tag.title == "Title")
    XCTAssert(playlist.ext_custom_tag.id == 12345)
  }
  
  func test_data_hex() throws {
    let text =
      """
      #EXTM3U
      #EXT-DATA:0xabcdef
      #EXT-KEY:VALUE=0x11223344
      """
    
    struct ExtKey: Decodable {
      let value: Data
    }
    
    struct Playlist: Decodable {
      let extm3u: Bool
      let ext_data: Data
      let ext_key: ExtKey
    }
    
    let playlist = try M3U8Decoder().decode(Playlist.self, from: text)
    
    XCTAssert(playlist.extm3u == true)
    
    XCTAssert(playlist.ext_data.count == 3)
    XCTAssert(playlist.ext_data[0] == 0xab)
    XCTAssert(playlist.ext_data[1] == 0xcd)
    XCTAssert(playlist.ext_data[2] == 0xef)
    
    XCTAssert(playlist.ext_key.value.count == 4)
    XCTAssert(playlist.ext_key.value[0] == 0x11)
    XCTAssert(playlist.ext_key.value[3] == 0x44)
  }
  
  func test_data_base64() throws {
    let text =
      """
      #EXTM3U
      #EXT-DATA1:q83v
      #EXT-DATA2:SGVsbG8=
      #EXT-DATA3:SGVsbG8gQmFzZTY0IQ==
      #EXT-KEY:VALUE1=QmFzZTY0,VALUE2=SGVsbG8=,VALUE3=SGVsbG8gQmFzZTY0IQ==
      """
    
    struct ExtKey: Decodable {
      let value1: Data
      let value2: Data
      let value3: Data
    }
    
    struct Playlist: Decodable {
      let extm3u: Bool
      let ext_data1: Data
      let ext_data2: Data
      let ext_data3: Data
      let ext_key: ExtKey
    }
    
    let decoder = M3U8Decoder()
    decoder.dataDecodingStrategy = .base64
    let playlist = try decoder.decode(Playlist.self, from: text)
    
    XCTAssert(playlist.extm3u == true)
    
    // Base64: q83v = 0xabcdef
    XCTAssert(playlist.ext_data1.count == 3)
    XCTAssert(playlist.ext_data1[0] == 0xab)
    XCTAssert(playlist.ext_data1[1] == 0xcd)
    XCTAssert(playlist.ext_data1[2] == 0xef)
    
    XCTAssert(String(data: playlist.ext_data2, encoding: .utf8) == "Hello")
    XCTAssert(String(data: playlist.ext_data3, encoding: .utf8) == "Hello Base64!")
    
    XCTAssert(String(data: playlist.ext_key.value1, encoding: .utf8) == "Base64")
    XCTAssert(String(data: playlist.ext_key.value2, encoding: .utf8) == "Hello")
    XCTAssert(String(data: playlist.ext_key.value3, encoding: .utf8) == "Hello Base64!")
  }
  
  func test_playlist() throws {
    let playlistText =
      """
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
    
    struct Playlist: Decodable {
      let extm3u: Bool
      let ext_x_version: Int
      
      let ext_x_targetduration: Int
      let ext_x_media_sequence: Int
      let ext_x_discontinuity_sequence: Int
      let ext_x_playlist_type: String
      let ext_x_i_frames_only: Bool
      let ext_x_endlist: Bool
      
      let segments: [MediaSegment]
    }
    
    let playlist = try M3U8Decoder().decode(Playlist.self, from: playlistText)
    
    XCTAssert(playlist.extm3u)
    XCTAssert(playlist.ext_x_version == 7)
    
    XCTAssert(playlist.ext_x_targetduration == 10)
    XCTAssert(playlist.ext_x_media_sequence == 2680)
    XCTAssert(playlist.ext_x_discontinuity_sequence == 0)
    XCTAssert(playlist.ext_x_playlist_type == "VOD")
    XCTAssert(playlist.ext_x_i_frames_only)
    XCTAssert(playlist.ext_x_endlist)
    
    XCTAssert(playlist.segments.count == 3)
    XCTAssert(playlist.segments[0].ext_x_key?.method == "SAMPLE-AES")
    XCTAssert(playlist.segments[0].ext_x_key?.keyformat == "com.apple.streamingkeydelivery")
    XCTAssert(playlist.segments[0].ext_x_key?.keyformatversions == "1")
    XCTAssert(playlist.segments[0].ext_x_key?.uri == "skd://p-drmfp-vod.movetv.com/fairplay/d1acadbf70824d178601c2e55675b3b3")
    XCTAssert(playlist.segments[0].ext_x_key?.iv?.count == 16) // 128-bit "0X99b74007b6254e4bd1c6e03631cad15b"
    XCTAssert(playlist.segments[0].ext_x_key?.iv?[0] == 0x99)
    XCTAssert(playlist.segments[0].ext_x_key?.iv?[15] == 0x5b)
    
    XCTAssert(playlist.segments[0].ext_x_map?.uri == "main.mp4")
    XCTAssert(playlist.segments[0].ext_x_map?.byterange?.length == 1118)
    XCTAssert(playlist.segments[0].ext_x_map?.byterange?.start == 0)
    
    XCTAssert(playlist.segments[0].ext_x_program_date_time?.description == "2010-02-19 06:54:23 +0000")
    
    XCTAssert(playlist.segments[0].ext_x_daterange?.id == "splice-6FFFFFF0")
    XCTAssert(playlist.segments[0].ext_x_daterange?.class == "com.xyz.dai.adbreak")
    XCTAssert(playlist.segments[0].ext_x_daterange?.start_date.description == "2014-03-05 11:15:00 +0000")
    XCTAssert(playlist.segments[0].ext_x_daterange?.end_date?.description == "2014-03-05 11:15:00 +0000")
    XCTAssert(playlist.segments[0].ext_x_daterange?.duration == 59.993)
    XCTAssert(playlist.segments[0].ext_x_daterange?.planned_duration == 59.993)
    //XCTAssert(playlist.segments[0].ext_x_daterange?.x_com_example_ad_id == "XYZ123")
    XCTAssert(playlist.segments[0].ext_x_daterange?.scte35_out == "0xFC002F0000000000FF000014056FFFFFF000E011622DCAFF000052636200000000000A0008029896F50000008700000000")
    XCTAssert(playlist.segments[0].ext_x_daterange?.end_on_next == true)
    
    XCTAssert(playlist.segments[0].extinf.duration == 13.333)
    XCTAssert(playlist.segments[0].extinf.title == "Sample artist - Sample title")
    
    XCTAssert(playlist.segments[0].ext_x_byterange?.length == 1700094)
    XCTAssert(playlist.segments[0].ext_x_byterange?.start == 1118)
    
    XCTAssert(playlist.segments[0].uri == "http://example.com/low.m3u8")
    
    XCTAssert(playlist.segments[1].ext_x_discontinuity == true)
    XCTAssert(playlist.segments[1].ext_x_byterange?.length == 1777588)
    XCTAssert(playlist.segments[1].ext_x_byterange?.start == nil)
    XCTAssert(playlist.segments[1].extinf.duration == 8.0)
    XCTAssert(playlist.segments[1].extinf.title == nil)
    XCTAssert(playlist.segments[1].uri == "main.mp4")
    
    XCTAssert(playlist.segments[2].extinf.duration == 10.0)
    XCTAssert(playlist.segments[2].extinf.title == nil)
    XCTAssert(playlist.segments[2].uri == "next.mp4")
  }
  
  func test_master() throws {
    let masterPlaylistText =
      """
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
  
    struct MaterPlaylist: Decodable {
      let extm3u: Bool
      let ext_x_independent_segments: Bool
      let ext_x_start: EXT_X_START
      let ext_x_session_data: EXT_X_SESSION_DATA
      let ext_x_session_key: EXT_X_KEY
      let ext_x_media: [EXT_X_MEDIA]
      let ext_x_i_frame_stream_inf: [EXT_X_I_FRAME_STREAM_INF]
      let streams: [VariantStream]
    }
  
    let playlist = try M3U8Decoder().decode(MaterPlaylist.self, from: masterPlaylistText)
    
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
    
    XCTAssert(playlist.streams.count == 1)
    XCTAssert(playlist.streams[0].ext_x_stream_inf.bandwidth == 3679027)
    XCTAssert(playlist.streams[0].ext_x_stream_inf.average_bandwidth == 3063808)
    XCTAssert(playlist.streams[0].ext_x_stream_inf.codecs.count == 2)
    XCTAssert(playlist.streams[0].ext_x_stream_inf.codecs[0] == "avc1.640028")
    XCTAssert(playlist.streams[0].ext_x_stream_inf.codecs[1] == "mp4a.40.2")
    XCTAssert(playlist.streams[0].ext_x_stream_inf.resolution?.width == 1280)
    XCTAssert(playlist.streams[0].ext_x_stream_inf.resolution?.height == 720)
    XCTAssert(playlist.streams[0].ext_x_stream_inf.frame_rate == 23.976)
    XCTAssert(playlist.streams[0].ext_x_stream_inf.hdcp_level == "TYPE-0")
    XCTAssert(playlist.streams[0].ext_x_stream_inf.audio == "aac_2_192_cdn_1")
    XCTAssert(playlist.streams[0].ext_x_stream_inf.video == "aac_2_192_cdn_1")
    XCTAssert(playlist.streams[0].ext_x_stream_inf.subtitles == "sub1")
    XCTAssert(playlist.streams[0].ext_x_stream_inf.closed_captions == "cc")
    XCTAssert(playlist.streams[0].uri == "http://example.com/low.m3u8")
  }
}

final class M3U8Tests_File: XCTestCase {
  
  struct MasterPlaylist: Decodable {
    let extm3u: Bool
    let ext_x_version: Int
    let ext_x_independent_segments: Bool
    let ext_x_session_key: EXT_X_KEY
    let ext_x_media: [EXT_X_MEDIA]
    let ext_x_i_frame_stream_inf: [EXT_X_I_FRAME_STREAM_INF]
    let streams: [VariantStream]
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
    let ext_x_endlist: Bool
    let segments: [MediaSegment]
  }
  
  static let masterUrl = Bundle.module.url(forResource: "m3u8/master_7_3_fairplay", withExtension: "m3u8")!
  static let videoUrl = Bundle.module.url(forResource: "m3u8/video_7_02_3_fairplay", withExtension: "m3u8")!
  static let compressedLargeURL = Bundle.module.url(forResource: "m3u8/tv_channels_private.m3u", withExtension: "zlib")!
  
  func test_master() throws {
    let playlist = try M3U8Decoder().decode(MasterPlaylist.self, from: Self.masterUrl)
    
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
    
    // Variant streams
    
    XCTAssert(playlist.streams.count == 18)
    
    XCTAssert(playlist.streams[0].ext_x_stream_inf.bandwidth == 3679027)
    XCTAssert(playlist.streams[0].ext_x_stream_inf.average_bandwidth == 3063808)
    XCTAssert(playlist.streams[0].ext_x_stream_inf.resolution?.width == 1280)
    XCTAssert(playlist.streams[0].ext_x_stream_inf.resolution?.height == 720)
    XCTAssert(playlist.streams[0].ext_x_stream_inf.frame_rate == 23.976)
    XCTAssert(playlist.streams[0].ext_x_stream_inf.codecs.count == 2)
    XCTAssert(playlist.streams[0].ext_x_stream_inf.codecs[0] == "avc1.640028")
    XCTAssert(playlist.streams[0].ext_x_stream_inf.codecs[1] == "mp4a.40.2")
    XCTAssert(playlist.streams[0].ext_x_stream_inf.closed_captions == "cc")
    XCTAssert(playlist.streams[0].ext_x_stream_inf.audio == "aac_2_192_cdn_1")
    XCTAssert(playlist.streams[0].uri == "sample/video_7_03_3_fairplay.m3u8")
    
    XCTAssert(playlist.streams[2].ext_x_stream_inf.bandwidth == 8225587)
    XCTAssert(playlist.streams[2].ext_x_stream_inf.average_bandwidth == 6852608)
    XCTAssert(playlist.streams[2].ext_x_stream_inf.resolution?.width == 1920)
    XCTAssert(playlist.streams[2].ext_x_stream_inf.resolution?.height == 1080)
    XCTAssert(playlist.streams[2].ext_x_stream_inf.frame_rate == 23.976)
    XCTAssert(playlist.streams[2].ext_x_stream_inf.codecs.count == 2)
    XCTAssert(playlist.streams[2].ext_x_stream_inf.codecs[0] == "avc1.640028")
    XCTAssert(playlist.streams[2].ext_x_stream_inf.codecs[1] == "mp4a.40.2")
    XCTAssert(playlist.streams[2].ext_x_stream_inf.closed_captions == "cc")
    XCTAssert(playlist.streams[2].ext_x_stream_inf.audio == "aac_2_192_cdn_1")
    XCTAssert(playlist.streams[2].uri == "sample/video_7_05_3_fairplay.m3u8")
    
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
  
  func test_master_camelCase() throws {
    let decoder = M3U8Decoder()
    decoder.keyDecodingStrategy = .camelCase
    _ = try decoder.decode(MasterPlaylistCamelCase.self, from: Self.masterUrl)
  }
  
  func test_master_customKey() throws {
    let decoder = M3U8Decoder()
    decoder.keyDecodingStrategy = .custom { key in
      return key
        .lowercased()
        .replacingOccurrences(of: "ext", with: "")
        .replacingOccurrences(of: "-x-", with: "")
        .replacingOccurrences(of: "-", with: "_")
    }
    _ = try decoder.decode(MasterPlaylistCustomKey.self, from: Self.masterUrl)
  }
  
  func test_playlist() throws {
    let playlist = try M3U8Decoder().decode(VideoPlaylist.self, from: Self.videoUrl)
    
    XCTAssert(playlist.extm3u)
    XCTAssert(playlist.ext_x_version == 7)
    XCTAssert(playlist.ext_x_targetduration == 3)
    XCTAssert(playlist.ext_x_playlist_type == "VOD")
    
    XCTAssert(playlist.segments.count == 1461)
    
    XCTAssert(playlist.segments[0].ext_x_key?.method == "SAMPLE-AES")
    XCTAssert(playlist.segments[0].ext_x_key?.keyformat == "com.apple.streamingkeydelivery")
    XCTAssert(playlist.segments[0].ext_x_key?.keyformatversions == "1")
    XCTAssert(playlist.segments[0].ext_x_key?.uri == "skd://p-drmfp-vod.movetv.com/fairplay/d1acadbf70824d178601c2e55675b3b3")
    XCTAssert(playlist.segments[0].ext_x_key?.iv == nil)
    
    XCTAssert(playlist.segments[0].extinf.duration == 2.048)
    XCTAssert(playlist.segments[0].extinf.title == nil)
    
    XCTAssert(playlist.segments[0].uri == "/22001/vod/dyn/f24d38bc60a411ec88b4005056a5d12f/sample/v0200000001.ts")
    XCTAssert(playlist.segments[2].uri == "/22001/vod/dyn/f24d38bc60a411ec88b4005056a5d12f/sample/v0200000003.ts")
    
    XCTAssert(playlist.ext_x_endlist)
  }
  
  func test_large_playlist() throws {
    struct VideoPlaylist: Decodable {
      let extm3u: Bool
      let segments: [MediaSegment]
    }
    
    let compressed = try Data(contentsOf: Self.compressedLargeURL)
    let data = try (compressed as NSData).decompressed(using: .zlib) as Data
    
    let start = Date()
    let playlist = try M3U8Decoder().decode(VideoPlaylist.self, from: data)
    let timeout = -start.timeIntervalSinceNow
    print("Timeout: \(timeout)")
    XCTAssert(timeout < 7.0)
  
    XCTAssert(playlist.segments.count == 194918)
    XCTAssert(playlist.segments[1].extinf.duration == -1)
    XCTAssert(playlist.segments[1].extinf.title == "TR | ● TRT 4K UHD")
    XCTAssert(playlist.segments[1].uri == "http://ios.liveurl.xyz:8080/username/password/138426")
  }
}

final class M3U8Tests_URL: XCTestCase {
  
  static let bipbopURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
  // https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8
  static let mpdURL = URL(string: "https://cdn.bitmovin.com/content/assets/art-of-motion-dash-hls-progressive/mpds/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.mpd")!
  
  struct MasterPlaylist: Decodable {
    let extm3u: Bool
    let ext_x_version: Int
    let ext_x_independent_segments: Bool
    let ext_x_media: [EXT_X_MEDIA]
    let ext_x_i_frame_stream_inf: [EXT_X_I_FRAME_STREAM_INF]
    let streams: [VariantStream]
  }
  
  func testMasterPlaylist(_ playlist: MasterPlaylist) {
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
    XCTAssert(playlist.streams.count == 24)
    XCTAssert(playlist.streams[2].ext_x_stream_inf.average_bandwidth == 6170000)
    XCTAssert(playlist.streams[2].ext_x_stream_inf.bandwidth == 6312875)
    XCTAssert(playlist.streams[2].ext_x_stream_inf.codecs.count == 2)
    XCTAssert(playlist.streams[2].ext_x_stream_inf.codecs[0] == "avc1.64002a")
    XCTAssert(playlist.streams[2].ext_x_stream_inf.codecs[1] == "mp4a.40.2")
    XCTAssert(playlist.streams[2].ext_x_stream_inf.resolution?.width == 1920)
    XCTAssert(playlist.streams[2].ext_x_stream_inf.resolution?.height == 1080)
    XCTAssert(playlist.streams[2].ext_x_stream_inf.frame_rate == 60.000)
    XCTAssert(playlist.streams[2].ext_x_stream_inf.closed_captions == "cc1")
    XCTAssert(playlist.streams[2].ext_x_stream_inf.audio == "aud1")
    XCTAssert(playlist.streams[2].ext_x_stream_inf.subtitles == "sub1")
    XCTAssert(playlist.streams[2].uri == "v8/prog_index.m3u8")
  }
  
  func test_error_unsupported_url() async {
    do {
      _ = try await M3U8Decoder().decode(MasterPlaylist.self, from: URL(string: "domain.com")!)
    }
    catch {
      XCTAssert(error.localizedDescription == "unsupported URL")
    }
  }
  
  func test_error_not_playlist() async {
    do {
      _ = try await M3U8Decoder().decode(MasterPlaylist.self, from: Self.mpdURL)
    }
    catch {
      XCTAssert(error as! M3U8Decoder.Error == .notPlaylist)
    }
  }
  
  func test_master() async throws {
    let playlist = try await M3U8Decoder().decode(MasterPlaylist.self, from: Self.bipbopURL)
    self.testMasterPlaylist(playlist)
  }
  
  var cancellable: Cancellable?
  
  func test_master_combine() {
    let exp = expectation(description: #function)
    
    cancellable = URLSession.shared.dataTaskPublisher(for: Self.bipbopURL)
      .map(\.data)
      .decode(type: MasterPlaylist.self, decoder: M3U8Decoder())
      .sink (
        receiveCompletion: { print($0) },
        receiveValue: { playlist in
          self.testMasterPlaylist(playlist)
          exp.fulfill()
        }
      )
    
    wait(for: [exp], timeout: 5.0)
  }
  
  func test_video_variant() async throws {
    struct MediaPlaylist: Decodable {
      let extm3u: Bool
      let ext_x_targetduration: Int
      let ext_x_version: Int
      let ext_x_media_sequence: Int
      let ext_x_playlist_type: String
      let ext_x_independent_segments: Bool
      let ext_x_endlist: Bool
      let segments: [MediaSegment]
    }
    
    let masterPlaylist = try await M3U8Decoder().decode(MasterPlaylist.self, from: Self.bipbopURL)
    
    guard let uri = masterPlaylist.streams.first?.uri else {
      XCTFail("No video variant")
      return
    }
    let url = Self.bipbopURL.deletingLastPathComponent().appendingPathComponent(uri)
    let mediaPlaylist = try await M3U8Decoder().decode(MediaPlaylist.self, from: url)
    
    XCTAssert(mediaPlaylist.extm3u)
    XCTAssert(mediaPlaylist.ext_x_version == 7)
    
    XCTAssert(mediaPlaylist.extm3u)
    XCTAssert(mediaPlaylist.ext_x_targetduration == 6)
    XCTAssert(mediaPlaylist.ext_x_version == 7)
    XCTAssert(mediaPlaylist.ext_x_media_sequence == 1)
    XCTAssert(mediaPlaylist.ext_x_playlist_type == "VOD")
    XCTAssert(mediaPlaylist.ext_x_independent_segments)
    
    XCTAssert(mediaPlaylist.segments.count == 100)
    
    XCTAssert(mediaPlaylist.segments[0].ext_x_map?.uri == "main.mp4")
    XCTAssert(mediaPlaylist.segments[0].ext_x_map?.byterange?.length == 719)
    XCTAssert(mediaPlaylist.segments[0].ext_x_map?.byterange?.start == 0)
    
    XCTAssert(mediaPlaylist.segments[0].extinf.duration == 6.00000)
    
    XCTAssert(mediaPlaylist.segments[0].ext_x_byterange?.length == 1508000)
    XCTAssert(mediaPlaylist.segments[0].ext_x_byterange?.start == 719)
    
    XCTAssert(mediaPlaylist.segments[0].uri == "main.mp4")
    
    XCTAssert(mediaPlaylist.ext_x_endlist)
  }
}
