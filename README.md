<p align="center">
  <img src="screenshots/Unpose AppIcon.png" width="140" style="border-radius: 28px;" />
</p>

<h1 align="center">Unposed</h1>
<p align="center"><em>Real moments, not poses.</em></p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift_Student_Challenge-2025-orange?style=flat-square" />
  <img src="https://img.shields.io/badge/Platform-iOS_17+-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/Built_with-Swift_Playgrounds-purple?style=flat-square" />
</p>

---

## Why I Built This

I kept noticing the same thing — the second a camera comes out, everyone puts on "the face." You know the one. Head tilted, smile rehearsed, eyes a little wider than normal. The photo comes out fine, but it doesn't really look like *you*. It looks like what you think a photo of you should look like.

The photos of people that I actually love — the ones that feel real — are always the ones where they didn't know the camera was there. Mid-laugh, mid-sentence, caught completely off guard. But here's the thing: you can't just tell someone "act natural." The moment you say that, it's over.

So I thought — what if the camera itself could trick you into forgetting about it?

That's how **Unposed** started.

## What It Does

Unposed is a photobooth app, but one that actively works against you knowing when the photo is being taken.

You pick your strip layout, choose how many frames you want, and hit start. From there, the app takes over. It runs what I call a **misdirection engine** — it throws fake countdowns at you, plays false shutter sounds, flashes the screen, pops up random emojis, sometimes does absolutely nothing for an uncomfortable amount of time... and then takes the actual photo when you've completely given up trying to be ready.

Each session gets a random **mood** at the start — sneaky, chaotic, calm, playful, ghostly — and that shapes everything about how the misdirection plays out. How many fakes you get, how long the silences last, whether the countdown is even telling the truth. The engine also remembers what tricks it already pulled so it doesn't repeat itself within a session.

What you end up with is a strip of genuinely candid moments. You laughing because a countdown just lied to you. You looking confused because nothing happened for five seconds straight. You mid-blink because the photo snapped right after a fake flash. Those are the good ones.

<p align="center">
  <img src="screenshots/FinalStrip.PNG" width="280" alt="A finished photo strip" />
</p>

## Screenshots

<p align="center">
  <img src="screenshots/Intro_Screen.PNG" width="220" alt="Intro screen with curtains" />
  &nbsp;&nbsp;
  <img src="screenshots/SetUpYourBoothScreen.PNG" width="220" alt="Booth setup screen" />
  &nbsp;&nbsp;
  <img src="screenshots/Camera_Preview_Screen.PNG" width="220" alt="Camera preview with face-tracked props" />
</p>

<p align="center">
  <img src="screenshots/Strip_Preview_Screen.PNG" width="220" alt="Strip preview after capture" />
  &nbsp;&nbsp;
  <img src="screenshots/PersonaliseScreen.PNG" width="220" alt="Personalisation screen" />
  &nbsp;&nbsp;
  <img src="screenshots/PersoinaliseScreen_With Accents.PNG" width="220" alt="Personalisation with accent overlays" />
</p>

<p align="center">
  <img src="screenshots/Personalise_Screen_DetailsSection.PNG" width="220" alt="Adding personal details to strip" />
  &nbsp;&nbsp;
  <img src="screenshots/FinalStrip.PNG" width="220" alt="Final exported strip" />
</p>

## Features

### 📸 Misdirection Engine
This is the heart of the app. It's a weighted randomisation system that builds unique "beat sequences" for every single frame — mixing real and fake countdowns, shutter sounds, haptic pulses, emoji distractions, screen flashes, and plain silence. A session mood gets picked at the start and the engine evolves its tricks as it goes. I spent most of my time on this because the whole app falls apart if the misdirection feels predictable.

### 🎭 Face-Tracked Props
I used Apple's Vision framework for real-time face landmark detection. You can pick from a bunch of built-in props — sunglasses, hats, wigs, a joker face, a masquerade mask — and they track your face live in the camera feed. The masks align to your actual eye positions. And yes, the props show up in your final captured photos too, not just the preview.

