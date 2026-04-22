# SkipUI Animation Repro

This app reproduces an Android animation bug in `SkipUI`.

## Issue

The repro has two matching tiles:

- a green tile
- a red tile

When you tap `Animate`, the app updates both state values:

```swift
redOpacity = 0

withAnimation(.linear(duration: ReproLayout.greenFadeDuration)) {
    greenOpacity = 0
}
```

Only the green opacity change is inside `withAnimation()`.

The expected result is:

- green tile fades out
- red tile disappears instantly

The incorrect Android result is:

- green tile fades out
- red tile also fades out

Think of it as the green tile's animation transaction leaking into a sibling state update.

## What To Look For

When reproducing the issue:

1. Launch the app on iOS and Android.
2. Tap `Animate`.
3. Watch both tiles at the same time.

Correct behavior (observed on iOS):

- the green tile animates
- the red tile snaps to zero opacity with no fade

Incorrect behavior (observed on Android):

- the red tile fades along with the green tile



## Running

Open `Project.xcworkspace` in Xcode to run the iOS app and build the Android app through the Skip toolchain.
