import Foundation

typealias Registry = [String: () -> AnyObject]

protocol Resolver {
    var registrations: Registry { get }
    func resolve<T: AnyObject>() -> T
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
        let name = NSStringFromClass(T)
        if let resolver = registrations[name] {
            return resolver() as T

        } else {
            fatalError("no registration for requested type.")
        }
    }
}

func singleton<T: AnyObject>(instance: T) -> Resolver {
    return Container(name: NSStringFromClass(T),        resolver: { () -> AnyObject in instance })
}

func auto<T: AnyObject>(factory: @autoclosure () -> T) -> Resolver {
    return Container(name: NSStringFromClass(T), resolver: factory)
}

func factory<T: AnyObject>(factory: () -> T) -> Resolver {
    return Container(name: NSStringFromClass(T), resolver: factory)
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

class TestObject {
    let id: String = NSUUID().UUIDString
    init() { dump("ctor") }}


// ______________________________________________________________________
//                                                                T E S T
class Singleton: TestObject { }
class Auto: TestObject { }
class Factory: TestObject { }

let container = singleton(Singleton()) + auto(Auto()) + factory({ Factory() })

var singleton: Singleton = <-container
dump(singleton.id)
singleton = <-container
dump(singleton.id)
singleton = <-container
dump(singleton.id)

var auto: Auto = <-container
dump(auto.id)
auto = <-container
dump(auto.id)
auto = <-container
dump(auto.id)

var factory: Factory = <-container
dump(factory.id)
factory = <-container
dump(factory.id)
factory = <-container
dump(factory.id)
