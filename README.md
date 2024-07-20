[![Swift: 5.10, 5.9, 5.8, 5.7](https://img.shields.io/badge/Swift-5.10%20|%205.9%20|%205.8%20|%205.7-de5d43.svg?style=flat&logo=swift)](https://developer.apple.com/swift)
![Platforms: iOS, macOS, tvOS, visionOS, watchOS](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20visionOS%20|%20watchOS-blue.svg?style=flat&logo=apple)
[![Swift Package Manager: compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-4BC51D.svg?style=flat&logo=apple)](https://swift.org/package-manager/)
[![Build](https://github.com/ikhvorost/M3U8Decoder/actions/workflows/swift.yml/badge.svg)](https://github.com/ikhvorost/M3U8Decoder/actions/workflows/swift.yml)
[![codecov](https://codecov.io/gh/ikhvorost/M3U8Decoder/branch/main/graph/badge.svg?token=fa2mCNbfuM)](https://codecov.io/gh/ikhvorost/M3U8Decoder)
[![Swift Doc Coverage](https://img.shields.io/badge/Swift%20Doc%20Coverage-100%25-f39f37?logo=google-docs&logoColor=white)](https://github.com/ikhvorost/swift-doc-coverage)

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/donate/?hosted_button_id=TSPDD3ZAAH24C)

<p align="center">
<img src="m3u8decoder.png" alt="M3U8Decoder: Flexible M3U8 playlist parsing for Swift." width="350">
</p>

# M3U8Decoder 

Decoder for Master and Media Playlists of [HTTP Live Streaming](https://datatracker.ietf.org/doc/html/rfc8216) using `Decodable` protocol.

- [Overview](#overview)
- [Key decoding strategy](#key-decoding-strategy)
- [Data decoding strategy](#data-decoding-strategy)
- [Predefined types](#predefined-types)
- [Custom tags and attributes](#custom-tags-and-attributes)
- [Combine](#combine)
- [Installation](#installation)
- [License](#license)

## Overview

The example below shows how to decode a simple Media Playlist from a provided text. The type adopts `Decodable` so that it’s decodable using a `M3U8Decoder` instance.

```swift
import M3U8Decoder

struct MediaPlaylist: Decodable {
  let extm3u: Bool
  let ext_x_version: Int
  let ext_x_targetduration: Int
  let ext_x_media_sequence: Int
  let segments: [MediaSegment]
  let comments: [String]
}

let m3u8 = """
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-TARGETDURATION:10
# Created with Unified Streaming Platform
#EXT-X-MEDIA-SEQUENCE:2680

#EXTINF:13.333,Sample artist - Sample title
http://example.com/low.m3u8
"""

let playlist = try M3U8Decoder().decode(MediaPlaylist.self, from: m3u8)
print(playlist)
```

Where:
- Predefined `segments` property contains array of `MediaSegment` structs with all parsed media segments tags and url, such as: `#EXTINF`, `#EXT-X-BYTERANGE`, `#EXT-X-DISCONTINUITY`, `#EXT-X-KEY`, `#EXT-X-MAP` `#EXT-X-PROGRAM-DATE-TIME`, `#EXT-X-DATERANGE` (For more info see [Predefined types](#predefined-types))
- Predefined `comments` property contains all lines that begin with `#`.

Prints:

``` swift
MediaPlaylist(
  extm3u: true, 
  ext_x_version: 7, 
  ext_x_targetduration: 10, 
  ext_x_media_sequence: 2680, 
  segments: [
    M3U8Decoder.MediaSegment(
      extinf: M3U8Decoder.EXTINF(
        duration: 13.333, 
        title: Optional("Sample artist - Sample title")
      ),
      ext_x_byterange: nil,
      ext_x_discontinuity: nil, 
      ext_x_key: nil, 
      ext_x_map: nil, 
      ext_x_program_date_time: nil, 
      ext_x_daterange: nil, 
      uri: "http://example.com/low.m3u8"
    )
  ], 
  comments: ["Created with Unified Streaming Platform"]
)
```

`M3U8Decoder` can also decode from `Data` and `URL` instances both synchonously and asynchronously (`async/await`). For instance, decoding Master Playlist by url:

```swift
import M3U8Decoder

struct MasterPlaylist: Decodable {
  let extm3u: Bool
  let ext_x_version: Int
  let ext_x_independent_segments: Bool
  let ext_x_media: [EXT_X_MEDIA]
  let ext_x_i_frame_stream_inf: [EXT_X_I_FRAME_STREAM_INF]
  let streams: [VariantStream]
}

let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
let playlist = try M3U8Decoder().decode(MasterPlaylist.self, from: url)
print(playlist)
```

Where: 
- Predefined `streams` property contains array of `VariantStream` structs with parsed `#EXT-X-STREAM-INF` tag and url (For more info see [Predefined types](#predefined-types))

Prints:

``` swift 
MasterPlaylist(
  extm3u: true, 
  ext_x_version: 6, 
  ext_x_independent_segments: true, 
  ext_x_media: [
    M3U8Decoder.EXT_X_MEDIA(
      type: "AUDIO", 
      group_id: "aud1", 
      name: "English", 
      language: Optional("en"), 
      assoc_language: nil, 
      autoselect: Optional(true), 
      default: Optional(true), 
      instream_id: nil, 
      channels: Optional("2"), 
      forced: nil, 
      uri: Optional("a1/prog_index.m3u8"), 
      characteristics: nil
    ),
    ...
  ], 
  ext_x_i_frame_stream_inf: [
    M3U8Decoder.EXT_X_I_FRAME_STREAM_INF(
      bandwidth: 187492, 
      average_bandwidth: Optional(183689), 
      codecs: ["avc1.64002a"], 
      resolution: Optional(M3U8Decoder.RESOLUTION(width: 1920, height: 1080)), 
      hdcp_level: nil, 
      video: nil, 
      uri: "v7/iframe_index.m3u8"
    ),
    ...
  ], 
  streams: [
    M3U8Decoder.VariantStream(
      ext_x_stream_inf: M3U8Decoder.EXT_X_STREAM_INF(
        bandwidth: 2177116, 
        average_bandwidth: Optional(2168183), 
        codecs: ["avc1.640020", "mp4a.40.2"], 
        resolution: Optional(M3U8Decoder.RESOLUTION(width: 960, height: 540)), 
        frame_rate: Optional(60.0), 
        hdcp_level: nil, 
        audio: Optional("aud1"), 
        video: nil, 
        subtitles: Optional("sub1"), 
        closed_captions: Optional("cc1")
      ),
      uri: "v5/prog_index.m3u8"
    ),
    ...
  ]
)
```

## Key decoding strategy

The strategy to use for automatically changing the value of keys before decoding.

### `snakeCase`

It's **default** strategy to convert playlist tags and attribute names to snake case.

1. Converting keys to lower case.
2. Replaces all `-` with `_`.

For example: `#EXT-X-TARGETDURATION` becomes `ext_x_targetduration`.

### `camelCase`

Converting playlist tag and attribute names to camel case.

1. Converting keys to lower case.
2. Capitalises the word starting after each `-`
3. Removes all `-`.

For example: `#EXT-X-TARGETDURATION` becomes `extXTargetduration`.

```swift
struct Media: Decodable {
  let type: String
  let groupId: String
  let name: String
  let language: String
  let instreamId: String
}

struct MasterPlaylist: Decodable {
  let extm3u: Bool
  let extXVersion: Int
  let extXIndependentSegments: Bool
  let extXMedia: [Media]
}

let m3u8 = """
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-INDEPENDENT-SEGMENTS
#EXT-X-MEDIA:TYPE=CLOSED-CAPTIONS,GROUP-ID="cc",NAME="SERVICE1",LANGUAGE="en",INSTREAM-ID="SERVICE1"
"""

let decoder = M3U8Decoder()
decoder.keyDecodingStrategy = .camelCase

let playlist = try decoder.decode(MasterPlaylist.self, from: m3u8)
print(playlist)
```

Prints:

``` swift
MasterPlaylist(
  extm3u: true, 
  extXVersion: 7, 
  extXIndependentSegments: true, 
  extXMedia: [
    Media(
      type: "CLOSED-CAPTIONS", 
      groupId: "cc", 
      name: "SERVICE1", 
      language: "en", 
      instreamId: "SERVICE1"
    )
  ]
)
```

### `custom((_ key: String) -> String)`

Provide a custom conversion from a tag or attribute name in the playlist to the keys specified by the provided function.

```swift
struct Media: Decodable {
  let type: String
  let group_id: String
  let name: String
  let language: String
  let instream_id: String
}

struct MasterPlaylist: Decodable {
  let m3u: Bool
  let version: Int
  let independent_segments: Bool
  let media: [Media]
}

let m3u8 = """
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-INDEPENDENT-SEGMENTS
#EXT-X-MEDIA:TYPE=CLOSED-CAPTIONS,GROUP-ID="cc",NAME="SERVICE1",LANGUAGE="en",INSTREAM-ID="SERVICE1"
"""

let decoder = M3U8Decoder()
// `EXT-X-INDEPENDENT-SEGMENTS` becomes `independent_segments`
decoder.keyDecodingStrategy = .custom { key in
  key
    .lowercased()
    .replacingOccurrences(of: "ext", with: "")
    .replacingOccurrences(of: "-x-", with: "")
    .replacingOccurrences(of: "-", with: "_")
}

let playlist = try decoder.decode(MasterPlaylist.self, from: m3u8)
print(playlist)
```

Prints:

``` swift
MasterPlaylist(
  m3u: true, 
  version: 7, 
  independent_segments: true, 
  media: [
    Media(
      type: "CLOSED-CAPTIONS", 
      group_id: "cc", 
      name: "SERVICE1", 
      language: "en", 
      instream_id: "SERVICE1"
    )
  ]
)
```

## Data decoding strategy

The strategies to use for decoding `Data` values.

### `hex`

Decode the `Data` from a hex string (e.g. `0xa2c4f622...`). This is the default strategy.

For instance, decoding `#EXT-X-KEY` tag with `IV` attribute where data is represented in hex string:

```swift
struct MediaPlaylist: Decodable {
  let extm3u: Bool
  let ext_x_version: Int
  let segments: [MediaSegment]
}

let m3u8 = """
#EXTM3U
#EXT-X-VERSION:7

#EXT-X-KEY:METHOD=SAMPLE-AES,URI="skd://vod.domain.com/fairplay/d1acadbf70824d178601c2e55675b3b3",IV=0X99b74007b6254e4bd1c6e03631cad15b
#EXTINF:10,
http://example.com/low.m3u8
"""

let playlist = try M3U8Decoder().decode(MediaPlaylist.self, from: m3u8)
if let iv = playlist.segments.first?.ext_x_key?.iv {
  print(iv.map { $0 } )
}
// Prints: [153, 183, 64, 7, 182, 37, 78, 75, 209, 198, 224, 54, 49, 202, 209, 91]
```

### `base64`

Decoding the `Data` from a Base64-encoded string:

```swift
struct Playlist: Decodable {
  let extm3u: Bool
  let ext_x_version: Int
  let ext_data: Data
}

let m3u8 = """
#EXTM3U
#EXT-X-VERSION:7
#EXT-DATA:SGVsbG8gQmFzZTY0IQ==
"""

let decoder = M3U8Decoder()
decoder.dataDecodingStrategy = .base64

let playlist = try decoder.decode(Playlist.self, from: m3u8)
let text = String(data: playlist.ext_data, encoding: .utf8)!
print(text) // Prints: Hello Base64!
```

## Predefined types

There are a list of predefined types (with `snakeCase` key coding strategy) for all master/media tags and attributes from of [HTTP Live Streaming](https://datatracker.ietf.org/doc/html/rfc8216) document that can be used to decode playlists.

> NOTE: Implementations of these types you can look at [MasterPlaylist.swift](Sources/M3U8Decoder/MasterPlaylist.swift) and [MediaPlaylist.swift](Sources/M3U8Decoder/MediaPlaylist.swift) but anyway **you can make and use your own ones** to decode your playlists.

Type | Tag/Attribute | Description
-- | -- | --
`EXT_X_MAP` | `#EXT-X-MAP:<attribute-list>` | The EXT-X-MAP tag specifies how to obtain the Media Initialization Section required to parse the applicable Media Segments.
`EXT_X_KEY` | `#EXT-X-KEY:<attribute-list>` <br> `#EXT_X_SESSION_KEY:<attribute-list>` | Media Segments MAY be encrypted. The EXT-X-KEY/EXT_X_SESSION_KEY tag specifies how to decrypt them.  
`EXT_X_DATERANGE` | `#EXT-X-DATERANGE:<attribute-list>` | The EXT-X-DATERANGE tag associates a Date Range (i.e., a range o time defined by a starting and ending date) with a set of attribute value pairs.
`EXTINF` | `#EXTINF:<duration>,[<title>]` |  The EXTINF tag specifies the duration of a Media Segment.
`EXT_X_BYTERANGE` | `#EXT-X-BYTERANGE:<n>[@<o>]` <br> `BYTERANGE=<n>[@<o>]` | The EXT-X-BYTERANGE tag indicates that a Media Segment is a sub-range of the resource identified by its URI.
`EXT_X_SESSION_DATA` | `#EXT-X-SESSION-DATA:<attribute-list>` | The EXT-X-SESSION-DATA tag allows arbitrary session data to be carried in a Master Playlist.
`EXT_X_START` | `#EXT-X-START:<attribute-list>` | The EXT-X-START tag indicates a preferred point at which to start playing a Playlist.
`EXT_X_MEDIA` | `#EXT-X-MEDIA:<attribute-list>` | The EXT-X-MEDIA tag is used to relate Media Playlists that contain alternative Renditions of the same content.
`EXT_X_STREAM_INF` | `#EXT-X-STREAM-INF:<attribute-list>` | The EXT-X-STREAM-INF tag specifies a Variant Stream, which is a set of Renditions that can be combined to play the presentation.
`EXT_X_I_FRAME_STREAM_INF` | `#EXT-X-I-FRAME-STREAM-INF:<attribute-list>` | The EXT-X-I-FRAME-STREAM-INF tag identifies a Media Playlist file containing the I-frames of a multimedia presentation.
`RESOLUTION` | `RESOLUTION=<width>x<height>` | The value is a decimal-resolution describing the optimal pixel resolution at which to display all the video in the Variant Stream.
`[String]` | `CODECS="codec1,codec2,..."` | The value is a quoted-string containing a comma-separated list of formats, where each format specifies a media sample type that is present in one or more Renditions specified by the Variant Stream.
`MediaSegment` |  `#EXTINF`<br>`#EXT-X-BYTERANGE`<br>`#EXT-X-DISCONTINUITY`<br>`#EXT-X-KEY`<br>`#EXT-X-MAP`<br>`#EXT-X-PROGRAM-DATE-TIME`<br>`#EXT-X-DATERANGE`<br>`<URI>` | Specifies a Media Segment.
`VariantStream` | `#EXT-X-STREAM-INF`<br>`<URI>` | Specifies a Variant Stream.

## Custom tags and attributes

You can specify your types for custom tags or attributes with any key decoding strategy to decode your non-standard playlists:

```swift
let m3u8 = """
#EXTM3U
#EXT-CUSTOM-TAG1:1
#EXT-CUSTOM-TAG2:VALUE1=1,VALUE2="Text"
#EXT-CUSTOM-ARRAY:1
#EXT-CUSTOM-ARRAY:2
#EXT-CUSTOM-ARRAY:3
"""

struct CustomAttributes: Decodable {
  let value1: Int
  let value2: String
}

struct CustomPlaylist: Decodable {
  let ext_custom_tag1: Int
  let ext_custom_tag2: CustomAttributes
  let ext_custom_array: [Int]
}

let playlist = try M3U8Decoder().decode(CustomPlaylist.self, from: m3u8)
print(playlist)
```

Prints:

``` swift
CustomPlaylist(
  ext_custom_tag1: 1, 
  ext_custom_tag2: CustomAttributes(
    value1: 1,
    value2: "Text"
  ), 
  ext_custom_array: [1, 2, 3]
)
```

## Combine

`M3U8Decoder` supports `TopLevelDecoder` protocol and can be used with Combine framework:

```swift
struct MasterPlaylist: Decodable {
  let extm3u: Bool
  let ext_x_version: Int
  let ext_x_independent_segments: Bool
  let ext_x_media: [EXT_X_MEDIA]
  let ext_x_i_frame_stream_inf: [EXT_X_I_FRAME_STREAM_INF]
  let streams: [VariantStream]
}

let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
let cancellable = URLSession.shared.dataTaskPublisher(for: url)
  .map(\.data)
  .decode(type: MasterPlaylist.self, decoder: M3U8Decoder())
  .sink (
    receiveCompletion: { print($0) }, // Prints: finished
    receiveValue: { playlist in
      print(playlist) // Prints: MasterPlaylist(extm3u: true, ext_x_version: 6, ext_x_independent_segments: true, ext_x_media: ...
    }
  )
```

## Installation

### XCode

1. Select `Xcode > File > Add Packages...`
2. Add package repository: `https://github.com/ikhvorost/M3U8Decoder.git`
3. Import the package in your source files: `import M3U8Decoder`

### Swift Package

Add `M3U8Decoder` package dependency to your `Package.swift` file:

```swift
let package = Package(
  ...
  dependencies: [
    .package(url: "https://github.com/ikhvorost/M3U8Decoder.git", from: "1.0.0")
  ],
  targets: [
    .target(name: "YourPackage",
      dependencies: [
        .product(name: "M3U8Decoder", package: "M3U8Decoder")
      ]
    ),
  ]
)
```

## License

`M3U8Decoder` is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/donate/?hosted_button_id=TSPDD3ZAAH24C)
