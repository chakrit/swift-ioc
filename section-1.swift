//
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
        let name = toString(T)
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
    return Container(name: toString(T),
        resolver: { () -> AnyObject in instance })
}

func factory<T: AnyObject>(factory: () -> T) -> Resolver {
    return Container(name: toString(T), resolver: factory)
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

// ______________________________________________________________________
//                                                                T E S T
class TestObject {
    let id: String = NSUUID().UUIDString
    init() { dump("ctor: \(id)") }
}

class Singleton: TestObject { }
class Factory: TestObject { }

var container = emptyContainer()
container += singleton(Singleton())
container += factory({ Factory() })

var singleton: Singleton = <-container
dump(singleton.id)
singleton = <-container
dump(singleton.id)
singleton = <-container
dump(singleton.id)

// In Swift1.2 @autoclosure now implies @noescape so we can no longer use it like what we did
// previously.
//var auto: Auto = <-container
//dump(auto.id)
//auto = <-container
//dump(auto.id)
//auto = <-container
//dump(auto.id)

var factory: Factory = <-container
dump(factory.id)
factory = <-container
dump(factory.id)
factory = <-container
dump(factory.id)

