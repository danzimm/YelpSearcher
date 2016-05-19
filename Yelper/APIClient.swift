//
//  APIClient.swift
//  Yelper
//
//  Created by Dan Zimmerman on 5/19/16.
//  Copyright © 2016 Dan Zimmerman. All rights reserved.
//

import OAuthSwift
import ReactiveCocoa

extension NSData {
	var jsonValue: AnyObject? {
		return try? NSJSONSerialization.JSONObjectWithData(self, options: NSJSONReadingOptions())
	}
}

struct APIClient {
	enum Error: ErrorType {
		case Parsing(NSData)
		case Networking(String)
		case Underlying(NSError)
		case Unknown(String)
	}
	
	static let client = APIClient()
	
	private let baseURL = "https://api.yelp.com/v2"
	private let defaultHeaders: [String: String]
	private let client: OAuthSwiftClient
	
	private init() {
		self.defaultHeaders = [
			"Accept": "application/json"
		]
		self.client = OAuthSwiftClient(
			consumerKey: "ZrwAb22G2T-eUDq2Qi2NlA",
			consumerSecret: "3oWIPEuwipQVc9T7W-E00dXeKmI",
			accessToken: "rAHuplMsPMhATO007q5hG9-a3eO1PCYC",
			accessTokenSecret: "lqjThtFiCfpiQfTfH8WoEy0CcRc")
	}
	
	func GET(path: String,
	         parameters: [String: AnyObject] = [:],
	         headers: [String: String] = [:]) -> SignalProducer<(NSData, NSHTTPURLResponse), Error> {
		return SignalProducer { observer, disposable in
			// TODO(danzimm): OAuthSwift isn't good - can't cancel, doesn't have same mapping ability as
			// alamofire. Look to move to use AF and then implement your own oauth stuff
			self.client.get("\(self.baseURL)/\(path)",
				parameters: parameters,
				headers: headers + self.defaultHeaders,
				success: observer.sendNext,
				failure: { (error) in
					observer.sendFailed(.Underlying(error))
				})
		}
	}
	
	func search(query: String, location: String = "Chicago") -> SignalProducer<(NSData, NSHTTPURLResponse), Error> {
		let params = [
			"location": location,
			"term": query
		]
		return GET("search", parameters: params)
	}
}
