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
        XCTAssertNotEqual(Thread.Main, Thread.Background)
    }

    func test_thread_shouldBeEqual_whenBothMain() {
        XCTAssertEqual(Thread.Main, Thread.Main)
    }

    func test_thread_shouldBeEqual_whenBothBackground() {
        XCTAssertEqual(Thread.Background, Thread.Background)
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

    func test_recorder_recordsThreadHistory() {
        dispatchable.after(1) {}
        dispatchable.offload {}
        dispatchable.main {}
        let expectedHistory = [Thread.After(1), Thread.Background, Thread.Main]
        XCTAssertEqual(recorder.threadHistory, expectedHistory)
    }

    // MARK: - main

    func test_main_shouldRecordMainThread_afterOffloading() {
        dispatchable.offload {}
        dispatchable.main {}
        XCTAssert(recorder.isMainThread)
    }

    func test_main_shouldRunTaskImmediately() {
        var didRunTask = false
        dispatchable.main {
            didRunTask = true
        }
        XCTAssert(didRunTask)
    }

    // MARK: - offload

    func test_offload_shouldRecordOffMainThread() {
        dispatchable.offload {}
        XCTAssertFalse(recorder.isMainThread)
    }

    func test_offload_shouldRunTaskImmediately() {
        var didRunTask = false
        dispatchable.offload {
            didRunTask = true
        }
        XCTAssert(didRunTask)
    }

    // MARK: - after

    func test_after_shouldRecordMainThread_afterOffloading() {
        dispatchable.offload {}
        dispatchable.after(1) {}
        XCTAssert(recorder.isMainThread)
    }

    func test_after_shouldRunTaskImmediately() {
        var didRunTask = false
        dispatchable.after(1) {
            didRunTask = true
        }
        XCTAssert(didRunTask)
    }
}
