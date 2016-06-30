# SWIFT IOC

This is a simple Swift IOC container implementation. The entire implementation is
contained (no pun intended) in a single
[`Contents.swift`](https://raw.githubusercontent.com/chakrit/swift-ioc/master/SwiftIOC.playground/Contents.swift)
file for quick copy-and-paste into your project.

# FEATURES

* Simple API. Minimal code. Minimal concepts.
* One file drop-in. You don't even need any dependency manager.
* Immutable containers. Construct new ones by `+`-ing existing ones.
* Can be used to make hierarchical container trees.

# USAGE

Register dependencies with either a `singleton` or a `factory` resolver:

```swift
// Registers a singleton object.
let resolver = singleton(GlobalServiceObject())

// Registers a factory function.
let resolver = factory({ () -> ComplexObject in
    let co = ComplexObject()
    co.complex = "setup"
    co.invokeMethod()

    return co
})
```

Construct your container by merging `Resolver`s together using the plus (`+`) operator:

```swift
let container = singleton(ServiceOne()) + singleton(ServiceTwo()) + factory({ InstanceService() })
```

Then to obtain dependencies, pull it out from the container you have just created using
the reverse arrow (`<-`) operator:

```swift
import UIKit

class MyViewController: ViewController {
  let serviceObject: GlobalServiceObject = <-container
  let anotherService: InstanceService = <-container

  override func viewDidLoad() {
    super.viewDidLoad()
    serviceObject.use()
  }
}
```

Additionally, dependencies can be lazy:

```swift
class X {
  lazy var cash: ExpensiveObject = <-container

  func doWork() {
    cash.work()
  }
}
```

Or hierarchical:

```swift
import UIKit

let topLevel = singleton(ServiceObject())

class RootViewController: ViewController {
  let container = topLevel + singleton(ViewUtility())

  // ...
}
```

Enjoy!

# TODOs / PR material

* Also registers as superclass type.
* Overrides.
* Explain modules system.
* Cyclic check.

# SUPPORT

GitHub issue or ping me @chakrit on twitter.

# LICENSE

MIT

