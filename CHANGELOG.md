# 0.6.6.6

- Исправлено создание/вывод Sxxxx после прерывания blockcheck.
- `ncat` теперь имеет приоритет над `nc` для TCP probe.
- Обновление списков показывает `ОБНОВЛЕНО` или `без изменений` и сохраняет метаданные checksum/time.
- README.md и BUILD.md обновлены до 0.6.6.6.

# CHANGELOG

## 0.6.6.6
- Исправлен stale/corrupted cache доменных списков: успешное обновление полностью заменяет кэш, старый кэш не примешивается; добавлены sentinel-домены и строгая валидация.
- Исправлено продолжение quick/full/automatic после `Ctrl-C`: частичные blockcheck-данные не запускают проверку кандидатов.
- Кандидатная проверка больше не считает домены без подтверждённого реального IP как FAIL; такие endpoints считаются untested, а при отсутствии тестируемых endpoints кандидат получает SKIPPED.
- Кандидатные и side-effect проверки используют реальный IP с каскадом независимых DoH и `--resolve` при синтетическом DNS.
- Installer берёт версию из единого `VERSION` и выводит фактическую версию установленного пакета.
- Для OpenWrt blockcheck2 `ncat` является обязательной зависимостью; BusyBox `nc` остаётся optional.
- README.md и BUILD.md обновлены до 0.6.6.6.

# Changelog
## 0.6.6.4

- Исправлено продолжение quick/full/automatic/combined/debug цепочек после `Ctrl-C`: частичный blockcheck не запускает проверку неполного набора кандидатов.
- Исправлена проверка найденных стратегий при отравленном/синтетическом локальном DNS: для проверки кандидата используется IP из DoH через `curl --resolve`.
- Installer теперь получает версию из `VERSION` и проверяет соответствие `VERSION`/`RELEASE`.
- Для OpenWrt добавлен обязательный `ncat`; BusyBox `nc` оставлен необязательным fallback, поскольку upstream blockcheck2 его не принимает.
- Добавлена валидация обновляемых списков YouTube/Discord/Telegram/Instagram/TikTok по контрольным доменам перед заменой кэша.
- README.md и BUILD.md обновлены до 0.6.6.4.

## 0.6.6.3

- Enforced explicit candidate namespaces: normal quick/full/automatic flows use only `Sxxxx`; only `77 -> [5] Extended diagnostics` may create `Cxxxx`.
- Prevented deep-diagnostics state leakage across interrupted or subsequent menu operations.
- Added detection and termination of manually started `nfqws`/`nfqws2` processes before blockcheck, in addition to init-managed services.
- Localized the human-facing blockcheck runtime tags and common upstream informational/warning messages while preserving raw upstream output unchanged.
- Displayed the `force` upstream scan level as `full` in the user interface and documented the requested quick/full/automatic execution flows.
- Version 0.6.6.3.

## 0.6.6.2

- Fixed SIGINT/SIGTERM handling so nested blockcheck/external/strategy handlers no longer overwrite the permanent top-level signal dispatcher.
- Fixed blockcheck2 LIVE TEST cleanup by tracking `tee`, summary reader and upstream process group independently; Ctrl-C now terminates the complete process tree and returns exit code 130.
- Direct blockcheck menu entries now stop installed zapret/zapret2 services before starting diagnostics, matching upstream blockcheck requirements.
- Restored the upstream blockcheck2 default curl timeout of 2 seconds through dedicated `BLOCKCHECK_CURL_MAX_TIME` variables instead of reusing the generic 10-second test timeout.
- Blockcheck2 summaries now distinguish an untested port from a confirmed unavailable port and no longer mix port results into strategy availability counts.
- Non-zero upstream blockcheck2 exits are now propagated instead of being reported as a successful test.


## 0.6.6.1

- Fixed stale blockcheck target reuse between service selections.
- Normal quick/full/automatic strategy verification now uses `Sxxxx` identifiers; deep `Cxxxx` diagnostics remain exclusive to `77 -> [5]`.
- Flattened all common service/domain result displays, including NVIDIA.
- Added canonical primary domains so expanded lists do not select a random auxiliary host for automatic blockcheck.
- Preserved dynamic domain-list refresh, multilingual UI, package-manager detection and reproducible build work from 0.6.6.0.

## 0.6.6.0

- Expanded YouTube, Discord, Telegram, Instagram and TikTok domain lists.
- Added automatic upstream domain-list refresh with cache fallback.
- Removed RuTracker from built-in services.
- Added bilingual documentation and multi-package-manager support.
