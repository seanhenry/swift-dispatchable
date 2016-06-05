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
            case Offload
            case After(Double)

            var delay: Double? {
                guard case .After(let delay) = self else { return nil }
                return delay
            }
        }

        var isMainThread: Bool {
            let lastThread = threadStack.last ?? .Main
            return lastThread != .Offload
        }
        private(set) var threadStack = [Thread]()
    }

    var recorder = Recorder()
    var didEnterThread: (Thread -> ())?
    var didExitThread: (Thread -> ())?

    func main(task: Task) {
        push(.Main)
        task()
        pop()
    }

    func offload(task: Task) {
        push(.Offload)
        task()
        pop()
    }

    func after(delay: Double, task: Task) {
        push(.After(delay))
        task()
        pop()
    }

    private func push(thread: Thread) {
        recorder.threadStack.append(thread)
        didEnterThread?(thread)
    }

    private func pop() -> Thread {
        let last = recorder.threadStack.removeLast()
        didExitThread?(last)
        return last
    }
}

func ==(lhs: Thread, rhs: Thread) -> Bool {
    switch (lhs, rhs) {
    case (.Main, .Main), (.Offload, .Offload): return true
    case (.After(let lhsDelay), .After(let rhsDelay)):
        return lhsDelay == rhsDelay
    default: return false
    }
}
