# pug_vpn

A new Flutter project.

## Android build notes (AmneziaWG)

- The Android AWG integration is connected as a git submodule (`android/amneziawg-android`).
- After clone, run:
  - `git submodule update --init --recursive`
- Build uses Gradle wrapper (`android/gradlew`) and requires a compatible JDK (`17..24`).
- On macOS/Linux wrapper tries to auto-pick JDK 21/17 if your default Java is too new.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
