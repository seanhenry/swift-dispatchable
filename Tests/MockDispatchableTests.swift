//
//  MockDispatchableTests.swift
//
//  Copyright © 2016 Sean Henry. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import XCTest
@testable import Dispatchable

class MockDispatchable_Recorder_ThreadTests: XCTestCase {

    // MARK: - ==

    func test_thread_shouldBeEqual_whenAfterDelayMatches() {
        XCTAssertEqual(Thread.After(1.3), Thread.After(1.3))
    }

    func test_thread_shouldNotBeEqual_whenDifferentTypes() {
        XCTAssertNotEqual(Thread.Main, Thread.Offload)
    }

    func test_thread_shouldBeEqual_whenBothMain() {
        XCTAssertEqual(Thread.Main, Thread.Main)
    }

    func test_thread_shouldBeEqual_whenBothBackground() {
        XCTAssertEqual(Thread.Offload, Thread.Offload)
    }

    func test_thread_shouldNotBeEqual_whenAfterDelaysAreDifferent() {
        XCTAssertNotEqual(Thread.After(2), Thread.After(3))
    }

    // MARK: - delay

    func test_delay_shouldReturnNil_whenNotAfter() {
        XCTAssertNil(Thread.Main.delay)
    }

    func test_delay_shouldReturnDelay_whenAfter() {
        XCTAssertEqual(Thread.After(1.1).delay, 1.1)
    }
}

class MockDispatchableTests: XCTestCase {

    var dispatchable: MockDispatchable!
    var recorder: Recorder! {
        return dispatchable.recorder
    }
    
    override func setUp() {
        super.setUp()
        dispatchable = MockDispatchable()
    }

    // MARK: - recorder

    func test_recorder_isMainThread_isTrueByDefault() {
        XCTAssert(recorder.isMainThread)
    }

    func test_recorder_shouldNotRecordToThreadStack_whenNotNested() {
        dispatchable.after(1) {}
        dispatchable.offload {}
        dispatchable.main {}
        XCTAssertEqual(recorder.threadStack.count, 0)
    }

    func test_recorder_shouldRecordToThreadStack_whenNested() {
        dispatchable.after(1) {
            XCTAssertEqual(self.recorder.threadStack, [.After(1)])
            self.dispatchable.offload {
                XCTAssertEqual(self.recorder.threadStack, [.After(1), .Offload])
                self.dispatchable.main {
                    XCTAssertEqual(self.recorder.threadStack, [.After(1), .Offload, .Main])
                }
            }
        }
    }

    // MARK: - main

    func test_main_shouldRunTaskImmediately() {
        var didRunTask = false
        dispatchable.main {
            didRunTask = true
        }
        XCTAssert(didRunTask)
    }

    func test_main_shouldRecordMainThread_afterOffloading() {
        dispatchable.offload {
            self.dispatchable.main {
                XCTAssert(self.recorder.isMainThread)
            }
        }
    }

    func test_main_shouldCallBack_inCorrectOrder() {
        let callbacks = collectCallbacks { task in
            self.dispatchable.main(task)
        }
        XCTAssertEqual(callbacks, ["enter:main", "task", "exit:main"])
    }

    // MARK: - offload

    func test_offload_shouldRunTaskImmediately() {
        var didRunTask = false
        dispatchable.offload {
            didRunTask = true
        }
        XCTAssert(didRunTask)
    }

    func test_offload_shouldRecordOffMainThread() {
        dispatchable.offload {
            XCTAssertFalse(self.recorder.isMainThread)
        }
        XCTAssert(recorder.isMainThread)
    }

    func test_offload_shouldCallBack_inCorrectOrder() {
        let callbacks = collectCallbacks { task in
            self.dispatchable.offload(task)
        }
        XCTAssertEqual(callbacks, ["enter:offload", "task", "exit:offload"])
    }

    // MARK: - after

    func test_after_shouldRunTaskImmediately() {
        var didRunTask = false
        dispatchable.after(1) {
            didRunTask = true
        }
        XCTAssert(didRunTask)
    }

    func test_after_shouldRecordMainThread_afterOffloading() {
        dispatchable.offload {
            self.dispatchable.after(1) {
                XCTAssert(self.recorder.isMainThread)
            }
        }
    }

    func test_after_shouldCallBack_inCorrectOrder() {
        let callbacks = collectCallbacks { task in
            self.dispatchable.after(1, task: task)
        }
        XCTAssertEqual(callbacks, ["enter:after", "task", "exit:after"])
    }

    // MARK: - Helpers

    private func collectCallbacks(task: (() -> ()) -> ()) -> [String] {
        var result = [String]()
        dispatchable.didEnterThread = { t in
            result.append("enter:" + self.threadToString(t))
        }
        dispatchable.didExitThread = { t in
            result.append("exit:" + self.threadToString(t))
        }
        task {
            result.append("task")
        }
        return result
    }

    private func threadToString(thread: Thread) -> String {
        switch thread {
        case .Main: return "main"
        case .Offload: return "offload"
        case .After: return "after"
        }
    }
}
