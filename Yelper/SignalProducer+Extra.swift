//
//  SignalProducer+Extra.swift
//  Yelper
//
//  Created by Dan Zimmerman on 5/19/16.
//  Copyright © 2016 Dan Zimmerman. All rights reserved.
//

import ReactiveCocoa
import Result

extension NSObject {
	var willDeallocProducer: SignalProducer<(), NoError> {
		return rac_willDeallocSignal()
			.toSignalProducer()
			.map { _ in () }
			.flatMapError { _ in SignalProducer(value: ()) }
	}
}

extension UICollectionViewCell {
	var prepareForReuseProducer: SignalProducer<(), NoError> {
		return rac_prepareForReuseSignal
			.toSignalProducer()
			.map { _ in () }
			.flatMapError { _ in SignalProducer(value: ()) }
	}
}
