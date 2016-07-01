# SWIFT IOC

This is a simple Swift IOC container implementation. The entire implementation is
contained (no pun intended) in a single
[`Contents.swift`](https://raw.githubusercontent.com/chakrit/swift-ioc/master/SwiftIOC.playground/Contents.swift)
file for quick copy-and-paste into your project.

# FEATURES

* Simple API. Minimal concepts.
* Tiny file. Minimal code (less than 100 LOC w/o docs).
* One file drop-in. You don't even need any dependency manager.
* Immutable containers. Construct new ones by `+`-ing existing ones.
* Can be used to make hierarchical container trees.

# USAGE

Register dependencies with either a `singleton` or a `factory` resolver:

```swift
// Registers a singleton object.
let resolver = singleton({ _ in GlobalServiceObject() })

// Registers a factory function.
let resolver = factory({ (resolver) -> ComplexObject in
    let co = ComplexObject()
    co.innerDependency = <-resolver
    co.invokeMethod()

    return co
})

// Registers a factory function using Swift shorthand lambda form
let resolver = factory({ Dependent(dependency: <-$0) })
```

Construct your container by merging `Resolver`s together using the plus (`+`) operator:

```swift
let container = singleton({ _ in ServiceOne() }) +
  singleton({ _ in ServiceTwo() }) +
  factory({ _ in InstanceService() })

// or mutable
var container = emptyContainer()
container += singleton({ _ in ServiceOne() })
container += singleton({ _ in ServiceTwo() })
//...
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

let topLevel = singleton({ _ in ServiceObject() })

class RootViewController: ViewController {
  let container = topLevel + singleton({ _ in ViewUtility() })

  // ...
}
```

Or registered out-of-order:

```swift
var container = emptyContainer()
container += factory({ One(requireTwo: <-$0 })
container += factory({ Two(requireThree: <-$0 })
container += factory({ Three() })
```

Enjoy!

# TODOs / PR material

* Handles superclass types.
* Overrides.
* Modules system.
* Cyclic check.

# SUPPORT

GitHub issue or ping me @chakrit on twitter.

# LICENSE

MIT

