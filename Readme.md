## App Store Redesign App

### Language
Swift 4.0

### Minimum supporting platform
iOS 9.0

### IDE
Xcode 9.4.1

### Dependencies used (managed by Cocoapods)

1. `SwiftyJSON` - for parsing the JSON responses from the API
1. `Alamofire` - networking library
1. `AlamofireImage` - networking library specific for loading, caching the images
1. `PromiseKit` - Turn callback codes into more readable format
1. `PromiseKit/Alamofire` - Alamofire extension that turns networking codes into promise style
1. `RealmSwift` - Data caching layer
1. `UIScrollView-InfiniteScroll` - Added load more functions to the list

### Steps to build

1. Install [Cocoapods](https://guides.cocoapods.org/using/getting-started.html#installation) if not yet done
1. In the same directory as the Podfile, execute the following:
```shell
$ pod install
```
All listed dependencies should be installed.
1. Open `AppStoreRedesign.xcworkspace` in Xcode
1. Build and run on simulator
1. To run on device, you have to change the Bundle Identifier to something owned by you (e.g. me.YOURNAME.AppStoreRedesign)

### Data Source

1. iTunes RSS Feed
    1. https://itunes.apple.com/hk/rss/topfreeapplications/limit=100/json​​
    1. https://itunes.apple.com/hk/rss/topgrossingapplications/limit=10/json​​

1. iTunes Lookup API
    1. https://itunes.apple.com/hk/lookup?id={id}

### Caching layer explained

1. API Caching - Grossing Apps

    The RSS feed of top grossing applications are parsed and write to the disk - managed by `Realm`. Information of apps positioning and parsed app details are also written (cached) to the disk by `Realm`.

    If loading the top grossing applications RSS feed failed (e.g. network error, no internet connection) and system level cache (`NSURLCache`) is not available, the app will load the cached info from `Realm`, together with the application details.

1. API Caching - Free Apps

    The RSS feed of top free applications are parsed and use the ID to query the lookup API (10 IDs at a time). The result from the lookup API are parsed and write to the disk - managed by `Realm`.

    If loading the top free applications details failed (e.g. network error, no internet connection) and system level cache (`NSURLCache`) is not available, the app will load the cached app detail from `Realm`.

1. Photo Caching

    Photo caching is auto managed by the `AlamofireImage`. Firstly, it will be cached in the system level (`NSURLCache`) and it will be also cached in memory level (by `AlamofireImage`). The image removal order is by LRU (least recent used).


### Possible features

- [ ] Detail page and its push and pop custom transition
- [ ] Peek the application detail
- [ ] Better UI design
- [ ] Handle Universal links and show app detail by IDs
