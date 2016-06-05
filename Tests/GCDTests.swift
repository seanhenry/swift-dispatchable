//
//  GCDTests.swift
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

class GCDTests: XCTestCase {
    
    var gcd: GCD!
    var didRunTask = false
    var didRunTaskOnMainThread: Bool!

    override func setUp() {
        super.setUp()
        didRunTask = false
        gcd = GCD()
    }

    // MARK: - init

    func test_init_shouldSetQueue() {
        gcd = GCD(queue: dispatch_queue_create("com.test", DISPATCH_QUEUE_SERIAL))
        let label = String(CString: dispatch_queue_get_label(gcd.queue), encoding: NSUTF8StringEncoding)
        XCTAssertEqual(label, "com.test")
    }

    // MARK: - queue

    func test_queue_shouldBeGlobalQueueWithUtilityQOSPriority() {
        let priority = dispatch_queue_get_qos_class(gcd.queue, nil)
        XCTAssertEqual(priority, QOS_CLASS_UTILITY)
    }
    
    // MARK: - main
    
    func test_main_shouldRunTask() {
        gcd.main(task())
        waitForTask()
        XCTAssert(didRunTask)
    }

    func test_main_shouldRunTaskOnMainThread() {
        let expectation = expectationWithDescription(#function)
        gcd.offload {
            self.gcd.main {
                self.didRunTaskOnMainThread = NSThread.isMainThread()
                expectation.fulfill()
            }
        }
        waitForTask()
        XCTAssert(didRunTaskOnMainThread)
    }

    // MARK: - offload

    func test_offload_shouldRunTaskOffTheMainThread() {
        gcd.offload(task())
        waitForTask()
        XCTAssert(didRunTask)
        XCTAssert(didRunTaskOnMainThread == false)
    }

    func test_offload_shouldRunTaskOnDefaultQOSQueue() {
        let expectation = expectationWithDescription(#function)
        gcd.offload {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_UTILITY)
            expectation.fulfill()
        }
        waitForTask()
    }

    func test_offload_shouldRunTaskOnCustomQueue() {
        let queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
        gcd = GCD(queue: queue)
        let expectation = expectationWithDescription(#function)
        gcd.offload {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)
            expectation.fulfill()
        }
        waitForTask()
    }

    // MARK: - after

    func test_after_shouldRunTaskAfterDelay() {
        let expectation = expectationWithDescription(#function)
        gcd.after(0.05) {
            self.didRunTask = true
            self.didRunTaskOnMainThread = NSThread.isMainThread()
            expectation.fulfill()
        }
        XCTAssertFalse(didRunTask, "Should not run immediately")
        waitForTask()
        XCTAssert(didRunTaskOnMainThread)
    }

    // MARK: - Helpers

    func task() -> Task {
        let expectation = expectationWithDescription(#function)
        let task = {
            self.didRunTask = true
            self.didRunTaskOnMainThread = NSThread.isMainThread()
            expectation.fulfill()
        }
        return task
    }

    func waitForTask() {
        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
