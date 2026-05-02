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

## MIDI Synth Troubleshooting Notes

- Audio output changes can alter `MenuBandSynth` timbre even when the selected
  instrument did not change. BlackHole 2ch <-> built-in output swaps were the
  concrete repro that exposed this.
- The important failure mode was not just `AVAudioEngineConfigurationChange`.
  The synth also needed to treat the Core Audio default output-device change
  (`kAudioHardwarePropertyDefaultOutputDevice`) as a first-class event.
- Reapplying state to the existing `MIDISynth` AU was not sufficient in this
  case. The more reliable recovery path was to rebuild the synth backend from
  logical state: clear connection flags, detach the old `midiSynth` node, clear
  `loadedPrograms`, reload sampler state, resume the engine if needed, then
  instantiate/configure a fresh MIDISynth backend.
- Keep the current GarageBand patch URL around if the backend may need to be
  rebuilt after a device change; otherwise only the GM program can be restored.
- If a future report says “the instrument sounds different after switching
  outputs,” check `Sources/MenuBand/MenuBandSynth.swift` first. Specifically,
  verify both the `AVAudioEngineConfigurationChange` observer and the default
  output-device listener/rebuild path still exist and still reapply bank/program
  state correctly.
- If the issue persists even after a full synth-backend rebuild, the remaining
  likely cause is external to app state: built-in speaker DSP/EQ, sample-rate
  conversion, or other system/device-side audio processing.
