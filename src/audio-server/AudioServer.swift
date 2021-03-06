// AudioServer.swift
// Copyright (c) 2017 Nyx0uf
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import Foundation


enum AudioServerType : Int, Codable
{
	case mpd
}


final class AudioServer : Codable
{
	// MARK: - Public properties
	// Server name
	var name: String
	// Server IP / hostname
	var hostname: String
	// Server port
	var port: UInt16
	// Server password
	var password: String = ""
	// Audio server type, only mpd supported for now
	var type: AudioServerType = .mpd

	private enum AudioServerCodingKeys: String, CodingKey
	{
		case name
		case hostname
		case port
		case password
		case type
	}

	// MARK: - Initializers
	init(name: String, hostname: String, port: UInt16, type: AudioServerType)
	{
		self.name = name
		self.hostname = hostname
		self.port = port
		self.type = type
	}

	init(name: String, hostname: String, port: UInt16, password: String, type: AudioServerType)
	{
		self.name = name
		self.hostname = hostname
		self.port = port
		self.password = password
		self.type = type
	}

	required convenience init(from decoder: Decoder) throws
	{
		let values = try decoder.container(keyedBy: AudioServerCodingKeys.self)
		let na = try values.decode(String.self, forKey: .name)
		let ho = try values.decode(String.self, forKey: .hostname)
		let po = try values.decode(UInt16.self, forKey: .port)
		let pa = try values.decode(String.self, forKey: .password)
		let ty = try values.decode(Int.self, forKey: .type)

		self.init(name: na, hostname: ho, port: po, password: pa, type: AudioServerType(rawValue: ty)!)
	}

	public func publicDescription() -> String
	{
		return "\(self.hostname)\n\(self.port)\n"
	}
}

// MARK: - Operators
func == (lhs: AudioServer, rhs: AudioServer) -> Bool
{
	return (lhs.name == rhs.name && lhs.hostname == rhs.hostname && lhs.port == rhs.port && lhs.password == rhs.password)
}
