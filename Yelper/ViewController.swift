//
//  ViewController.swift
//  Yelper
//
//  Created by Dan Zimmerman on 5/19/16.
//  Copyright © 2016 Dan Zimmerman. All rights reserved.
//

import ReactiveCocoa
import Result
import UIKit

extension NSError {
	static var unknown: NSError {
		return NSError(domain: "Unknown", code: 37, userInfo: nil)
	}
}

struct Item {
	enum ImageFetchError: ErrorType {
		case Underlying(NSError)
		case CreatingImage
		case Unknown
	}
	
	let title: String
	let image: SignalProducer<UIImage, ImageFetchError>
	
	init(title: String, imageURL: NSURL) {
		self.title = title
		self.image = SignalProducer { observer, disposable in
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
				NSURLSession.sharedSession()
					.dataTaskWithURL(imageURL) { (data, resp, error) in
						guard let data = data where resp != nil else {
							if let error = error {
								observer.sendFailed(.Underlying(error))
							} else {
								observer.sendFailed(.Unknown)
							}
							return
						}
						guard let image = UIImage(data: data) else {
							observer.sendFailed(.CreatingImage)
							return
						}
						observer.sendNext(image)
						observer.sendCompleted()
					}
					.resume()
			}
		}
	}
}

class ViewController: UIViewController {
	@IBOutlet var collectionView: UICollectionView!
	
	private var items: [Item] = [] {
		didSet {
			self.collectionView.reloadData()
		}
	}
	
	private let searchTextObserver: Observer<String?, NoError>
	private let searchTextProducer: SignalProducer<String?, NoError>
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		(self.searchTextProducer, self.searchTextObserver) = SignalProducer.buffer(1)
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		(self.searchTextProducer, self.searchTextObserver) = SignalProducer.buffer(1)
		super.init(coder: aDecoder)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		searchTextProducer
			.takeUntil(willDeallocProducer)
			.observeOn(UIScheduler())
			.startWithNext { [unowned self] query in
				if let query = query {
					APIClient.client.search(query)
						.takeUntil(self.willDeallocProducer)
						.map { $0.0.jsonValue as? [String: AnyObject] }
						.filter { $0 != nil }
						.map { $0!["businesses"] as? [AnyObject] }
						.filter { $0 != nil }
						.map { businesses -> [Item] in
							return businesses!.flatMap { object in
								return (object as? [String: AnyObject])
									.flatMap { dict in
										guard
											let name = dict["name"] as? String,
												image = dict["image_url"] as? String,
												imageURL = NSURL(string: image) else {
													return nil
												}
										return Item(title: name, imageURL: imageURL)
									}
							}
						}
						.observeOn(UIScheduler())
						.startWithNext { [unowned self] items in
							self.items = items
						}
				} else {
					self.items = []
				}
			}
		searchTextObserver.sendNext(nil)
		
		collectionView.backgroundColor = .whiteColor()
		view.backgroundColor = .whiteColor()
	}
}

extension ViewController: UICollectionViewDataSource {
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return items.count
	}
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(collectionView: UICollectionView,
	                    cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ItemCell", forIndexPath: indexPath) as! ItemCell
		cell.item = items[indexPath.row]
		return cell
	}
}

extension ViewController: UISearchBarDelegate {
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		searchTextObserver.sendNext(searchText)
	}
	
	func searchBarTextDidEndEditing(searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
}

