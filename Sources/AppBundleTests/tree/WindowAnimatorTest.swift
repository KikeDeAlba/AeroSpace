@testable import AppBundle
import AppKit
import Common
import Testing

@MainActor
@Suite(.serializedGlobally)
struct WindowAnimatorTest {
    @Test func testEasingEndpointsAndMidpoint() {
        for easing in Easing.allCases {
            assertEquals(easing.apply(0), 0)
            assertEquals(easing.apply(1), 1)
        }
        assertEquals(Easing.linear.apply(0.5), 0.5)
        assertEquals(Easing.easeOut.apply(0.5), 0.875)
        assertEquals(Easing.easeInOut.apply(0.5), 0.5)
        assertEquals(Easing.easeInOut.apply(0.25), 0.0625)
    }

    @Test func testEasingClampsOutOfRangeProgress() {
        for easing in Easing.allCases {
            assertEquals(easing.apply(-1), 0)
            assertEquals(easing.apply(2), 1)
        }
    }

    @Test func testEasingIsMonotonic() {
        for easing in Easing.allCases {
            var prev = easing.apply(0)
            for i in 1 ... 100 {
                let cur = easing.apply(Double(i) / 100)
                assertTrue(cur >= prev)
                prev = cur
            }
        }
    }

    @Test func testStepCount() {
        assertEquals(animationStepCount(durationMs: 0), 0)
        assertEquals(animationStepCount(durationMs: -5), 0)
        assertEquals(animationStepCount(durationMs: 1), 1)
        assertEquals(animationStepCount(durationMs: 16), 1)
        assertEquals(animationStepCount(durationMs: 17), 2)
        assertEquals(animationStepCount(durationMs: 150), 10)
        assertEquals(animationStepCount(durationMs: 250), 16)
        assertEquals(animationStepCount(durationMs: 1000), 63)
    }

    @Test func testInterpolationEndpointsAreExact() {
        let from = Rect(topLeftX: 0.3, topLeftY: 10.7, width: 100.1, height: 200.9)
        let to = Rect(topLeftX: 1000.123, topLeftY: -33.3, width: 640.7, height: 480.2)
        assertEquals(interpolateFrame(from: from, to: to, progress: 0), from)
        assertEquals(interpolateFrame(from: from, to: to, progress: 1), to)
        assertEquals(interpolateFrame(from: from, to: to, progress: 1.5), to)
        assertEquals(interpolateFrame(from: from, to: to, progress: -0.5), from)
    }

    @Test func testInterpolationMidpoint() {
        let from = Rect(topLeftX: 0, topLeftY: 0, width: 100, height: 200)
        let to = Rect(topLeftX: 100, topLeftY: 50, width: 300, height: 400)
        assertEquals(interpolateFrame(from: from, to: to, progress: 0.5), Rect(topLeftX: 50, topLeftY: 25, width: 200, height: 300))
    }

    @Test func testLastAnimationStepIsExactTarget() {
        let from = Rect(topLeftX: 0, topLeftY: 0, width: 100, height: 100)
        let to = Rect(topLeftX: 333.333, topLeftY: 77.7, width: 123.4, height: 567.8)
        let stepCount = animationStepCount(durationMs: 150)
        for easing in Easing.allCases {
            assertEquals(animationFrame(from: from, to: to, step: stepCount, stepCount: stepCount, easing: easing), to)
            assertEquals(animationFrame(from: from, to: to, step: 0, stepCount: stepCount, easing: easing), from)
        }
    }

    @Test func testPartialTargetResolve() {
        let current = Rect(topLeftX: 1, topLeftY: 2, width: 3, height: 4)
        assertEquals(FrameTarget(topLeft: CGPoint(x: 10, y: 20), size: nil).resolve(against: current), Rect(topLeftX: 10, topLeftY: 20, width: 3, height: 4))
        assertEquals(FrameTarget(topLeft: nil, size: CGSize(width: 30, height: 40)).resolve(against: current), Rect(topLeftX: 1, topLeftY: 2, width: 30, height: 40))
    }

    @Test func testDecideSetFrame() {
        let a = FrameTarget(topLeft: CGPoint(x: 0, y: 0), size: CGSize(width: 100, height: 100))
        let b = FrameTarget(topLeft: CGPoint(x: 50, y: 0), size: CGSize(width: 100, height: 100))

        assertEquals(decideSetFrame(a, durationMs: 0, lastTarget: nil, isAnimatingToLastTarget: false), .instant)
        assertEquals(decideSetFrame(a, durationMs: 0, lastTarget: a, isAnimatingToLastTarget: false), .instant)
        assertEquals(decideSetFrame(a, durationMs: 0, lastTarget: b, isAnimatingToLastTarget: true), .instant)

        assertEquals(decideSetFrame(a, durationMs: 150, lastTarget: nil, isAnimatingToLastTarget: false), .animate)
        assertEquals(decideSetFrame(a, durationMs: 150, lastTarget: b, isAnimatingToLastTarget: false), .animate)
        assertEquals(decideSetFrame(a, durationMs: 150, lastTarget: b, isAnimatingToLastTarget: true), .animate)

        assertEquals(decideSetFrame(a, durationMs: 150, lastTarget: a, isAnimatingToLastTarget: true), .skip)
        assertEquals(decideSetFrame(a, durationMs: 0, lastTarget: a, isAnimatingToLastTarget: true), .skip)

        assertEquals(decideSetFrame(a, durationMs: 150, lastTarget: a, isAnimatingToLastTarget: false), .instant)
    }

    @Test func testAnimationCompletion() {
        let completion = AnimationCompletion()
        assertFalse(completion.isDone)
        completion.markDone()
        assertTrue(completion.isDone)
        completion.markDone()
        assertTrue(completion.isDone)
    }
}
