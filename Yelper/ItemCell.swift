//
//  ItemCell.swift
//  Yelper
//
//  Created by Dan Zimmerman on 5/19/16.
//  Copyright © 2016 Dan Zimmerman. All rights reserved.
//

import ReactiveCocoa
import UIKit

class ItemCell: UICollectionViewCell {
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var label: UILabel!
	
	var item: Item? {
		willSet {
			imageView.image = nil
			label.text = nil
		}
		didSet {
			label.text = item?.title
			item?.image
				.takeUntil(prepareForReuseProducer)
				.observeOn(UIScheduler())
				.startWithNext { [unowned self] image in
					self.imageView.image = image
				}
		}
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		item = nil
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		imageView.layer.cornerRadius = 5
	}
}
