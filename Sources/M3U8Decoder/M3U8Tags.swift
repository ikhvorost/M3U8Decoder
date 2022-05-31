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

// #EXT-X-MAP:<attribute-list> - URI, BYTERANGE
public struct EXT_X_MAP: Decodable {
    public let uri: String
    public let byterange: EXT_X_BYTERANGE
}

// #EXT-X-KEY:<attribute-list> - METHOD, URI, IV, KEYFORMAT, KEYFORMATVERSIONS
public struct EXT_X_KEY: Decodable {
    public let method: String
    public let keyformat: String
    public let keyformatversions: Int
    public let uri: String
    public let iv: String?
}

public struct EXT_X_DATERANGE: Decodable {
    public let id: String
    public let `class`: String
    public let start_date: Date
    public let end_date: Date
    public let duration: Double
    public let planned_duration: Double
    public let x_com_example_ad_id: String
    public let scte35_out: String // SCTE35-CMD, SCTE35-OUT, SCTE35-IN
    public let end_on_next: Bool
}

// #EXTINF:<duration>,[<title>]
public struct EXTINF: Decodable {
    public let duration: Double
    public let title: String?
}

// #EXT-X-BYTERANGE:<n>[@<o>]
public struct EXT_X_BYTERANGE: Decodable {
    public let length: Int
    public let start: Int?
}

// MARK: - Master Playlist Tags

public struct EXT_X_SESSION_DATA: Decodable {
    public let data_id: String
    public let value: String
    public let uri: String
    public let language: String
}

public struct EXT_X_SESSION_KEY: Decodable {
    public let method: String
    public let keyformat: String
    public let keyformatversions: Int
    public let uri: String
}

public struct EXT_X_START: Decodable {
    public let time_offset: Int
    public let precise: Bool
}

public struct EXT_X_MEDIA: Decodable {
    public let type: String
    public let group_id: String
    public let name: String
    public let language: String
    public let assoc_language: String?
    public let autoselect: Bool?
    public let `default`: Bool?
    public let instream_id: String?
    public let channels: Int?
    public let forced: Bool?
    public let uri: String?
    public let characteristics: String?
}

public struct RESOLUTION: Decodable {
    public let width: Int
    public let height: Int
}

public struct EXT_X_I_FRAME_STREAM_INF: Decodable {
    public let bandwidth: Int
    public let average_bandwidth: Int?
    public let resolution: RESOLUTION
    public let codecs: String
    public let uri: String
}

public struct EXT_X_STREAM_INF: Decodable {
    public let bandwidth: Int
    public let average_bandwidth: Int
    public let codecs: String
    public let resolution: RESOLUTION
    public let frame_rate: Double
    public let hdcp_level: String?
    public let audio: String?
    public let video: String?
    public let subtitles: String?
    public let closed_captions: String
}
