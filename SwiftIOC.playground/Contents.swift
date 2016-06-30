/*:
 # SWIFT-IOC
 
 See the accompanying README.md file for full details. This playground as copy-pastable source code and as a quickstart.
 
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

typealias Registry = [String: () -> AnyObject]

protocol Resolver {
    var registrations: Registry { get }
    func resolve<T: AnyObject>() -> T
}

private class EmptyContainer: Resolver {
    let registrations: Registry = [:]

    func resolve<T : AnyObject>() -> T {
        fatalError("no registration for requested type.")
    }
}

private class Container: Resolver {
    let registrations: Registry

    init(name: String, resolver: () -> AnyObject) {
        registrations = [name: resolver]
    }

    init(previousRegistrations: Registry, name: String, resolver: () -> AnyObject) {
        var merged = previousRegistrations
        merged[name] = resolver
        registrations = merged
    }

    init(previousRegistrations: Registry, additionalRegistrations: Registry) {
        var merged = previousRegistrations
        for (key, value) in additionalRegistrations {
            merged[key] = value
        }

        registrations = merged
    }

    func resolve<T : AnyObject>() -> T {
        let name = String(T)
        if let resolver = registrations[name] {
            return resolver() as! T

        } else {
            fatalError("no registration for requested type.")
        }
    }
}

func emptyContainer() -> Resolver {
    return EmptyContainer()
}

func singleton<T: AnyObject>(instance: T) -> Resolver {
    return Container(name: String(T),
                     resolver: { () -> AnyObject in instance })
}

func factory<T: AnyObject>(factory: () -> T) -> Resolver {
    return Container(name: String(T), resolver: factory)
}

func +(lhs: Resolver, rhs: Resolver) -> Resolver {
    return Container(previousRegistrations: lhs.registrations,
                     additionalRegistrations: rhs.registrations)
}

func +=(inout lhs: Resolver, rhs: Resolver) {
    lhs = lhs + rhs
}

prefix operator <- {}
prefix func <-<T: AnyObject>(resolver: Resolver) -> T {
    return resolver.resolve()
}

/*:
 ---

 ### Tests
 */
class TestObject {
    let id: String = NSUUID().UUIDString
    init() { dump("ctor: \(id)") }
}

class Singleton: TestObject { }
class Factory: TestObject { }

var container = emptyContainer()
container += singleton(Singleton())
container += factory({ Factory() })

let single1: Singleton = <-container
let single2: Singleton = <-container
let single3: Singleton = <-container
print(single1.id == single2.id)
print(single2.id == single3.id)

let instance1: Factory = <-container
let instance2: Factory = <-container
let instance3: Factory = <-container
print(instance1.id != instance2.id)
print(instance2.id != instance3.id)

class Dependent {
    let service: Singleton = <-container
    let instance: Factory = <-container
}

let dependent1 = Dependent()
let dependent2 = Dependent()
print(dependent1.service === dependent2.service)
print(dependent1.instance !== dependent2.instance)
