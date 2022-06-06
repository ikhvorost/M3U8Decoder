[![Swift 5](https://img.shields.io/badge/Swift-5-f48041.svg?style=flat)](https://developer.apple.com/swift)
![Platforms: iOS, macOS, tvOS, watchOS](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20-blue.svg?style=flat)
[![Swift Package Manager: compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)
[![Build](https://github.com/ikhvorost/M3U8Decoder/actions/workflows/swift.yml/badge.svg)](https://github.com/ikhvorost/M3U8Decoder/actions/workflows/swift.yml)
[![codecov](https://codecov.io/gh/ikhvorost/M3U8Decoder/branch/main/graph/badge.svg?token=fa2mCNbfuM)](https://codecov.io/gh/ikhvorost/M3U8Decoder)
[![Swift Doc Coverage](https://img.shields.io/badge/Swift%20Doc%20Coverage-100%25-f39f37)](https://github.com/SwiftDocOrg/swift-doc)

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/donate/?hosted_button_id=TSPDD3ZAAH24C)

```
███╗   ███╗ ██████╗  ██╗   ██╗  █████╗ 
████╗ ████║ ╚════██╗ ██║   ██║ ██╔══██╗
██╔████╔██║  █████╔╝ ██║   ██║ ╚█████╔╝
██║╚██╔╝██║  ╚═══██╗ ██║   ██║ ██╔══██╗
██║ ╚═╝ ██║ ██████╔╝ ╚██████╔╝ ╚█████╔╝
╚═╝     ╚═╝ ╚═════╝   ╚═════╝   ╚════╝ 
                DECODER
```

# M3U8Decoder

Decoder for Media Playlist of [HTTP Live Streaming](https://datatracker.ietf.org/doc/html/rfc8216) using `Decodable` protocol.

- [Overview](#overview)
- [KeyDecodingStrategy](#keydecodingstrategy)
- [Predefined types](#predefinedtypes)
- [Custom tags](#customtags)
- [Combine](#combine)
- [Async](#async)
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
-  `EXTINF` is predefined type for `#EXTINF` playlist tag. (See  [Predefined types](#predefinedtypes))
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

## KeyDecodingStrategy

The strategy to use for automatically changing the value of keys before decoding.

### `snakeCase`
Converting playlist tag and attribute names to snake case. It's default strategy.

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