#!/usr/bin/env python3
"""Checks English.json and Russian.json: structure, blanks, and that every phrase names its own minute.

a.m./p.m. follows the current hour, not the hour counted down to: 11:17 is "forty-three minutes to twelve a.m."."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MINUTES = [f"{h:02d}:{m:02d}" for h in range(24) for m in range(60)]

EN_HOURS = ["twelve", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven"]
EN_ONES = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve",
           "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
EN_TENS = {2: "twenty", 3: "thirty", 4: "forty", 5: "fifty"}

RU_NOM = {"ноль": 0, "один": 1, "одна": 1, "два": 2, "две": 2, "три": 3, "четыре": 4, "пять": 5, "шесть": 6,
          "семь": 7, "восемь": 8, "девять": 9, "десять": 10, "одиннадцать": 11, "двенадцать": 12,
          "тринадцать": 13, "четырнадцать": 14, "пятнадцать": 15, "шестнадцать": 16, "семнадцать": 17,
          "восемнадцать": 18, "девятнадцать": 19, "двадцать": 20, "тридцать": 30, "сорок": 40, "пятьдесят": 50}
RU_GEN = {"одной": 1, "двух": 2, "трех": 3, "четырех": 4, "пяти": 5, "шести": 6, "семи": 7, "восьми": 8,
          "девяти": 9, "десяти": 10, "одиннадцати": 11, "двенадцати": 12, "тринадцати": 13, "четырнадцати": 14,
          "пятнадцати": 15, "шестнадцати": 16, "семнадцати": 17, "восемнадцати": 18, "девятнадцати": 19,
          "двадцати": 20, "тридцати": 30, "сорока": 40, "пятидесяти": 50}
RU_ORD = {"первого": 1, "второго": 2, "третьего": 3, "четвертого": 4, "пятого": 5, "шестого": 6, "седьмого": 7,
          "восьмого": 8, "девятого": 9, "десятого": 10, "одиннадцатого": 11, "двенадцатого": 12}
RU_SPECIAL = {"полдень": 12, "полночь": 12, "четверть": 15, "четверти": 15, "половина": 30}


def en_number(n):
    if n < 20:
        return EN_ONES[n]
    return EN_TENS[n // 10] + ("-" + EN_ONES[n % 10] if n % 10 else "")


def en_phrase_ok(h, m, phrase):
    s = phrase.lower().replace("\u2019", "'")
    hour, next_hour = EN_HOURS[h % 12], EN_HOURS[(h + 1) % 12]
    if s.endswith("a.m.") and h >= 12:
        return False
    if s.endswith("p.m.") and h < 12:
        return False
    if " to " in s:
        minutes_ok = en_number(60 - m) in s or (m == 45 and "quarter" in s)
        target_ok = next_hour in s or ((h + 1) % 24 == 0 and "midnight" in s) or ((h + 1) % 24 == 12 and "noon" in s)
        return minutes_ok and target_ok
    if m == 0:
        return hour in s or (h == 12 and "noon" in s) or (h == 0 and "midnight" in s)
    if "past" in s:
        minutes_ok = en_number(m) in s or (m == 15 and "quarter" in s) or (m == 30 and "half" in s)
        target_ok = hour in s or (h == 0 and "midnight" in s) or (h == 12 and "noon" in s)
        return minutes_ok and target_ok
    return s.startswith(hour) and en_number(m) in s


def ru_numbers(phrase):
    s = phrase.lower().replace("ё", "е").replace("пол-", "половина ")
    if s.strip() in ("полдень", "полночь"):
        return [12]
    s = re.sub(r"^пол(?!день|ночь)(\w+)", r"половина \1", s)
    tokens = re.findall(r"[а-я]+", s)
    out, i = [], 0
    while i < len(tokens):
        t, n = tokens[i], None
        if t in RU_NOM:
            n = RU_NOM[t]
            if n in (20, 30, 40, 50) and i + 1 < len(tokens) and 0 < RU_NOM.get(tokens[i + 1], 0) < 10:
                n += RU_NOM[tokens[i + 1]]
                i += 1
        elif t in RU_GEN:
            n = RU_GEN[t]
            if n in (20, 30, 40, 50) and i + 1 < len(tokens) and RU_GEN.get(tokens[i + 1], 99) < 10:
                n += RU_GEN[tokens[i + 1]]
                i += 1
        elif t in RU_ORD:
            n = RU_ORD[t]
        elif t in RU_SPECIAL:
            n = RU_SPECIAL[t]
        elif t in ("час", "часа") and (i == 0 or tokens[i - 1] not in RU_NOM):
            n = 1
        if n is not None:
            out.append(n)
        i += 1
    return out


def ru_phrase_ok(h, m, phrase):
    h12, next_h12 = h % 12 or 12, (h + 1) % 12 or 12
    expected = [[h, m], [h, 0, m], [h12, m], [h12, 0, m], [m, next_h12], [60 - m, next_h12]]
    if m == 45:
        expected.append([15, next_h12])
    if m == 0:
        expected += [[h12], [h], [12], [h12, 0, 0], [h, 0, 0], [h, 0]]
    return ru_numbers(phrase) in expected


def check(name, phrase_ok):
    errors = []
    path = ROOT / name
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        return [f"{name}: top level must be a list"]
    clocks = [entry.get("clock") for entry in data]
    if clocks != MINUTES:
        missing = sorted(set(MINUTES) - set(clocks))
        extra = sorted(set(clocks) - set(MINUTES))
        errors.append(f"{name}: expected 1440 minutes in order; missing {missing[:5]}, unexpected {extra[:5]}")
    for entry in data:
        clock = entry.get("clock", "?")
        phrases = []
        for key, value in entry.items():
            if key == "clock":
                continue
            if not re.fullmatch(r"value_\d+", key):
                errors.append(f"{name} {clock}: unexpected key {key!r}")
                continue
            if not isinstance(value, str):
                errors.append(f"{name} {clock} {key}: not a string")
                continue
            if value != value.strip() or "  " in value:
                errors.append(f"{name} {clock} {key}: stray whitespace in {value!r}")
            if not value.strip():
                errors.append(f"{name} {clock} {key}: blank phrase")
                continue
            phrases.append(value.strip())
        if not phrases:
            errors.append(f"{name} {clock}: no phrases")
        if len(set(phrases)) != len(phrases):
            errors.append(f"{name} {clock}: duplicate phrases")
        if re.fullmatch(r"\d\d:\d\d", clock or ""):
            h, m = int(clock[:2]), int(clock[3:])
            for phrase in phrases:
                if not phrase_ok(h, m, phrase):
                    errors.append(f"{name} {clock}: {phrase!r} does not describe this minute")
    return errors


def main():
    errors = check("English.json", en_phrase_ok) + check("Russian.json", ru_phrase_ok)
    for line in errors:
        print(line)
    print(f"{len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
