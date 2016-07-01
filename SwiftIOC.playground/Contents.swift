/*:
 # SWIFT-IOC
 
 See the accompanying README.md file for full details. This playground acts as copy-pastable source code and as a quickstart.
 
 First build some `Resolver`s:
 
 ````
 let resolver1 = singleton(SharedServiceObject())
 ````
 
 Or using a factory method:
 
 ````
 let resolver2 = factory({ () -> ComplexObject in
    let co = ComplexObject()
    co.setup1()
    co.setup2()
    return co
 })
 ````
 
 Then combine them into a container using the `+` operator:
 
 ````
 let container = resolver1 + resolver2
 ````
 
 Then pull your dependencies from the container using the reverse arrow `<-` operator:
 
 ````
 class Dependant {
     let shared: SharedServiceObject = <-container
     let object: ComplexObject = <-container
 }
 ````
 
 That's it!
 
 ---

 ### Implementation

 */
// Copyright (c) 2015 Chakrit Wichian
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

private typealias Registry = [String: ResolutionScope]
typealias Builder = (Resolver) -> AnyObject

private protocol ResolutionScope {
    func build<T: AnyObject>(resolver: Resolver) -> T
    init(builder: Builder)
}

private class DefaultScope: ResolutionScope {
    let builder: Builder
    
    required init(builder: Builder) {
        self.builder = builder
    }
    
    func build<T: AnyObject>(resolver: Resolver) -> T {
        return self.builder(resolver) as! T
    }
}

private class SingletonScope: DefaultScope {
    private var instance: AnyObject? = nil
    private var onceToken: dispatch_once_t = dispatch_once_t()
    
    override func build<T: AnyObject>(resolver: Resolver) -> T {
        dispatch_once(&onceToken) {
            self.instance = self.builder(resolver)
        }
        
        return instance! as! T
    }
}

class Resolver {
    private let registrations: Registry
    
    private init(registry: Registry) {
        self.registrations = registry
    }
    
    private init(name: String, scope: ResolutionScope) {
        self.registrations = [name: scope]
    }
    
    private func resolve<T: AnyObject>() -> T {
        let name = String(T)
        if let scope = registrations[name] {
            return scope.build(self)
            
        } else {
            fatalError("no container registration for type \(name)")
        }
    }
}

func emptyContainer() -> Resolver {
    return Resolver(registry: [:])
}

func singleton<T: AnyObject>(builder: (Resolver) -> T) -> Resolver {
    let scope = SingletonScope(builder: builder)
    return Resolver(registry: [String(T): scope])
}

func factory<T: AnyObject>(builder: (Resolver) -> T) -> Resolver {
    let scope = DefaultScope(builder: builder)
    return Resolver(registry: [String(T): scope])
}

func +(lhs: Resolver, rhs: Resolver) -> Resolver {
    var merged: Registry = lhs.registrations
    for (name, builder) in rhs.registrations {
        merged[name] = builder
    }
    
    return Resolver(registry: merged)
}

func +=(inout lhs: Resolver, rhs: Resolver) -> Resolver {
    lhs = lhs + rhs
    return rhs
}

prefix operator <- {}
prefix func <-<T: AnyObject>(resolver: Resolver) -> T {
    return resolver.resolve()
}

/*:
 ---

 ### Tests
 */
var counter: Int = 0

class TestObject {
    let id: Int
    
    init() {
        counter += 1
        self.id = counter
        
        print("   creating: \(self.dynamicType) \(self.id)")
    }
}


print(" ====================================== BASIC SETUP ")
class Singleton: TestObject { }
class Factory: TestObject { }

var container = emptyContainer()
container += singleton({ _ in Singleton() })
container += factory({ _ in Factory() })

let single1: Singleton = <-container
let single2: Singleton = <-container
let single3: Singleton = <-container
print("singleton works: \(single1.id == single2.id)")
print("singleton works: \(single2.id == single3.id)")

let instance1: Factory = <-container
let instance2: Factory = <-container
let instance3: Factory = <-container
print("factory works: \(instance1.id != instance2.id)")
print("factory works: \(instance2.id != instance3.id)")


print(" ====================================== IMPLICIT PULLING ")
class Dependent: TestObject {
    let service: Singleton = <-container
    let instance: Factory = <-container
    lazy var lazyInstance: Factory = <-container
}

let dependent1 = Dependent()
let dependent2 = Dependent()
print("instance resolution works for singleton: \(dependent1.service === dependent2.service)")
print("instance resolution works for factory:   \(dependent1.instance !== dependent2.instance)")
print("lazy resolution works: \(dependent1.lazyInstance.id)")
print("lazy resolution works: \(dependent2.lazyInstance.id)")


print(" ====================================== COMPLEX OUT-OF-ORDER REGISTRATION ")
class Inner: TestObject { }

class Outer: TestObject {
    let inner1: Inner
    let inner2: Inner
    
    init(inner one: Inner, another two: Inner) {
        self.inner1 = one
        self.inner2 = two
    }
}

class Wrapper: TestObject {
    let outer: Outer
    
    init(outer: Outer) {
        self.outer = outer
    }
}

container = emptyContainer()
container += factory({ Wrapper(outer: <-$0) })
container += singleton({ Outer(inner: <-$0, another: <-$0) })
container += factory({ _ in Inner() })

let wrapper1: Wrapper = <-container
let wrapper2: Wrapper = <-container
print("out-of-order resolution: \(wrapper1.id) \(wrapper1.outer.id) \(wrapper1.outer.inner1.id) \(wrapper1.outer.inner2.id)")
print("out-of-order resolution: \(wrapper2.id) \(wrapper2.outer.id) \(wrapper2.outer.inner1.id) \(wrapper2.outer.inner2.id)")
