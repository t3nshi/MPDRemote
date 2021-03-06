// ZeroConfExplorer.swift
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


protocol ZeroConfExplorerDelegate : class
{
	func didFindServer(_ server: AudioServer)
}


final class ZeroConfExplorer : NSObject
{
	// MARK: - Public properties
	// Is searching flag
	fileprivate(set) var isSearching = false
	// Services list
	fileprivate(set) var services = [NetService : AudioServer]()
	// Delegate
	weak var delegate: ZeroConfExplorerDelegate?

	// MARK: - Private properties
	// Zeroconf browser
	private var _serviceBrowser: NetServiceBrowser!

	// MARK: - Initializer
	override init()
	{
		super.init()

		self._serviceBrowser = NetServiceBrowser()
		self._serviceBrowser.delegate = self
	}

	deinit
	{
		self._serviceBrowser.delegate = nil
		self._serviceBrowser = nil
	}

	// MARK: - Public
	func searchForServices(type: String, domain: String = "")
	{
		if isSearching
		{
			stopSearch()
		}

		services.removeAll()
		_serviceBrowser.searchForServices(ofType:type, inDomain:domain)
	}

	func stopSearch()
	{
		_serviceBrowser.stop()
	}

	// MARK: - Private
	fileprivate func resolvZeroconfService(service: NetService)
	{
		if let server = services[service] , isResolved(server)
		{
			return
		}

		service.delegate = self
		service.resolve(withTimeout: 5)
	}

	fileprivate func isResolved(_ server: AudioServer) -> Bool
	{
		return String.isNullOrWhiteSpace(server.hostname) == false && server.port != 0
	}
}

// MARK: - NetServiceBrowserDelegate
extension ZeroConfExplorer : NetServiceBrowserDelegate
{
	func netServiceBrowserWillSearch(_ browser: NetServiceBrowser)
	{
		isSearching = true
	}

	func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser)
	{
		isSearching = false
	}

	func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber])
	{
		Logger.shared.log(type: .error, message: "ZeroConf didNotSearch : \(errorDict)")
	}

	func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool)
	{
		services[service] = AudioServer(name: service.name, hostname: "", port: 0, type: .mpd)
		resolvZeroconfService(service: service)
	}

	func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool)
	{
		services[service] = nil
	}
}

// MARK: - NetServiceDelegate
extension ZeroConfExplorer : NetServiceDelegate
{
	func netServiceDidResolveAddress(_ sender: NetService)
	{
		guard let addresses = sender.addresses else {return}

		var found = false
		var tmpIP = ""
		for addressBytes in addresses where found == false
		{
			let inetAddressPointer = (addressBytes as NSData).bytes.assumingMemoryBound(to: sockaddr_in.self)
			var inetAddress = inetAddressPointer.pointee
			if inetAddress.sin_family == sa_family_t(AF_INET)
			{
				let ipStringBuffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
				let ipString = inet_ntop(Int32(inetAddress.sin_family), &inetAddress.sin_addr, ipStringBuffer, UInt32(INET6_ADDRSTRLEN))
				if let ip = String(validatingUTF8: ipString!)
				{
					tmpIP = ip
					found = true
				}
				ipStringBuffer.deallocate(capacity: Int(INET6_ADDRSTRLEN))
			}
			else if inetAddress.sin_family == sa_family_t(AF_INET6)
			{
				let inetAddressPointer6 = (addressBytes as NSData).bytes.assumingMemoryBound(to: sockaddr_in6.self)
				var inetAddress6 = inetAddressPointer6.pointee
				let ipStringBuffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
				let ipString = inet_ntop(Int32(inetAddress6.sin6_family), &inetAddress6.sin6_addr, ipStringBuffer, UInt32(INET6_ADDRSTRLEN))
				if let ip = String(validatingUTF8: ipString!)
				{
					tmpIP = ip
					found = true
				}
				ipStringBuffer.deallocate(capacity: Int(INET6_ADDRSTRLEN))
			}

			if found
			{
				let server = AudioServer(name: sender.name, hostname: tmpIP, port: UInt16(sender.port), type: .mpd)
				services[sender] = server
				delegate?.didFindServer(server)
			}
		}
	}

	func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber])
	{
	}

	func netServiceDidStop(_ sender: NetService)
	{
	}
}
