//  M3U8Tags.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2022/05/31.
//  Copyright © 2022 Iurii Khvorost. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

// MARK: - Media Playlist Tags

/// The EXT-X-MAP tag specifies how to obtain the Media Initialization Section (Section 3) required to parse the applicable Media Segments.
///
///     #EXT-X-MAP:<attribute-list>
///
/// RFC: https://datatracker.ietf.org/doc/html/rfc8216#section-4.3.2.5
public struct EXT_X_MAP: Decodable {
    /// The value is a quoted-string containing a URI that identifies a resource that contains the Media Initialization Section. This attribute is REQUIRED.
    public let uri: String
    /// The value is a quoted-string specifying a byte range into the resource identified by the URI attribute. This attribute is OPTIONAL.
    public let byterange: EXT_X_BYTERANGE?
}

/// Media Segments MAY be encrypted. The EXT-X-KEY/EXT_X_SESSION_KEY tag specifies how to decrypt them.
///
///     #EXT-X-KEY:<attribute-list>
///     #EXT_X_SESSION_KEY:<attribute-list>
///
/// RFC: https://datatracker.ietf.org/doc/html/rfc8216#section-4.3.2.4
public struct EXT_X_KEY: Decodable {
    /// The value is an enumerated-string that specifies the encryption method. This attribute is REQUIRED.
    public let method: String
    /// The value is a quoted-string that specifies how the key is represented in the resource identified by the URI. This attribute is OPTIONAL.
    public let keyformat: String?
    /// The value is a quoted-string containing one or more positive integers separated by the "/" character (for example, "1", "1/2", or "1/2/5"). This attribute is OPTIONAL.
    public let keyformatversions: String?
    /// The value is a quoted-string containing a URI that specifies how to obtain the key. This attribute is REQUIRED unless the METHOD is NONE.
    public let uri: String
    /// The value is a hexadecimal-sequence that specifies a 128-bit unsigned integer Initialization Vector to be used with the key.
    public let iv: String?
}

/// The EXT-X-DATERANGE tag associates a Date Range (i.e., a range o time defined by a starting and ending date) with a set of attribute value pairs.
///
///     #EXT-X-DATERANGE:<attribute-list>
///
/// RFC: https://datatracker.ietf.org/doc/html/rfc8216#section-4.3.2.7
public struct EXT_X_DATERANGE: Decodable {
    /// A quoted-string that uniquely identifies a Date Range in the Playlist. This attribute is REQUIRED.
    public let id: String
    /// A client-defined quoted-string that specifies some set of attributes and their associated value semantics. This attribute is OPTIONAL.
    public let `class`: String?
    /// A client-defined quoted-string that specifies some set of attributes and their associated value semantics. This attribute is REQUIRED.
    public let start_date: Date
    /// A quoted-string containing the ISO-8601 date at which the Date Range ends. This attribute is OPTIONAL.
    public let end_date: Date?
    /// The duration of the Date Range expressed as a decimal-floating-point number of seconds. This attribute is OPTIONAL.
    public let duration: Double?
    /// The expected duration of the Date Range expressed as a decimal-floating-point number of seconds. It is OPTIONAL.
    public let planned_duration: Double?
    /// Used to carry SCTE-35 data. It is OPTIONAL.
    public let scte35_cmd: String?
    /// Used to carry SCTE-35 data. It is OPTIONAL.
    public let scte35_out: String?
    /// Used to carry SCTE-35 data. It is OPTIONAL.
    public let scte35_in: String?
    /// An enumerated-string whose value MUST be YES. This attribute is OPTIONAL.
    public let end_on_next: Bool?
}

/// The EXTINF tag specifies the duration of a Media Segment.
///
///     #EXTINF:<duration>,[<title>]
///
/// RFC: https://datatracker.ietf.org/doc/html/rfc8216#section-4.3.2.1
public struct EXTINF: Decodable {
    /// Specifies the duration of the Media Segment in seconds. This attribute is REQUIRED.
    public let duration: Double
    /// Human-readable informative title of the Media Segment. This attribute is OPTIONAL.
    public let title: String?
}

