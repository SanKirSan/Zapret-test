# Building zapret-test / Сборка zapret-test

## Русский

Для GitHub-раздачи добавьте `bootstrap.sh` в корень релиза и замените `OWNER/REPOSITORY` на фактический путь репозитория.

Сборка не требует OpenWrt: пакет создаётся обычным `make` на Linux/WSL/macOS при наличии POSIX shell и `zip`.

```sh
make
```

Проверка без создания архива:

```sh
make check
```

Архив создаётся как `zapret-test-VERSION.zip` и содержит один верхний каталог `zapret-test/`.

Версию задают одновременно в `VERSION`, `RELEASE` и `zapret-test`:

```sh
make VERSION=0.6.6.9
```

Для интеграции в CI используйте:

```sh
make check
make package
sha256sum zapret-test-*.zip
```

Installer поддерживает `apk` (OpenWrt/Alpine), `opkg`, `apt`, `dnf`, `yum`, `pacman` и `zypper`, выбирая имена пакетов из `requirements.conf`.

## English

For GitHub distribution, keep `bootstrap.sh` at the repository root and replace `OWNER/REPOSITORY` with the actual repository path.

The package can be built outside OpenWrt with a POSIX shell and `zip` available.

```sh
make
```

Run validation only:

```sh
make check
```

The resulting archive is `zapret-test-VERSION.zip` and contains exactly one top-level directory: `zapret-test/`.

Set the release version consistently with:

```sh
make VERSION=0.6.6.9
```

For CI:

```sh
make check
make package
sha256sum zapret-test-*.zip
```

The installer detects `apk` (OpenWrt/Alpine), `opkg`, `apt`, `dnf`, `yum`, `pacman`, and `zypper`, using the package mapping in `requirements.conf`.
