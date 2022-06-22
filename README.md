[![Swift 5](https://img.shields.io/badge/Swift-5-f48041.svg?style=flat)](https://developer.apple.com/swift)
![Platforms: iOS, macOS, tvOS, watchOS](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20-blue.svg?style=flat)
[![Swift Package Manager: compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)
[![Build](https://github.com/ikhvorost/M3U8Decoder/actions/workflows/swift.yml/badge.svg)](https://github.com/ikhvorost/M3U8Decoder/actions/workflows/swift.yml)
[![codecov](https://codecov.io/gh/ikhvorost/M3U8Decoder/branch/main/graph/badge.svg?token=fa2mCNbfuM)](https://codecov.io/gh/ikhvorost/M3U8Decoder)
[![Swift Doc Coverage](https://img.shields.io/badge/Swift%20Doc%20Coverage-100%25-f39f37)](https://github.com/SwiftDocOrg/swift-doc)

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/donate/?hosted_button_id=TSPDD3ZAAH24C)

<p align="center">
<img src="m3u8decoder.png" alt="M3U8Decoder: Flexible M3U8 playlist parsing for Swift." width="350">
</p>

# M3U8Decoder 

Decoder for Media Playlist of [HTTP Live Streaming](https://datatracker.ietf.org/doc/html/rfc8216) using `Decodable` protocol.

- [Overview](#overview)
- [Key decoding strategy](#key-decoding-strategy)
- [Data decoding strategy](#data-decoding-strategy)
- [Predefined types](#predefined-types)
- [Custom tags and attributes](#custom-tags-and-attributes)
- [Combine](#combine)
- [async\/await](#asyncawait)
- [Installation](#installation)
- [License](#license)

## Overview

The example below shows how to decode an instance of a simple `Playlist` type from a provided text of Media Playlist. The type adopts `Decodable` so that it’s decodable using a `M3U8Decoder` instance.

```swift
import M3U8Decoder

struct Playlist: Decodable {
    let extm3u: Bool
    let ext_x_version: Int
    let ext_x_targetduration: Int
    let ext_x_media_sequence: Int
    let extinf: [EXTINF]
    let uri: [String]
}

let m3u8 = """
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-TARGETDURATION:10
#EXT-X-MEDIA-SEQUENCE:2680

#EXTINF:13.333,Sample artist - Sample title
http://example.com/low.m3u8
"""

let decoder = M3U8Decoder()
let playlist = try decoder.decode(Playlist.self, from: m3u8)
    
print(playlist.extm3u) // Prints "true"
print(playlist.ext_x_version) // Prints "7"
print(playlist.ext_x_targetduration) // Prints "10"
print(playlist.ext_x_media_sequence) // Prints "2680"
print(playlist.extinf[0].duration) // Prints "13.33"
print(playlist.extinf[0].title!) // Prints ""Sample artist - Sample title""
print(playlist.uri[0]) // Prints "http://example.com/low.m3u8"
```

Where:
-  `EXTINF` is predefined type for `#EXTINF` playlist tag. (See  [Predefined types](#predefined-types))
- `uri` contains all URI lines that identifies a Media Segments or a Playlist files.

`M3U8Decoder` can also decode from `Data` and `URL` instances both synchonously and asynchronously e.g.:

```swift
import M3U8Decoder

struct MasterPlaylist: Decodable {
    let extm3u: Bool
    let ext_x_version: Int
    let ext_x_independent_segments: Bool
    let ext_x_media: [EXT_X_MEDIA]
    let ext_x_stream_inf: [EXT_X_STREAM_INF]
    let ext_x_i_frame_stream_inf: [EXT_X_I_FRAME_STREAM_INF]
    let uri: [String]

    var variantStreams: [(inf: EXT_X_STREAM_INF, uri: String)] {
        Array(zip(ext_x_stream_inf, uri))
    }
}

let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
let decoder = M3U8Decoder()
decoder.decode(MasterPlaylist.self, from: url) { result in
    switch result {
    case let .success(playlist):
        print(playlist.ext_x_independent_segments) // Prints "true"
        
        print(playlist.variantStreams.count) // Prints "24"
        print(playlist.variantStreams[0].inf.average_bandwidth!) // Prints "2168183"
        print(playlist.variantStreams[0].inf.resolution!) // Prints "RESOLUTION(width: 960, height: 540)"
        print(playlist.variantStreams[0].inf.frame_rate!) // Prints "60.0"
        print(playlist.variantStreams[0].uri) // Prints "v5/prog_index.m3u8"
        
    case let .failure(error):
        print(error)
    }
}
```

## Key decoding strategy

The strategy to use for automatically changing the value of keys before decoding.

### `snakeCase`

It's **default** strategy to convert playlist tag and attribute names to snake case.

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
    let language: String?
    let instreamId: String?
}
    
struct Playlist: Decodable {
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

let playlist = try decoder.decode(Playlist.self, from: m3u8)    
print(playlist.extXVersion) // Prints "7"
print(playlist.extXIndependentSegments) // Prints "true"
print(playlist.extXMedia[0].type) // Prints "CLOSED-CAPTIONS"
print(playlist.extXMedia[0].groupId) // Prints "cc"
```

### `custom((_ key: String) -> String)`

Provide a custom conversion from a tag or attribute name in the playlist to the keys specified by the provided function.

```swift
struct Media: Decodable {
    let type: String
    let group_id: String
    let name: String
    let language: String?
    let instream_id: String?
}
    
struct Playlist: Decodable {
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

// `EXT-X-INDEPENDENT-SEGMENTS` bacomes `independent_segments`
decoder.keyDecodingStrategy = .custom { key in
    key
        .lowercased()
        .replacingOccurrences(of: "ext", with: "")
        .replacingOccurrences(of: "-x-", with: "")
        .replacingOccurrences(of: "-", with: "_")
}
    
let playlist = try decoder.decode(Playlist.self, from: m3u8)
print(playlist.version) // Prints "7"
print(playlist.independent_segments) // Prints "true"
print(playlist.media[0].type) // Prints "CLOSED-CAPTIONS"
print(playlist.media[0].group_id) // Prints "cc"
```

## Data decoding strategy

The strategy to use for decoding `Data` values.

### `hex`

Decode the `Data` from a hex string (e.g. `0xa2c4f622...`). This is the default strategy.

Decoding `#EXT-X-KEY` tag with `IV` attribute where data is represented in hex string:

```swift
struct Playlist: Decodable {
    let extm3u: Bool
    let ext_x_version: Int
    let ext_x_key: EXT_X_KEY
    let extinf: [EXTINF]
    let uri: [String]
}

let m3u8 = """
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-KEY:METHOD=SAMPLE-AES,URI="skd://vod.domain.com/fairplay/d1acadbf70824d178601c2e55675b3b3",IV=0X99b74007b6254e4bd1c6e03631cad15b
#EXTINF:10,
http://example.com/low.m3u8
"""

let playlist = try M3U8Decoder().decode(Playlist.self, from: m3u8)

print(playlist.ext_x_version) // Prints "7"
print(playlist.ext_x_key.method) // Prints "SAMPLE-AES"
print(playlist.ext_x_key.uri) // Prints "skd://vod.domain.com/fairplay/d1acadbf70824d178601c2e55675b3b3"
print(playlist.ext_x_key.iv!) // Prints "16 bytes"
```

### `base64`

Decode the `Data` from a Base64-encoded string.

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
print(playlist.ext_x_version) // Prints "7"
print(playlist.ext_data) // Prints "13 bytes"
print(String(data: playlist.ext_data, encoding: .utf8)!) // Prints "Hello Base64!"
```

## Predefined types

There are a list of default predifined sctructs (with `snakeCase` key coding strategy) for all medata tags and attributes from of [HTTP Live Streaming](https://datatracker.ietf.org/doc/html/rfc8216) document that can be used to decode playlists.

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

Implementations of these structs you can look at [M3U8Tags.swift](Sources/M3U8Decoder/M3U8Tags.swift) but anyway you can make and use your own ones to decode your playlists.

## Custom tags and attributes

You can specify your types for custom tags or attributes with any key decodig strategy to decode your non-standard playlists:

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

do {
    let playlist = try M3U8Decoder().decode(CustomPlaylist.self, from: m3u8)
    
    print(playlist.ext_custom_tag1) // Prints "1"
    print(playlist.ext_custom_tag2) // Prints "CustomAttributes(value1: 1, value2: 'Text')"
    print(playlist.ext_custom_array) // Prints "[1, 2, 3]"
}
catch {
    print(error.description)
}
```

## Combine

`M3U8Decoder` supporst `TopLevelDecoder` protocol and can be used with Combine framework:

```swift
struct MasterPlaylist: Decodable {
    let extm3u: Bool
    let ext_x_version: Int
    let ext_x_independent_segments: Bool
    let ext_x_media: [EXT_X_MEDIA]
    let ext_x_stream_inf: [EXT_X_STREAM_INF]
    let ext_x_i_frame_stream_inf: [EXT_X_I_FRAME_STREAM_INF]
    let uri: [String]
}
    
var cancellable: Cancellable?

let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
cancellable = URLSession.shared.dataTaskPublisher(for: url)
    .map(\.data)
    .decode(type: MasterPlaylist.self, decoder: M3U8Decoder())
    .sink (
        receiveCompletion: { print("Received completion: \($0)") },
        receiveValue: { playlist in
            print("Version:", playlist.ext_x_version)
            print("Independent segments:", playlist.ext_x_independent_segments)
            print("EXT-X-MEDIA[0]:", playlist.ext_x_media[0])
            print("URI[0]:", playlist.uri[0])
        }
    )
```

Outputs:

```
Version: 6
Independent segments: true
EXT-X-MEDIA[0]: EXT_X_MEDIA(type: "AUDIO", group_id: "aud1", name: "English", language: Optional("en"), assoc_language: nil, autoselect: Optional(true), default: Optional(true), instream_id: nil, channels: Optional("2"), forced: nil, uri: Optional("a1/prog_index.m3u8"), characteristics: nil)
URI[0]: v5/prog_index.m3u8
Received completion: finished
```

> NOTE: Combine is avaliable from macOS 10.15, iOS 13.0, watchOS 6.0 and tvOS 13.0.


## async/await

With `M3U8Decoder` you can decode your data asynchronously with `async`/`await` e.g.:

```swift
struct MasterPlaylist: Decodable {
    let extm3u: Bool
    let ext_x_version: Int
    let ext_x_independent_segments: Bool
    let ext_x_media: [EXT_X_MEDIA]
    let ext_x_stream_inf: [EXT_X_STREAM_INF]
    let ext_x_i_frame_stream_inf: [EXT_X_I_FRAME_STREAM_INF]
    let uri: [String]
}

Task {
    do {
        let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
        let playlist = try await M3U8Decoder().decode(MasterPlaylist.self, from: url)
        
        print("Version:", playlist.ext_x_version)
        print("Independent segments:", playlist.ext_x_independent_segments)
        print("EXT-X-MEDIA[0]:", playlist.ext_x_media[0])
        print("URI[0]:", playlist.uri[0])
    }
    catch {
        print(error.description)
    }
}
```

Outputs:

```
Version: 6
Independent segments: true
EXT-X-MEDIA[0]: EXT_X_MEDIA(type: "AUDIO", group_id: "aud1", name: "English", language: Optional("en"), assoc_language: nil, autoselect: Optional(true), default: Optional(true), instream_id: nil, channels: Optional("2"), forced: nil, uri: Optional("a1/prog_index.m3u8"), characteristics: nil)
URI[0]: v5/prog_index.m3u8
```

> NOTE: Asynchonous decoding is avaliable from macOS 10.15, iOS 13.0, watchOS 6.0 and tvOS 13.0.

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
        ...
    ...
)
```

## License

`M3U8Decoder` is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/donate/?hosted_button_id=TSPDD3ZAAH24C)