### ✂️ Prop Scanner
This one was fun to build. You can point the camera at literally any object, take a photo, and the app uses `VNGenerateForegroundInstanceMaskRequest` to isolate it from the background. Then you pick where it should sit on your face (eyes, forehead, nose, chin, or hand) and it becomes a fully face-tracked prop. Want to wear a banana as a hat? Go for it.

### 🖼 Strip Layouts
Three styles to choose from:
- **Vertical** — the classic photo strip look (2, 3, or 4 frames)
- **Grid** — 2×2, 2×3, or 2×4 grid layouts (4, 6, or 8 frames)
- **Polaroid** — a single candid shot with that instant-photo vibe

### 🎨 Full Personalisation
Once you've got your photos, you can customise the strip before saving:
- Pick a solid background colour or use a pattern
- Choose custom colours through the system colour picker
- Add accent overlays — hearts, stars, dots, flowers, cosmic particles, stamps — that scatter around your photos
- Write a personal message, add a date stamp, or drop in a signature
- Import your own pattern image from your photo library

### 🎬 Curtain Transition
When you open the app, velvet curtains part to reveal the booth. It's a small thing, but honestly, if you're building a photobooth app you have to commit to the bit.

## How the Misdirection Actually Works

I want to explain this part properly because it's not just "random delays." Each frame goes through a full composition pipeline:

1. **Mood selection** — at the start of every session, a mood is randomly picked (sneaky, chaotic, calm, playful, ghostly). This sets all the weights — how likely silence is vs. fakes vs. honest countdowns.

2. **Type selection** — for each frame, the engine picks a misdirection type: silent surprise, lying countdown, fake barrage, delayed nothing, instant ambush, long con, countdown abandoned, or reverse expectation. Types that were used recently get heavily penalised so they don't repeat.

3. **Beat composition** — the chosen type gets expanded into an actual sequence of beats: countdown ticks, fake flashes, fake shutter sounds, haptic pulses, emoji pop-ups, silence gaps. Each type has its own composition logic.

4. **Secondary injection** — extra surprise beats get layered on top for more variety. A random emoji might fire during what seemed like a calm countdown, or a haptic might pulse out of nowhere.

5. **Deduplication** — if the resulting beat sequence looks too similar to a recent one, it gets mutated until it feels different.

6. **Post-capture decoy** — after the *real* photo is taken, sometimes a fake flash or emoji still fires. Just to mess with you for the next frame.

The whole idea is that you genuinely cannot learn the pattern, because there isn't one. Every session is different. Every frame within a session is different.

## Tech Stack

Everything is built from scratch using Apple's own frameworks — no third-party dependencies at all.

| Area | What I Used |
|---|---|
| UI | SwiftUI with a dark theme and soft pink palette |
| Camera | AVFoundation — `AVCaptureSession` with both photo and video data outputs |
| Face Tracking | Vision framework — `VNDetectFaceLandmarksRequest` |
| Hand Detection | Vision framework — `VNDetectHumanHandPoseRequest` |
| Subject Isolation | Vision — `VNGenerateForegroundInstanceMaskRequest` combined with Core Image masking |
| Orientation Handling | `AVCaptureDevice.RotationCoordinator` for proper rotation across device orientations |
| Haptics | UIKit haptic feedback engine with randomised intensity patterns |
| Strip Export | `UIGraphicsImageRenderer` for high-resolution strip rendering |
| Persistence | Custom props saved as PNG files with JSON metadata to the Documents directory |

## Swift Student Challenge 2025

I built this as my submission for the **Swift Student Challenge**. The whole project is a Swift Playground app (`.swiftpm`) — no Xcode project file, no SPM dependencies, no CocoaPods, nothing external. Everything from the misdirection engine to the face tracking pipeline to the strip renderer was written from scratch.

## Requirements

- iOS 17.0+
- iPhone or iPad with a camera
- Camera permission (kind of essential for a photobooth)

## How to Run

Open `Unposed.swiftpm` in **Swift Playgrounds** on iPad or in **Xcode** on Mac. You'll need to run it on a physical device since the camera is required — the simulator won't cut it.

---

<p align="center">
  <sub>Built with a lot of coffee, a lot of fake shutter sounds, and a deep dislike for posed photos.</sub>
</p>
