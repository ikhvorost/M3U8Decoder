//  MediaPlaylist.swift
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

/// The EXT-X-MAP tag specifies how to obtain the Media Initialization Section required to parse the applicable Media Segments.
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
  public let iv: Data?
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

public struct MediaSegment: Decodable {
  public let extinf: EXTINF
  public let ext_x_byterange: EXT_X_BYTERANGE?
  public let ext_x_discontinuity: Bool?
  public let ext_x_key: EXT_X_KEY?
  public let ext_x_map: EXT_X_MAP?
  public let ext_x_program_date_time: Date?
  public let ext_x_daterange: EXT_X_DATERANGE?
  public let uri: String
}
