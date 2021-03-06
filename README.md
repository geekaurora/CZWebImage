# CZWebImage

![Swift Version](https://img.shields.io/badge/swift-5.0-orange.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/CZUtils.svg?style=flat)](http://cocoapods.org/pods/CZUtils)
[![Platform](https://img.shields.io/cocoapods/p/CZUtils.svg?style=flat)](http://cocoapods.org/pods/CZUtils)
 
Elegant progressive concurrent image downloading framework, with neat API and performant LRU mem/disk cache.

### How To Use

```objective-c
Objective-C:

#import <CZWebImage/CZWebImage.h>
...
[imageView cz_setImageWithURL:[NSURL URLWithString:@"http://www.domain.com/path/to/image.jpg"]
             placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
```

```swift
Swift:

import CZWebImage

// Liner to fetch imageUrl
feedImageView.cz_setImage(with: imageUrl,
                          placeholderImage: UIImage(named: "placeholder.png"))   
                          
// Set cropSize for image - will get done in background thread automatically after download
feedImageView.cz_setImage(with: imageUrl,
                          placeholderImage: UIImage(named: "placeholder.png"),
                          cropSize: cropSize)                          
```

### Work Flow
<img src="./Docs/CZWebImage-Sequence-Diagram.png">

### Debugging
Set `shouldObserveOperations` of `CZWebImageConstants` to `true` to observe downloading tasks.
 
### Instagram Demo - [Github](https://github.com/showt1me/CZInstagram)
Implemented on top of **CZWebImage**

<img src="https://media.giphy.com/media/jSWYS99p1rXe9nSCtp/giphy.gif">
