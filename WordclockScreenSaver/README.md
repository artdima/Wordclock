# Wordclock Screen Saver (macOS)

Заставка для macOS: время прописью из `English.json` / `Russian.json`.

## Сборка

1. Открыть `WordclockScreenSaver.xcodeproj` в корне репозитория.
2. Выбрать схему `WordclockScreenSaver`, `Product → Build` (⌘B). Проект подписывается
   ad hoc («Sign to Run Locally»), аккаунт разработчика для сборки не нужен.
3. В навигаторе `Products` → правый клик на `Wordclock.saver` → `Show in Finder`.
4. Двойной клик по `.saver` — macOS предложит установить, либо скопировать вручную
   в `~/Library/Screen Savers/`.
5. `Системные настройки → Заставка → Wordclock`. Кнопка «Параметры» открывает
   выбор языка, разнообразия формулировок, смещения текста и размера шрифта.

После пересборки заставку нужно скопировать заново, а System Settings — перезапустить
(процесс `legacyScreenSaver` кэширует бандл; помогает `killall legacyScreenSaver`).

## Релиз

```sh
xcrun notarytool store-credentials wordclock --apple-id <id> --team-id <TEAM> --password <app-specific>
WORDCLOCK_TEAM_ID=<TEAM> scripts/release.sh
```

Скрипт собирает Release с подписью `Developer ID Application` и hardened runtime,
нотаризует zip, прикрепляет тикет (`stapler`) и кладёт `dist/Wordclock-<версия>.saver.zip`.
Версия берётся из `MARKETING_VERSION` проекта.

## Устройство

| Файл | Роль |
|---|---|
| `WordclockScreenSaverView.swift` | `ScreenSaverView`, хостит SwiftUI и отдаёт configure sheet |
| `ClockEngine.swift` | тик раз в 0.5 с, выбор фразы на текущую минуту, дрейф текста |
| `ClockLibrary.swift` | разбор JSON: `value_1…value_N` → массив вариантов, кэш по языку |
| `ClockScreen.swift` | полноэкранная вёрстка текста |
| `ConfigureView.swift` | окно настроек |
| `Settings.swift` | файл настроек в Application Support, атомарная запись, чтение по mtime |
| `Localizable.xcstrings` | строки окна настроек, en + ru |
| `../scripts/validate_phrases.py` | проверка JSON: 1440 минут, нет пустых и дублей, фраза соответствует минуте |
| `../scripts/release.sh` | сборка под Developer ID, нотаризация |

Ресурсы `English.json` и `Russian.json` берутся из корня репозитория — копии не создаются.

## Важное

- Ресурсы грузятся через `Bundle(for:)`, а не `Bundle.main`: начиная с macOS 14
  заставка работает в чужом процессе (`legacyScreenSaver`), и `Bundle.main` — это он.
  По той же причине каждому `Text` в окне настроек явно передаётся бандл заставки —
  иначе SwiftUI ищет строку в хосте и показывает ключ без перевода.
- Ключ времени строится из `Calendar.autoupdatingCurrent`, а не `DateFormatter`:
  форматтер зависит от 12-часового формата системы и фиксирует часовой пояс при создании,
  а `legacyScreenSaver` живёт долго.
- Настройки — не в `ScreenSaverDefaults`, а в `Application Support/Wordclock/settings.plist`
  (в контейнере `legacyScreenSaver`). С macOS 14 System Settings держит два процесса
  `legacyScreenSaver` (окно «Параметры» и превью), а сама заставка — третий, который живёт
  между запусками; контейнер у них общий, кэш `UserDefaults` — нет, и записанное одним
  процессом другие не видят до перезапуска. Движок на каждом тике сравнивает mtime файла
  (один `stat`) и перечитывает его при изменении.
- Окно «Параметры» держит вью (хост хранит его слабо), создаётся заново на каждый запрос;
  если хост за секунду его не показал, вью выводит его сама плавающим окном и пишет в лог.
- По `com.apple.screensaver.willstop` вью сама останавливает анимацию: с Sonoma хост не
  вызывает `stopAnimation` и не уничтожает экземпляры, таймер иначе крутится вечно.
- macOS 26: кнопка «Параметры» иногда не срабатывает — System Settings теряет клик до
  обращения к заставке; лечится только перезапуском System Settings.
- Вариант фразы выбирается детерминированно от номера минуты — на всех мониторах
  одновременно показывается одна и та же формулировка.
- Пустые и обрамлённые пробелами значения в JSON отбрасываются при декодировании;
  ошибки загрузки пишутся в Console (`os.Logger`, subsystem — bundle id).
