# zapret-test 0.6.7.1

# Версия 0.6.7.1

В версии 0.6.6.9 исправлены: обновление доменных списков стало атомарным и авторитетным для соответствующего сервиса (без добавления устаревших bundled-доменов), добавлен fallback curl/wget → jsDelivr, отображается время последнего успешного обновления кэша, `ncat` имеет безусловный приоритет над `nc`, проверка кандидатов полностью блокируется после прерванного blockcheck, а приглашение к началу работы перенесено из installer в основной `zapret-test`.
- после `Ctrl-C` прерванный `blockcheck` больше не создаёт и не запускает `Sxxxx`-проверки на неполных данных;
- `ncat` имеет приоритет над `nc` для TCP-проверок, как требует upstream `zapret2`; BusyBox `nc` не используется;
- автоматическое обновление списков теперь явно показывает, был ли список реально обновлён или остался без изменений, а для каждого успешного обновления сохраняется checksum/time metadata;
- технический raw-вывод внешнего `blockcheck2.sh` не локализуется и не изменяется.

[Русская версия](#русский) · [English version](#english)

---

## Русский

### Быстрая установка

Для Bash/Zsh:

```sh
sh <(wget -O - https://raw.githubusercontent.com/SanKirSan/Zapret-test/main/bootstrap.sh)
```

Для OpenWrt/BusyBox `ash` используйте POSIX-вариант без process substitution:

```sh
wget -O - https://raw.githubusercontent.com/SanKirSan/Zapret-test/main/bootstrap.sh | sh
```

То же через `curl`:

```sh
curl -fsSL https://raw.githubusercontent.com/SanKirSan/Zapret-test/main/bootstrap.sh | sh
```

`zapret-test` — консольный диагностический стенд для OpenWrt/Linux, предназначенный для проверки доступности сервисов, DNS, HTTP/HTTPS, blockcheck/blockcheck2 и кандидатов стратегий `zapret`/`zapret2`.

Программа **не изменяет конфигурацию запущенного zapret/zapret2 без явного действия пользователя**. На время экспериментальных проверок она создаёт изолированное тестовое состояние, а после завершения выполняет rollback.

### Основные возможности

В версии 0.6.7.1 исправлены: автоматическое сохранение raw-отчётов blockcheck, сохранение AVAILABLE-кандидатов при прерывании и очистка известных BusyBox arithmetic-ошибок из консольного вывода; в прямой диагностике blockcheck убран лишний предварительный экран «ВЫБОР ПРОФИЛЯ».

В версии 0.6.6.9 исправлены: передача `Ctrl-C` в цепочке quick/full/automatic (частичный blockcheck больше не запускает проверку кандидатов), проверка стратегий через реальный IP с каскадом независимых DoH при синтетическом DNS, версия installer из единого `VERSION`, обязательный `ncat` для OpenWrt blockcheck2 и всех TCP-проверок, атомарное авторитетное обновление доменных списков без примеси устаревших bundled-доменов, fallback `curl/wget` → jsDelivr для raw GitHub-источников, отображение времени последнего успешного обновления cache, перенос приветствия с installer в основной `zapret-test`, произвольный выбор target домена после базовой TCP-проверки и сохранение подтверждённых рабочих стратегий для последующего теста совместимости. Raw-вывод внешнего `blockcheck2.sh` сохраняется без локализации.

- быстрый, полный и автоматический режимы тестирования;
- отдельный baseline без запуска blockcheck;
- blockcheck и blockcheck2 с live-выводом и корректным `Ctrl-C`;
- после выбора сервиса выполняется TCP baseline по валидным доменам, затем target можно выбрать вручную из полного списка или оставить автоматический первый домен;
- подтверждённые `PASS`-стратегии без side effects и без untested endpoints сохраняются в `/tmp/zapret-test/working-strategies/`;
- в меню `Диагностика blockcheck` добавлен режим `4) Совместимость стратегий`: стратегии запускаются автоматически на всех или выбранных доменах другого/исходного сервиса без ручного выбора каждой стратегии;
- расширенная диагностика стратегий только через `77 → Расширенная диагностика`;
- DNS integrity с локальным DNS, настроенными upstream-resolver'ами, DoH cross-check и отдельной проверкой TLS/DoT transport;
- native availability/network diagnostics для OpenWrt;
- подробная диагностика NVIDIA по группам;
- пользовательские сервисы и домены;
- автоматическое обновление расширенных доменных списков при запуске;
- кэш последнего успешно загруженного списка;
- русский и английский пользовательский интерфейс;
- поддержка нескольких Linux package managers;
- reproducible build через `Makefile`.

### Доменные списки

Для сервисов YouTube, Discord, Telegram, Meta/Instagram и TikTok программа при запуске обновляет списки из репозитория `itdoginfo/allow-domains`. Репозиторий разделяет списки по категориям, сервисам и странам и публикует отдельные RAW-файлы для YouTube, Discord, Telegram, Meta и TikTok. См. [репозиторий itdoginfo/allow-domains](https://github.com/itdoginfo/allow-domains).

Используются текущие источники:

```text
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/youtube.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/discord.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/telegram.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/meta.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/tiktok.lst
```

Например, список YouTube включает дополнительные служебные и медиадомены; аналогично расширены Discord, Telegram, Meta и TikTok.

Загруженный список проходит проверку доменов и обязательных sentinel-значений до атомарной замены кэша. Успешный источник полностью заменяет домены соответствующего сервиса; устаревшие bundled-домены к нему не добавляются. Для `raw.githubusercontent.com` при недоступности основного источника используется jsDelivr. При недоступности источников используется последняя валидная копия с отображением времени последнего успешного обновления. При отсутствии и сети, и валидного кэша остаётся встроенный список.

Отключение автообновления:

```sh
sed -i 's/^ENABLE_LIST_AUTOUPDATE=.*/ENABLE_LIST_AUTOUPDATE=0/' /etc/zapret-test/config
```

Или задайте в `/etc/zapret-test/config`:

```text
ENABLE_LIST_AUTOUPDATE=0
```

### Встроенные сервисы

В основной базе сохранены:

```text
YouTube
Discord
Telegram
Google
Instagram
TikTok
NVIDIA
Reddit
Twitch
Steam
```

`RuTracker` удалён из встроенного списка сервисов. Его отсутствие не означает, что его нельзя проверить вообще: отдельные availability-тесты могут содержать свои контрольные адреса для сетевой диагностики.

### Меню

```text
[1] Быстрый тест
[2] Полный тест
[3] Автоматический тест
[4] Только базовая проверка
[5] Выбор движка
[6] Диагностика blockcheck
[7] Диагностика доступности / сети
[8] Добавить свой сервис
[77] Сервисное меню
[0] Выход
```

`Ctrl-C` корректно прерывает текущий blockcheck и зависимый сценарий; неполный blockcheck не передаётся в проверку кандидатов. После восстановления сервисов управление возвращается в меню.

### Последовательность режимов

```text
[1] Быстрый тест
    baseline
    ↓
    blockcheck quick
    ↓
    проверка найденных кандидатов

[2] Полный тест
    baseline
    ↓
    blockcheck full
    ↓
    проверка найденных кандидатов

[3] Автоматический тест
    baseline
    ↓
    blockcheck standard для найденных движков
    ↓
    анализ найденных кандидатов

77 → [5] Расширенная диагностика
    ↓
    подробная диагностика кандидатов с Cxxxx
```


### Расширенная диагностика

`77 → [5] Расширенная диагностика` предназначен для тяжёлых и подробных проверок.

Обычные `[1]`, `[2]`, `[3]` проверяют найденные стратегии под нейтральными идентификаторами `ZAPRET2-S0001`, `ZAPRET2-S0002`, ... . Глубокие `ZAPRET2-C0001`, `ZAPRET2-C0002`, ... зарезервированы только для этого раздела.

### Blockcheck

Один запуск blockcheck использует один target-домен. После выбора сервиса выводится полный список валидных доменов, а первый валидный домен выбирается автоматически.

Пример:

```text
TARGETS: YouTube
  [01] → youtube.com
  [02]   www.youtube.com
  [03]   googlevideo.com
  [04]   ytimg.com

Automatic target: youtube.com
```

Сырой вывод blockcheck сохраняется отдельно. Локализованный вывод программы не изменяет raw capture внешнего инструмента.

### DNS

Baseline и отдельные availability-тесты различают:

- локальный resolver роутера;
- настроенные upstream DNS resolver'ы;
- внешний DoH cross-check;
- отдельную TLS/DoT transport reachability.

Адреса из диапазона `198.18.0.0/15` трактуются как синтетические/test addresses и не считаются обычными удалёнными IP.

### Package managers

Installer определяет и использует:

```text
apk           OpenWrt / Alpine
opkg          старые OpenWrt
apt           Debian / Ubuntu и совместимые системы
dnf           Fedora / RHEL и совместимые системы
yum           legacy RPM-системы
pacman        Arch Linux и совместимые системы
zypper        openSUSE / SUSE
```

Карта имён пакетов хранится в `requirements.conf`. У одного и того же бинарника разные Linux-дистрибутивы могут использовать разные имена пакетов.

### Установка на OpenWrt

```sh
cd /tmp
rm -rf /tmp/zapret-test
unzip -q zapret-test-0.6.7.1.zip
cd /tmp/zapret-test
chmod +x install.sh
./install.sh
```

Запуск:

```sh
zapret-test
```

CLI:

```sh
zapret-test detect
zapret-test services
zapret-test baseline
zapret-test quick
zapret-test full
zapret-test auto
zapret-test blockcheck
zapret-test blockcheck1
zapret-test blockcheck2
zapret-test requirements
zapret-test external
zapret-test stop
```

### Отчёты

```text
/tmp/rezult_zapret.txt
/tmp/rezult_zapret.json
/tmp/zapret-best.conf
/tmp/zapret2-best.conf
/tmp/zapret-test/
```

### Сборка

Основной build entrypoint — `Makefile`.

```sh
make check
make package
```

Для CI:

```sh
make check
sha256sum zapret-test-0.6.6.9.zip
```

Подробные инструкции находятся в `BUILD.md`.

### Структура проекта

```text
zapret-test/
├── zapret-test
├── install.sh
├── Makefile
├── build.sh
├── bootstrap.sh
├── BUILD.md
├── README.md
├── CHANGELOG.md
├── VERSION
├── RELEASE
├── requirements.conf
├── domain-sources.conf
├── services.conf
├── availability.conf
├── external-tests.conf
├── profiles/
├── strategies/
├── compat/
└── upstream/
```

### Безопасность и ограничения

`zapret-test` — диагностический инструмент. Ответ HTTP 3xx/403 сам по себе не доказывает блокировку или работоспособность приложения. Аналогично, успешный DNS/TCP/TLS тест не означает, что весь workflow сервиса работает.

Кандидаты blockcheck являются экспериментальными свидетельствами. Программа не должна автоматически считать неизвестную стратегию рабочей только потому, что внешняя команда завершилась без ошибки.

### Источники доменных списков

См. [репозиторий itdoginfo/allow-domains](https://github.com/itdoginfo/allow-domains).

---

## English

### One-line installation

For Bash/Zsh:

```sh
sh <(wget -O - https://raw.githubusercontent.com/SanKirSan/Zapret-test/main/bootstrap.sh)
```

For OpenWrt/BusyBox `ash`, use the POSIX pipe form:

```sh
wget -O - https://raw.githubusercontent.com/SanKirSan/Zapret-test/main/bootstrap.sh | sh
```

The `curl` equivalent is:

```sh
curl -fsSL https://raw.githubusercontent.com/SanKirSan/Zapret-test/main/bootstrap.sh | sh
```

`zapret-test` is a CLI diagnostic harness for OpenWrt/Linux. It tests service reachability, DNS, HTTP/HTTPS, blockcheck/blockcheck2 and candidate `zapret`/`zapret2` strategies.

The tool **does not rewrite the installed zapret/zapret2 configuration without an explicit user action**. Experimental checks use isolated test state and perform rollback afterwards.

### Features

- quick, full and automatic test modes;
- baseline-only mode without blockcheck;
- blockcheck and blockcheck2 with live output and proper `Ctrl-C` handling;
- expensive extended strategy diagnostics only under `77 → Extended diagnostics`;
- DNS integrity checks with local DNS, configured upstream resolvers, DoH cross-check and separate TLS/DoT transport reachability;
- native OpenWrt availability/network diagnostics;
- grouped NVIDIA diagnostics;
- custom services and domains;
- automatic domain-list refresh on startup;
- last-known-good list cache;
- Russian and English UI;
- multiple Linux package managers;
- reproducible builds with `Makefile`.

### Domain lists and automatic updates

At startup, the program refreshes expanded service lists for YouTube, Discord, Telegram, Meta/Instagram and TikTok from `itdoginfo/allow-domains`. The repository publishes RAW service lists and documents multiple list formats and service/category organization. See the [itdoginfo/allow-domains repository](https://github.com/itdoginfo/allow-domains).

Configured sources:

```text
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/youtube.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/discord.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/telegram.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/meta.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/tiktok.lst
```

The downloader validates the received data before replacing the cache. When the upstream repository is temporarily unavailable, the last cached list is used. When neither the network nor a cache is available, the bundled curated list remains active.

Disable automatic refresh in `/etc/zapret-test/config`:

```text
ENABLE_LIST_AUTOUPDATE=0
```

### Built-in services

```text
YouTube
Discord
Telegram
Google
Instagram
TikTok
NVIDIA
Reddit
Twitch
Steam
```

The built-in `RuTracker` service has been removed from the service database.

### Main menu

```text
[1] Quick test
[2] Full test
[3] Automatic test
[4] Baseline only
[5] Select engine
[6] Blockcheck diagnostics
[7] Availability / network diagnostics
[8] Add custom service
[77] Service menu
[0] Exit
```

`Ctrl-C` interrupts the current blockcheck and dependent scenario; partial blockcheck data is never passed to candidate verification. After service restoration control returns to the menu.

### Extended diagnostics

`77 → [5] Extended diagnostics` is reserved for expensive and detailed checks.

Normal `[1]`, `[2]`, and `[3]` verify detected strategies using neutral `ZAPRET2-S0001`, `ZAPRET2-S0002`, ... identifiers. Deep `ZAPRET2-C0001`, `ZAPRET2-C0002`, ... identifiers are reserved exclusively for this section.

Execution flow: `[1]` Quick = baseline -> quick blockcheck; `[2]` Full = baseline -> full blockcheck; `[3]` Automatic = baseline -> standard blockcheck for detected engines -> candidate analysis.

### Blockcheck

One blockcheck execution uses one target domain. After selecting a service, the complete list of valid service domains is displayed and the first valid domain is selected automatically.

The raw output from external tools remains separate from the localized wrapper output.

### DNS diagnostics

The diagnostic layer distinguishes:

- the router's local resolver;
- configured upstream resolvers;
- external DoH comparison;
- separate TLS/DoT transport reachability.

`198.18.0.0/15` is treated as synthetic/test address space instead of a normal remote destination.

### Package managers

The installer detects:

```text
apk           OpenWrt / Alpine
opkg          legacy OpenWrt
apt           Debian / Ubuntu and compatible systems
dnf           Fedora / RHEL and compatible systems
yum           legacy RPM systems
pacman        Arch Linux and compatible systems
zypper        openSUSE / SUSE
```

Package-name mappings are stored in `requirements.conf` because the same command can belong to differently named packages on different distributions.

### Installation on OpenWrt

```sh
cd /tmp
rm -rf /tmp/zapret-test
unzip -q zapret-test-0.6.6.9.zip
cd /tmp/zapret-test
chmod +x install.sh
./install.sh
```

Run:

```sh
zapret-test
```

CLI:

```sh
zapret-test detect
zapret-test services
zapret-test baseline
zapret-test quick
zapret-test full
zapret-test auto
zapret-test blockcheck
zapret-test blockcheck1
zapret-test blockcheck2
zapret-test requirements
zapret-test external
zapret-test stop
```

### Reports

```text
/tmp/rezult_zapret.txt
/tmp/rezult_zapret.json
/tmp/zapret-best.conf
/tmp/zapret2-best.conf
/tmp/zapret-test/
```

### Build

Use the included `Makefile`:

```sh
make check
make package
```

For CI:

```sh
make check
sha256sum zapret-test-0.6.6.9.zip
```

See `BUILD.md` for detailed build instructions.

### Project layout

```text
zapret-test/
├── zapret-test
├── install.sh
├── Makefile
├── build.sh
├── bootstrap.sh
├── BUILD.md
├── README.md
├── CHANGELOG.md
├── VERSION
├── RELEASE
├── requirements.conf
├── domain-sources.conf
├── services.conf
├── availability.conf
├── external-tests.conf
├── profiles/
├── strategies/
├── compat/
└── upstream/
```

### Limitations

An HTTP 3xx/403 response is not, by itself, proof of blocking or full application functionality. Successful DNS/TCP/TLS checks also do not prove that an entire application workflow works.

Blockcheck candidates are experimental evidence. Unknown strategies must not be treated as working solely because an external command returned successfully.


License - MIT
