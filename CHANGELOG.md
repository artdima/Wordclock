# Changelog

## 1.1 — 2026-10-12

**Install.** Signed with a Developer ID and notarized: unzip, double-click, done. No more
removing the quarantine attribute by hand.

**Upgrading from 1.0.** The saver is now `Wordclock.saver` with a new bundle identifier.
Delete the old `WordclockScreenSaver.saver` from `~/Library/Screen Savers/`, otherwise System
Settings shows two entries. Settings start from the defaults again.

### Fixed
- Changes made in **Options** now reach the preview and the running screen saver right away.
- The **Options** window opens and closes reliably on macOS 14 and later.
- A blank screen for up to a minute at the top of some hours in Russian.
- Wrong or duplicate phrasings at 14:00 and midnight in English; time-of-day words at 05:00
  and 23:30 in Russian.
- The time could stop matching the clock after a time-zone change.
- The screen saver kept animating in the background after it was dismissed.

### Changed
- English and a 55 % text size by default.
- The Options window is in English and Russian and shows the text size in percent.
- A thumbnail in System Settings instead of a blank tile.

### Known issues
- macOS 26: System Settings sometimes ignores a click on **Options**. Quit and reopen System
  Settings.

## 1.0 — 2026-09-07

First release.
