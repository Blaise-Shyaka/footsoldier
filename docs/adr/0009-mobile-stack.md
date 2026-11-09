# ADR-0009: React Native (Expo) with SQLite for the mobile app

- Status: Proposed — **depends on team skills; confirm before Phase 2**
- Date: 2026-11-06

## Context

Phase 2 needs an offline-first app for Android and iOS, reliable on low-end Android devices
(~2 GB RAM), with camera, GPS, background sync and local storage. The form logic must match
the server and the web form filler exactly ([ADR-0006](0006-shared-form-logic.md)).

## Decision

Build the app with **React Native using Expo**, in TypeScript, with **SQLite** (`expo-sqlite`
+ Drizzle ORM) as the local store and a hand-written sync engine implementing
[ADR-0007](0007-offline-sync-protocol.md). The app imports the shared `form-runtime` package
used by the web.

## Consequences

- One TypeScript form runtime for web and mobile; only Ruby + TS need to agree.
- One codebase for Android and iOS; Expo handles builds and native modules for camera,
  location, secure storage and background tasks.
- OTA updates via the open `expo-updates` protocol can use Expo's hosted service or a
  self-hosted update server.
- Performance on very low-end devices needs active care (list virtualization, image handling,
  avoiding heavy re-renders) and testing on real hardware.

## Alternatives considered

- **Flutter + Drift (SQLite)** — excellent performance on low-end Android and a strong offline
  story; but needs a third form-runtime implementation (Dart) and a third language for the team.
  The best alternative if the team prefers Dart.
- **Hotwire Native** — reuses Rails views, but is web-view based and online-first; offline
  capture would need a parallel native implementation anyway.
- **PWA only** — no reliable background sync on iOS, storage eviction risk, weaker camera/GPS
  control; unacceptable for the reliability goal.
- **Kotlin Multiplatform / native apps** — highest fidelity, two UI codebases, highest cost.
- **Reuse ODK Collect** — proven offline collector, but no product branding/control and XForms
  coupling.
