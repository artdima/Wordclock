# Verbarius Screen Saver (macOS)

Заставка для macOS: время прописью из `English.json` / `Russia.json`.

## Сборка

1. Открыть `VerbariusScreenSaver.xcodeproj` в корне репозитория.
2. Выбрать схему `VerbariusScreenSaver`, `Product → Build` (⌘B).
3. В навигаторе `Products` → правый клик на `VerbariusScreenSaver.saver` → `Show in Finder`.
4. Двойной клик по `.saver` — macOS предложит установить, либо скопировать вручную
   в `~/Library/Screen Savers/`.
5. `Системные настройки → Заставка → Verbarius`. Кнопка «Параметры» открывает
   выбор языка, разнообразия формулировок, смещения текста и размера шрифта.

После пересборки заставку нужно скопировать заново, а System Settings — перезапустить
(процесс `legacyScreenSaver` кэширует бандл; помогает `killall legacyScreenSaver`).

## Устройство

| Файл | Роль |
|---|---|
| `VerbariusScreenSaverView.swift` | `ScreenSaverView`, хостит SwiftUI и отдаёт configure sheet |
| `ClockEngine.swift` | тик раз в 0.5 с, выбор фразы на текущую минуту, дрейф текста |
| `ClockLibrary.swift` | разбор JSON: `value_1…value_N` → массив вариантов |
| `ClockScreen.swift` | полноэкранная вёрстка текста |
| `ConfigureView.swift` | окно настроек |
| `Settings.swift` | хранение настроек в `ScreenSaverDefaults` |

Ресурсы `English.json` и `Russia.json` берутся из корня репозитория — копии не создаются.

## Важное

- Ресурсы грузятся через `Bundle(for:)`, а не `Bundle.main`: начиная с macOS 14
  заставка работает в чужом процессе (`legacyScreenSaver`), и `Bundle.main` — это он.
- Ключ времени формируется `DateFormatter` с `en_US_POSIX` и `HH:mm`, иначе при
  12-часовом формате системы ключи вида `09:41` не совпадут.
- Вариант фразы выбирается детерминированно от номера минуты — на всех мониторах
  одновременно показывается одна и та же формулировка.
