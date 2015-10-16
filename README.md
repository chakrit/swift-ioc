# SWIFT IOC

This is a simple Swift IOC container implementation. The entire implementation is
contained (no pun intended) in the `section-1.swift` file for quick copy-and-paste.

This project is meant to be cloned into an Xcode playground directory so it's easy to test
and experiment.

# FEATURES

* Simple API.
* Tiny codebase. One file drop-in. You don't even need Cocoapods.
* Immutable containers. Construct new ones by `+`-ing existing ones.
* Can be used to make hierarchical container trees.

# USAGE

Use one of these three methods to create a `Resolver`:

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

Construct your container by merging `Resolver`s together:

```swift
let container = singleton(Singleton()) + auto(Auto()) + factory({ Factory() })
```

Obtain dependencies in your `ViewController` by pulling from the `container`:

```swift
import UIKit

class MyViewController: ViewController {
  let serviceObject: GlobalServiceObject = <-container

  override func viewDidLoad() {
    super.viewDidLoad()
    serviceObject.use()
  }
}
```

Dependencies can be lazy:

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