/// The EXT-X-BYTERANGE tag indicates that a Media Segment is a sub-range of the resource identified by its URI.
///
///     #EXT-X-BYTERANGE:<n>[@<o>]
///
/// RFC: https://datatracker.ietf.org/doc/html/rfc8216#section-4.3.2.2
public struct EXT_X_BYTERANGE: Decodable {
    /// n is a decimal-integer indicating the length of the sub-range in bytes. This attribute is REQUIRED.
    public let length: Int
    /// o is a decimal-integer indicating the start of the sub-range, as a byte offset from the beginning of the resource. This attribute is OPTIONAL.
    public let start: Int?
}

// MARK: - Master Playlist Tags

/// The EXT-X-SESSION-DATA tag allows arbitrary session data to be carried in a Master Playlist.
///
///     #EXT-X-SESSION-DATA:<attribute-list>
///
/// RFC: https://datatracker.ietf.org/doc/html/rfc8216#section-4.3.4.4
public struct EXT_X_SESSION_DATA: Decodable {
    /// The value of DATA-ID is a quoted-string that identifies a particular data value. This attribute is REQUIRED.
    public let data_id: String
    /// VALUE is a quoted-string.  It contains the data identified by DATA-ID. This attribute is REQUIRED.
    public let value: String
    /// The value is a quoted-string containing a URI. This attribute is REQUIRED.
    public let uri: String
    /// The value is a quoted-string containing a language tag that identifies the language of the VALUE.  This attribute is OPTIONAL.
    public let language: String?
}

/// The EXT-X-START tag indicates a preferred point at which to start playing a Playlist.
///
///     #EXT-X-START:<attribute-list>
///
/// RFC: https://datatracker.ietf.org/doc/html/rfc8216#section-4.3.5.2
public struct EXT_X_START: Decodable {
    /// The value of TIME-OFFSET is a signed-decimal-floating-point number of seconds. This attribute is REQUIRED.
    public let time_offset: Int
    /// The value is an enumerated-string; valid strings are YES and NO. This attribute is OPTIONAL.
    public let precise: Bool?
}

/// The EXT-X-MEDIA tag is used to relate Media Playlists that contain alternative Renditions of the same content.
///
///     #EXT-X-MEDIA:<attribute-list>
///
/// RFC: https://datatracker.ietf.org/doc/html/rfc8216#section-4.3.4.1
public struct EXT_X_MEDIA: Decodable {
    /// The value is an enumerated-string; valid strings are AUDIO, VIDEO, SUBTITLES, and CLOSED-CAPTIONS. This attribute is REQUIRED.
    public let type: String
    /// The value is a quoted-string that specifies the group to which the Rendition belongs. This attribute is REQUIRED.
    public let group_id: String
    /// The value is a quoted-string containing a human-readable description of the Rendition. This attribute is REQUIRED.
    public let name: String
    /// The value is a quoted-string containing one of the standard Tags for Identifying Languages, which identifies the primary language used in the Rendition. This attribute is OPTIONAL.
    public let language: String?
    /// The value is a quoted-string containing a language tag that identifies a language that is associated with the Rendition. This attribute is OPTIONAL.
    public let assoc_language: String?
    /// The value is an enumerated-string; valid strings are YES and NO. This attribute is OPTIONAL.
    public let autoselect: Bool?
    /// The value is an enumerated-string; valid strings are YES and NO. This attribute is OPTIONAL.
    public let `default`: Bool?
    /// The value is a quoted-string that specifies a Rendition within the segments in the Media Playlist. This attribute is OPTIONAL.
    public let instream_id: String?
    /// The value is a quoted-string that specifies an ordered, backslash-separated ("/") list of parameters. This attribute is OPTIONAL.
    public let channels: String?
    /// The value is an enumerated-string; valid strings are YES and NO. This attribute is OPTIONAL.
    public let forced: Bool?
    /// The value is a quoted-string containing a URI that identifies the Media Playlist file. This attribute is OPTIONAL.
    public let uri: String?
    /// The value is a quoted-string containing one or more Uniform Type Identifiers [UTI] separated by comma (,) characters. This attribute is OPTIONAL.
    public let characteristics: String?
}

