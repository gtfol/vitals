# Verification

## What has been checked

Status as of the first build, September 25, 2026. Nothing has been installed on an iPhone yet.

- **Core logic, `swift test`:** 27 tests pass with Swift 6.3.3 in Swift 6 language mode with warnings as errors, on Linux (official `swift:6.3.3-noble` toolchain). They cover unit round trips, input parsing, bodyweight text, clocks and the rest timer, Epley limits, volume, records (baseline, ties, warm-ups, incomplete, bodyweight, edits and deletes, unit switching), exercise history, previous-session pairing, workout summaries, Heart Rate Measurement parsing (8/16-bit, contact, energy, RR, truncated packets, slices), battery, statistics, gaps, chart thinning, zones, the Health payload window, sync identifiers and recovery times.
- **Bluetooth and HealthKit services:** `HeartRateMonitor` and `HealthKitExporter` were type-checked with the same compiler settings against stand-in `CoreBluetooth` and `HealthKit` modules that mirror the API signatures and `Sendable` annotations Apple documents. That found a real Swift 6 data-race error, which is fixed. It doesn't replace compiling against the iOS SDK.
- **iOS build and XCTest:** GitHub Actions ([ios.yml](../.github/workflows/ios.yml)) builds for the simulator and for devices (unsigned) with Xcode 26.6 on macOS 26, checks that the committed project matches the generator, and runs the core, persistence and coordinator tests on an iPhone simulator. See the latest run on the branch for the current result.

The simulator tests use an on-disk SwiftData store and a fake exporter. They don't exercise a strap, Bluetooth, background execution, real HealthKit writes or the rendered interface.

## Physical iPhone checklist

Set up first: in Zepp, Device → Helio Strap → Health Monitoring → Heart Rate Push on. Fully quit Zepp before each Bluetooth test. Test HealthKit on a real iPhone, not only the simulator.

Lift log
- [ ] Log a strength workout with two exercises, completed working sets and warm-up sets. Change lb ↔ kg, use the rest timer (+30s, skip, lock the screen, reopen), finish, and reopen it from history with the same values and order.
- [ ] Repeat with no strap chosen and with Apple Health access denied. Every screen stays usable; the workout saves locally and shows "not allowed" for Apple Health.
- [ ] Start from a routine, edit the copied sets and remove an exercise; the routine is unchanged. Save a workout as a routine; edit and delete a routine.
- [ ] Log a heavier completed working set than any earlier session: "new best" shows in the workout and in exercise history. Edit it lower, then delete it: the record disappears and volume updates. Check a first-ever session (no record), a tie, a heavier warm-up, zero load and a bodyweight movement with added load (no weighted records).

Strap
- [ ] With Heart Rate Push on and Zepp quit: choose the Helio in settings, see live BPM, last sample time and battery (if reported).
- [ ] 30 minutes with the screen locked during a workout. Record how many samples arrive, and whether iOS kept delivering them.
- [ ] Walk out of range or power the strap off: the workout and sets stay, status shows reconnecting with the missing time, the chart shows a gap, and samples resume when the strap returns without anything filled in.
- [ ] Bluetooth off, then on; Bluetooth permission denied; a workout where no heart-rate packet ever arrives.
- [ ] State restoration: with a workout running, let iOS terminate vitals in the background (not a force-quit) and note whether iOS relaunches it for strap data. Record the result; iOS doesn't guarantee it.
- [ ] Heart Rate Push off: status says no heart rate and points to Zepp.

Apple Health
- [ ] With access allowed, finish a workout: exactly one workout with the right type, start and end, and the received heart-rate samples appears in the Health app.
- [ ] Force a failure (for example, finish while access is off, then turn it on) and retry: still exactly one workout. Retry again from history: nothing new is written.
- [ ] A workout with no heart-rate samples saves as a workout; a strength session with no completed sets saves as a heart-rate workout.

Relaunch
- [ ] Force-quit during a workout and reopen: the prompt offers continue or finish, the sets and start time are intact, finishing uses the last known activity time, and no second workout exists. The chart shows the closed period as a gap.

Accessibility
- [ ] VoiceOver through the set table, rest clock and heart-rate strip; the largest Dynamic Type size; a smaller iPhone.

Record results and dates here as they're checked, including any iOS limitation observed.
