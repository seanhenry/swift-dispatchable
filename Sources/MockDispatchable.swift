//
//  MockDispatchable.swift
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

import Foundation

typealias Recorder = MockDispatchable.Recorder
typealias Thread = MockDispatchable.Recorder.Thread

class MockDispatchable: Dispatchable {

    struct Recorder {

        enum Thread: Equatable {
            case Main
            case Background
            case After(Double)

            var delay: Double? {
                guard case .After(let delay) = self else { return nil }
                return delay
            }
        }

        var isMainThread: Bool {
            let lastThread = threadHistory.last ?? .Main
            return lastThread != .Background
        }
        private(set) var threadHistory = [Thread]()

        private mutating func runOnMainThread() {
            threadHistory.append(.Main)
        }

        private mutating func runOnBackgroundThread() {
            threadHistory.append(.Background)
        }

        private mutating func runAfterDelay(delay: Double) {
            threadHistory.append(.After(delay))
        }
    }

    var recorder = Recorder()

    func main(task: Task) {
        recorder.runOnMainThread()
        task()
    }

    func offload(task: Task) {
        recorder.runOnBackgroundThread()
        task()
    }

    func after(delay: Double, task: Task) {
        recorder.runAfterDelay(delay)
        task()
    }
}

func ==(lhs: Thread, rhs: Thread) -> Bool {
    switch (lhs, rhs) {
    case (.Main, .Main), (.Background, .Background): return true
    case (.After(let lhsDelay), .After(let rhsDelay)):
        return lhsDelay == rhsDelay
    default: return false
    }
}
