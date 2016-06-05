# Dispatchable
A simple library to help test asynchronous code.
- All code is run on the main thread when running tests.
- Records asynchronous behaviour which can be checked in your tests.
  
## Testing Asynchronous Code
Ideally asynchronous tests should be avoided to ensure unit tests are quick and robust.   
  
*What asynchronous code should you verify?*  
It's probably not essential to verify what exactly runs on a separate thread but it is often essential to test the behaviour of threading in your application. For example, whether completion blocks are fired on the main thread.
## Using `Dispatchable`
```
let dispatch = GCD()
dispatch.offload {
    print("This happens on a separate thread.")
}

dispatch.main {
    print("This happens on the main thread.")
}

dispatch.after(0.5) {
    print("This happens on the main thread after a delay of 0.5 seconds.")
}
```

## Testing
 Suppose you have a class which does something asynchonously:
 
```
class MyClass {

    let dispatch: Dispatchable
    var state = "no state"

    init(dispatch: Dispatchable = GCD()) {
        self.dispatch = dispatch
    }

    func doSomethingAsynchronous() {
        dispatch.offload {
            self.state = "changed state"
        }
    }
}
let classInProductCode = MyClass()
```

In your tests you can replace `Dispatchable` with a mocked version.

```
var mockedDispatchable = MockDispatchable()
let classUnderTest = MyClass(dispatch: mockedDispatchable)
```
In your test call the method to test.  

```
classUnderTest.doSomethingAsynchronous()
```

The asynchronous code will now run immediately.

```
XCTAssertEqual(classUnderTest.state, "changed state")
``` 
## Complex example  
```
extension MyClass {

    func doSomethingComplex(completion: () -> ()) {
        dispatch.offload {
            self.state = "changed state"
            self.dispatch.main {
                completion()
            }
        }
    }
}
```
Unit Test:

```
mockedDispatchable = MockDispatchable()
let complexClass = MyClass(dispatch: mockedDispatchable)
// Test 1: Test that state is not changed before entering the concurrent thread.
mockedDispatchable.didEnterThread = { thread in
    if thread == .Offload {
        XCTAssertEqual(complexClass.state, "no state")
    }
}
// Test 2: Test that the state changes in the concurrent thread.
mockedDispatchable.didExitThread = { thread in
    if thread == .Offload {
        XCTAssertEqual(complexClass.state, "changed state")
    }
}

complexClass.doSomethingComplex {
    // Test 3: Test callback is on the main thread.
    XCTAssert(mockedDispatchable.recorder.isMainThread)
}
```

## How to access `MockDispatchable`
There are 2 ways to set up `Dispatchable` for testing.
### Use `@testable import Dispatchable` in your tests.
`MockDispatchable` is an `internal` `class` and cannot be accessed by your production code. However, in your tests you can use `@testable import Dispatchable` to access the mock.    
  
*Important*  
This will only work if you build `Dispatchable` using the `Debug` configuration. If this doesn't suit you then follow the method below.    
  
*Note*  
The mock will not be included when building using the release configuration to ensure it can never be included in production code.
### Copy the MockDispatchable.swift file into your test target.
 This is not preferred because the mock will become out of sync with the framework as it changes.