/// The value is a decimal-resolution describing the optimal pixel resolution at which to display all the video in the Variant Stream.
///
///     RESOLUTION=<width>x<height>
///
/// RFC: https://datatracker.ietf.org/doc/html/rfc8216#section-4.3.4.2
public struct RESOLUTION: Decodable {
    /// Width of a video.
    public let width: Int
    /// Height of a video.
    public let height: Int
}

/// The EXT-X-STREAM-INF tag specifies a Variant Stream, which is a set of Renditions that can be combined to play the presentation.
///
///     #EXT-X-STREAM-INF:<attribute-list>
///
/// RFC: https://datatracker.ietf.org/doc/html/rfc8216#section-4.3.4.2
public struct EXT_X_STREAM_INF: Decodable {
    /// The value is a decimal-integer of bits per second. This attribute is REQUIRED.
    public let bandwidth: Int
    /// The value is a decimal-integer of bits per second. This attribute is OPTIONAL.
    public let average_bandwidth: Int?
    /// The value is a quoted-string containing a comma-separated list of formats, where each format specifies a media sample type that is present in one or more Renditions specified by the Variant Stream. This attribute is REQUIRED.
    public let codecs: String
    /// The value is a decimal-resolution describing the optimal pixel resolution at which to display all the video in the Variant Stream. This attribute is OPTIONAL.
    public let resolution: RESOLUTION?
    /// The value is a decimal-floating-point describing the maximum frame rate for all the video in the Variant Stream, rounded to three decimal places. This attribute is OPTIONAL.
    public let frame_rate: Double?
    /// The value is an enumerated-string; valid strings are TYPE-0 and NONE. This attribute is OPTIONAL.
    public let hdcp_level: String?
    /// The value is a quoted-string. This attribute is OPTIONAL.
    public let audio: String?
    /// The value is a quoted-string. This attribute is OPTIONAL.
    public let video: String?
    /// The value is a quoted-string. This attribute is OPTIONAL.
    public let subtitles: String?
    /// The value can be either a quoted-string or an enumerated-string with the value NONE. This attribute is OPTIONAL.
    public let closed_captions: String?
}

/// The EXT-X-I-FRAME-STREAM-INF tag identifies a Media Playlist file containing the I-frames of a multimedia presentation.
///
///     #EXT-X-I-FRAME-STREAM-INF:<attribute-list>
///
/// RFC: https://datatracker.ietf.org/doc/html/rfc8216#section-4.3.4.3
public struct EXT_X_I_FRAME_STREAM_INF: Decodable {
    /// The value is a decimal-integer of bits per second. This attribute is REQUIRED.
    public let bandwidth: Int
    /// The value is a decimal-integer of bits per second. This attribute is OPTIONAL.
    public let average_bandwidth: Int?
    /// The value is a quoted-string containing a comma-separated list of formats, where each format specifies a media sample type that is present in one or more Renditions specified by the Variant Stream. This attribute is REQUIRED.
    public let codecs: String
    /// The value is a decimal-resolution describing the optimal pixel resolution at which to display all the video in the Variant Stream. This attribute is OPTIONAL.
    public let resolution: RESOLUTION?
    /// The value is an enumerated-string; valid strings are TYPE-0 and NONE. This attribute is OPTIONAL.
    public let hdcp_level: String?
    /// The value is a quoted-string. This attribute is OPTIONAL.
    public let video: String?
    /// The value is a quoted-string containing a URI that identifies the I-frame Media Playlist file. This attribute is REQUIRED.
    public let uri: String
}
