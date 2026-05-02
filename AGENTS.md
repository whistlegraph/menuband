# Agent Notes

Repo-local context for future coding agents working on Menu Band.

## Shared Project Shape

- This is a SwiftPM-first macOS executable target named `MenuBand`.
- The repository is a GitHub mirror of the aesthetic.computer monorepo. Keep
  changes focused so patches are easy to apply upstream.

## Current Project Status

- Floating palette support exists in `Sources/MenuBand/FloatingPlayPalette.swift`.
- Menubar waveform strip support exists in
  `Sources/MenuBand/MenuBarWaveformStrip.swift`.
- The floating palette and the strip were styled to match the popover's
  waveform treatment, including bezel substrate, instrument-family tinting,
  MIDI dot-matrix mode, and popover-style instrument / held-note chrome.
- Full-surface dragging for the floating palette was tried and reverted because
  it interfered with smooth mouse note input on the floating piano.
- In Xcode, `BuildProject` and `XcodeRefreshCodeIssuesInFile` are reliable
  fast validation tools for these UI changes.

## UI Integration Notes

- Multiple `WaveformView` instances can be live at once (popover, floating
  palette, menubar strip). Waveform capture is shared through
  `MenuBandController.setWaveformCaptureEnabled(_:)` and must stay ref-counted.
  `WaveformView` also tracks its own capture lease; do not blindly call
  `setWaveformCaptureEnabled(false)` from a path that never successfully started
  capture, or one surface can blank another.
- There are two meaningful instrument states: `melodicProgram` is the committed
  choice, while `effectiveMelodicProgram` includes temporary hover-preview
  program changes from the popover. Any UI that should follow what the synth is
  currently sounding should use `effectiveMelodicProgram`.
- The menubar waveform strip has a footer row under the waveform: instrument
  name on the left, held notes centered. Future layout, animation, or sizing
  changes need to account for the strip's taller height and the live footer
  refresh behavior.
