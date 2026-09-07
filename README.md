# Wordclock

A macOS screen saver that tells the time in words — not `21:14`, but
“Fourteen minutes past nine”.

![Wordclock screen saver](icon.png)

Every minute of the day has its own set of phrasings, up to eleven of them, stored
in `English.json` and `Russia.json`. The saver picks one per minute and crossfades
to the next.

## About the idea

This project is made after the **Verbarius** clock designed at
[Art. Lebedev Studio](https://www.artlebedev.ru). It is an amateur example
implementation of the idea itself — a clock that spells the time out loud —
written from scratch and not used commercially.

The project is not affiliated with Art. Lebedev Studio and is not their product.
The Verbarius name, the original clock design and its firmware belong to the
studio. If you are a rights holder and believe anything in this repository
infringes on your rights, get in touch and it will be removed.

## Install

1. Open `WordclockScreenSaver.xcodeproj` in Xcode and build it (⌘B).
2. `Products → WordclockScreenSaver.saver → Show in Finder`, then double-click the
   file or copy it into `~/Library/Screen Savers/`.
3. `System Settings → Screen Saver → Wordclock`.

macOS 13 or newer.

## Options

The **Options** button in System Settings opens the saver’s settings:

| Setting | What it does |
|---|---|
| Language | Russian or English phrasings |
| Vary the wording | Pick a different phrasing every minute instead of always the first one |
| Shift the text | Slowly drift the text across the screen to spare the display |
| Text size | Scale the type up or down |

## Under the hood

Implementation notes — file layout, how the JSON is parsed, and the macOS 14
pitfalls worth knowing — are in
[`WordclockScreenSaver/README.md`](WordclockScreenSaver/README.md).

## License

See [LICENSE](LICENSE).
