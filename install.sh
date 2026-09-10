#!/bin/sh
set -u

NAME="zapret-test"
SRC="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
VERSION="$(cat "$SRC/VERSION" 2>/dev/null || echo unknown)"
ROOT="${PREFIX_ROOT:-}"
BIN="$ROOT/usr/bin/zapret-test"
LIB="$ROOT/usr/lib/zapret-test"
ETC="$ROOT/etc/zapret-test"

[ "$(id -u 2>/dev/null || echo 1)" = 0 ] || { echo "ERROR: run as root." >&2; exit 1; }
[ -f "$SRC/zapret-test" ] || { echo "ERROR: $SRC/zapret-test not found." >&2; exit 1; }
[ "$VERSION" = "$(cat "$SRC/RELEASE" 2>/dev/null || echo)" ] || { echo "ERROR: VERSION/RELEASE mismatch." >&2; exit 2; }
chmod +x "$SRC/zapret-test" 2>/dev/null || true


REQ_FILE="$SRC/requirements.conf"
RUN_ROOT="${PREFIX_RUN:-/tmp/${NAME}}"
mkdir -p "$RUN_ROOT" 2>/dev/null || true
INSTALL_LOG="$RUN_ROOT/install.log"

log(){ printf '%s\n' "$*" | tee -a "$INSTALL_LOG"; }

# Set REQUIREMENTS_STRICT=1 to make any unresolved requirement abort installation.
# Default is 0: install every package available in the selected package manager,
# record unresolved requirements explicitly, and still install the harness.
REQUIREMENTS_STRICT="${REQUIREMENTS_STRICT:-0}"

pkg_manager_detect(){
    if command -v apk >/dev/null 2>&1; then
        if [ -r /etc/openwrt_release ]; then PKG_MANAGER=apk-openwrt; else PKG_MANAGER=apk; fi
    elif command -v opkg >/dev/null 2>&1; then PKG_MANAGER=opkg
    elif command -v apt-get >/dev/null 2>&1; then PKG_MANAGER=apt
    elif command -v dnf >/dev/null 2>&1; then PKG_MANAGER=dnf
    elif command -v yum >/dev/null 2>&1; then PKG_MANAGER=yum
    elif command -v pacman >/dev/null 2>&1; then PKG_MANAGER=pacman
    elif command -v zypper >/dev/null 2>&1; then PKG_MANAGER=zypper
    else
        echo "ERROR: no supported package manager found." >&2
        echo "Supported: apk (OpenWrt/Alpine), opkg, apt, dnf, yum, pacman, zypper." >&2
        exit 2
    fi
    case "$PKG_MANAGER" in
        apk-openwrt|apk) PKG_MANAGER_VERSION="$(apk --version 2>/dev/null | head -n1 || echo unavailable)" ;;
        opkg) PKG_MANAGER_VERSION="$(opkg --version 2>/dev/null | head -n1 || echo unavailable)" ;;
        apt) PKG_MANAGER_VERSION="$(apt-get --version 2>/dev/null | head -n1 || echo unavailable)" ;;
        dnf) PKG_MANAGER_VERSION="$(dnf --version 2>/dev/null | head -n1 || echo unavailable)" ;;
        yum) PKG_MANAGER_VERSION="$(yum --version 2>/dev/null | head -n1 || echo unavailable)" ;;
        pacman) PKG_MANAGER_VERSION="$(pacman --version 2>/dev/null | head -n1 || echo unavailable)" ;;
        zypper) PKG_MANAGER_VERSION="$(zypper --version 2>/dev/null | head -n1 || echo unavailable)" ;;
    esac
}

check_manager_consistency(){
    release=""
    if [ -r /etc/openwrt_release ]; then . /etc/openwrt_release 2>/dev/null || true; release="${DISTRIB_RELEASE:-}"; fi
    case "$release" in
        25.*|26.*) [ "$PKG_MANAGER" = apk-openwrt ] || log "[WARN] OpenWrt $release normally uses apk" ;;
        24.*|23.*|22.*|21.*|20.*) [ "$PKG_MANAGER" = opkg ] || log "[WARN] OpenWrt $release normally uses opkg" ;;
    esac
}

pkg_installed(){
    pkg="$1"
    case "$PKG_MANAGER" in
        apk-openwrt|apk) apk info -e "$pkg" >/dev/null 2>&1 ;;
        opkg) opkg status "$pkg" 2>/dev/null | grep -q '^Status: install ok installed' ;;
        apt) dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed' ;;
        dnf|yum) rpm -q "$pkg" >/dev/null 2>&1 ;;
        pacman) pacman -Q "$pkg" >/dev/null 2>&1 ;;
        zypper) rpm -q "$pkg" >/dev/null 2>&1 ;;
    esac
}

pkg_update(){
    case "$PKG_MANAGER" in
        apk-openwrt|apk) apk update ;;
        opkg) opkg update ;;
        apt) DEBIAN_FRONTEND=noninteractive apt-get update ;;
        dnf) dnf -y makecache --refresh ;;
        yum) yum -y makecache ;;
        pacman) pacman -Sy --noconfirm ;;
        zypper) zypper --non-interactive refresh ;;
        *) return 1 ;;
    esac
}

pkg_available(){
    pkg="$1"
    case "$PKG_MANAGER" in
        apk-openwrt|apk) apk search -e "$pkg" 2>/dev/null | grep -q . ;;
        opkg) opkg list "$pkg" 2>/dev/null | grep -q "^${pkg} " ;;
        apt) apt-cache show "$pkg" >/dev/null 2>&1 ;;
        dnf) dnf -q list available "$pkg" >/dev/null 2>&1 || dnf -q info "$pkg" >/dev/null 2>&1 ;;
        yum) yum -q list available "$pkg" >/dev/null 2>&1 || yum -q info "$pkg" >/dev/null 2>&1 ;;
        pacman) pacman -Si "$pkg" >/dev/null 2>&1 ;;
        zypper) zypper --non-interactive search --match-exact "$pkg" >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}

pkg_install(){
    case "$PKG_MANAGER" in
        apk-openwrt|apk) apk add "$@" ;;
        opkg) opkg install "$@" ;;
        apt) DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
        dnf) dnf install -y "$@" ;;
        yum) yum install -y "$@" ;;
        pacman) pacman -S --noconfirm "$@" ;;
        zypper) zypper --non-interactive install -y "$@" ;;
        *) return 1 ;;
    esac
}

packages_snapshot(){
    out="$1"
    case "$PKG_MANAGER" in
        apk-openwrt|apk) apk info -vv 2>/dev/null >"$out" || apk info 2>/dev/null >"$out" || : ;;
        opkg) opkg list-installed 2>/dev/null >"$out" || : ;;
        apt) dpkg-query -W -f='${binary:Package} ${Version}\n' 2>/dev/null >"$out" || : ;;
        dnf|yum|zypper) rpm -qa 2>/dev/null >"$out" || : ;;
        pacman) pacman -Q 2>/dev/null >"$out" || : ;;
    esac
}

requirements_prepare(){
    [ -f "$REQ_FILE" ] || { echo "ERROR: $REQ_FILE missing." >&2; exit 3; }
    # Keep installation diagnostics inside the product runtime directory instead
    # of creating a new top-level /tmp/zapret-test-requirements-* directory on
    # every release. A single stable directory is reused across upgrades.
    REQ_ROOT="$RUN_ROOT"
    REQ_DIR="$REQ_ROOT/requirements"
    mkdir -p "$REQ_DIR" || { echo "ERROR: cannot create $REQ_DIR" >&2; exit 3; }

    # Remove legacy requirement directories created by pre-0.6.3.8 releases.
    for legacy in /tmp/${NAME}-requirements-*; do
        [ -d "$legacy" ] || continue
        [ "$legacy" = "$REQ_DIR" ] && continue
        rm -rf "$legacy" 2>/dev/null || true
    done
    REQ_BEFORE="$REQ_DIR/packages-before.txt"
    REQ_AFTER="$REQ_DIR/packages-after.txt"
    REQ_STATUS="$REQ_DIR/status.txt"
    REQ_UNRESOLVED="$REQ_DIR/unresolved.txt"

    # Package-manager preflight MUST happen before any package mutation.
    pkg_manager_detect
    check_manager_consistency
    {
        echo "zapret-test=$VERSION"
        echo "package_manager=$PKG_MANAGER"
        echo "package_manager_version=$PKG_MANAGER_VERSION"
        echo "snapshot_before=$REQ_BEFORE"
    } > "$REQ_STATUS"

    log "Package manager preflight: $PKG_MANAGER"
    log "Package manager version: $PKG_MANAGER_VERSION"
    packages_snapshot "$REQ_BEFORE"
    log "Installed package snapshot before: $REQ_BEFORE"

    if [ -n "$ROOT" ]; then
        log "PREFIX_ROOT=$ROOT detected: package mutation is skipped in test-root mode."
    else
        log "Refreshing package indexes before any package install..."
        if ! pkg_update; then
            log "ERROR: package index update failed. No packages were installed."
            exit 4
        fi
    fi

    MISSING_PKGS=""
    OPTIONAL_MISSING=""
    UNRESOLVED=""
    printf '%s\n' 'COMMAND|PACKAGE|MODE|COMMAND_STATUS|PACKAGE_STATUS|PURPOSE' > "$REQ_STATUS"
    while IFS='|' read -r cmd apk_pkg opkg_pkg apt_pkg dnf_pkg pacman_pkg zypper_pkg alpine_pkg mode purpose; do
        case "$cmd" in ''|\#*) continue;; esac
        case "$PKG_MANAGER" in
            apk-openwrt) pkg="$apk_pkg" ;;
            apk) pkg="$alpine_pkg" ;;
            opkg) pkg="$opkg_pkg" ;;
            apt) pkg="$apt_pkg" ;;
            dnf|yum) pkg="$dnf_pkg" ;;
            pacman) pkg="$pacman_pkg" ;;
            zypper) pkg="$zypper_pkg" ;;
        esac
        if command -v "$cmd" >/dev/null 2>&1; then cmd_status=INSTALLED; else cmd_status=MISSING; fi
        if pkg_installed "$pkg"; then pkg_status=INSTALLED
        elif pkg_available "$pkg"; then pkg_status=AVAILABLE
        else pkg_status=UNAVAILABLE
        fi
        printf '%s|%s|%s|%s|%s|%s\n' "$cmd" "$pkg" "$mode" "$cmd_status" "$pkg_status" "$purpose" >> "$REQ_STATUS"
        case "$cmd_status/$pkg_status/$mode" in
            INSTALLED/*/*) log "[OK] $cmd | package=$pkg | $purpose" ;;
            MISSING/INSTALLED/*) log "[WARN] $cmd missing but package $pkg is marked installed"; MISSING_PKGS="$MISSING_PKGS $pkg" ;;
            MISSING/AVAILABLE/REQUIRED) log "[INSTALL] $cmd -> $pkg | $purpose"; MISSING_PKGS="$MISSING_PKGS $pkg" ;;
            MISSING/AVAILABLE/OPTIONAL) log "[INSTALL-OPTIONAL] $cmd -> $pkg | $purpose"; MISSING_PKGS="$MISSING_PKGS $pkg" ;;
            MISSING/UNAVAILABLE/REQUIRED) log "[UNRESOLVED-REQUIRED] $cmd -> $pkg unavailable in $PKG_MANAGER feeds | $purpose"; UNRESOLVED="$UNRESOLVED $cmd|$pkg|REQUIRED" ;;
            MISSING/UNAVAILABLE/OPTIONAL) log "[UNRESOLVED-OPTIONAL] $cmd -> $pkg unavailable in $PKG_MANAGER feeds | $purpose"; OPTIONAL_MISSING="$OPTIONAL_MISSING $cmd|$pkg" ;;
        esac
    done < "$REQ_FILE"

    unique=""
    for p in $MISSING_PKGS; do
        [ -n "$p" ] || continue
        case " $unique " in *" $p "*) : ;; *) unique="$unique $p";; esac
    done

    if [ -n "$(printf '%s' "$unique" | tr -d ' ')" ]; then
        if [ -n "$ROOT" ]; then
            log "[TEST ROOT] would install:$unique"
        else
            log "Installing missing requirement packages:$unique"
            # shellcheck disable=SC2086
            if ! pkg_install $unique; then
                packages_snapshot "$REQ_AFTER"
                log "ERROR: package installation failed. Snapshot after failure: $REQ_AFTER"
                [ "$REQUIREMENTS_STRICT" = 1 ] && exit 5
            fi
        fi
    else
        log "No requirement packages need installation."
    fi

    packages_snapshot "$REQ_AFTER"
    log "Installed package snapshot after: $REQ_AFTER"
    {
        echo "snapshot_after=$REQ_AFTER"
        echo "unresolved_required=$UNRESOLVED"
        echo "unresolved_optional=$OPTIONAL_MISSING"
    } >> "$REQ_STATUS"
    printf '%s\n' "$UNRESOLVED" | tr ' ' '\n' | sed '/^$/d' > "$REQ_UNRESOLVED"

    failed=""
    while IFS='|' read -r cmd apk_pkg opkg_pkg apt_pkg dnf_pkg pacman_pkg zypper_pkg alpine_pkg mode purpose; do
        case "$cmd" in ''|\#*) continue;; esac
        if ! command -v "$cmd" >/dev/null 2>&1 && [ "$mode" = REQUIRED ]; then
            failed="$failed $cmd"
        fi
    done < "$REQ_FILE"

    if [ -n "$(printf '%s' "$failed" | tr -d ' ')" ]; then
        log "[UNRESOLVED REQUIRED COMMANDS]$failed"
        if [ "$REQUIREMENTS_STRICT" = 1 ]; then
            log "ERROR: strict requirements mode is enabled; installation aborted."
            exit 6
        else
            log "WARNING: required requirements remain unresolved; installation continues."
        fi
    fi

    optional_failed=""
    while IFS='|' read -r cmd apk_pkg opkg_pkg apt_pkg dnf_pkg pacman_pkg zypper_pkg alpine_pkg mode purpose; do
        case "$cmd" in ''|\#*) continue;; esac
        if ! command -v "$cmd" >/dev/null 2>&1 && [ "$mode" = OPTIONAL ]; then
            optional_failed="$optional_failed $cmd"
        fi
    done < "$REQ_FILE"
    [ -z "$(printf '%s' "$optional_failed" | tr -d ' ')" ] || log "[INFO] Optional requirements still unavailable:$optional_failed"
}

requirements_prepare

mkdir -p "$ROOT/usr/bin" "$ROOT/usr/lib" "$LIB" "$LIB/upstream" "$ETC" "$ETC/profiles" "$ETC/strategies/custom" "$ETC/bundled" "$ETC/compat"
cp "$SRC/zapret-test" "$BIN"
chmod 0755 "$BIN"

install_new() {
    src="$1"; dst="$2"
    [ -e "$dst" ] || cp "$src" "$dst"
}

cp "$SRC/services.conf" "$ETC/services.conf"
cp "$SRC/domain-sources.conf" "$ETC/domain-sources.conf"
cp "$SRC/requirements.conf" "$ETC/requirements.conf"
cp "$SRC/availability.conf" "$ETC/availability.conf"
for f in "$SRC/profiles"/*.profile; do
    [ -f "$f" ] || continue
    install_new "$f" "$ETC/profiles/$(basename "$f")"
done
for f in "$SRC/strategies/custom"/*; do
    [ -f "$f" ] || continue
    install_new "$f" "$ETC/strategies/custom/$(basename "$f")"
done
[ -f "$SRC/external-tests.conf" ] && cp "$SRC/external-tests.conf" "$ETC/external-tests.conf"
for f in "$SRC/compat"/*; do
    [ -f "$f" ] || continue
    cp -p "$f" "$ETC/compat/$(basename "$f")"
    chmod 0755 "$ETC/compat/$(basename "$f")" 2>/dev/null || true
done

# Store the harness launchers for diagnostics. They intentionally do not pretend to be full upstream trees.
cp -p "$SRC/upstream/blockcheck.sh" "$LIB/upstream/blockcheck.sh.wrapper"
cp -p "$SRC/upstream/blockcheck2.sh" "$LIB/upstream/blockcheck2.sh.wrapper"
chmod 0755 "$LIB/upstream/blockcheck"*.wrapper 2>/dev/null || true
# When a real upstream tree already exists, cache the exact installed blockcheck scripts for audit/reproducibility.
for pair in "/opt/zapret/blockcheck.sh|$LIB/upstream/blockcheck.sh.installed" "/opt/zapret2/blockcheck2.sh|$LIB/upstream/blockcheck2.sh.installed"; do
    srcf="${pair%%|*}"; dstf="${pair#*|}"
    [ -f "$srcf" ] && cp -p "$srcf" "$dstf" || true
done
cat > "$LIB/upstream/README.txt" <<'EOF2'
The *.wrapper files are launchers, not standalone upstream trees.
At runtime zapret-test uses the real blockcheck.sh/blockcheck2.sh from the installed zapret/zapret2 tree.
If such a tree exists at install time, its blockcheck script is cached as *.installed for audit purposes.
A standalone blockcheck script cannot be made functional without its corresponding upstream tree and dependencies.
EOF2

printf '%s\n' "$VERSION" > "$LIB/VERSION"

echo "Installed $NAME $VERSION"
echo "Binary : $BIN"
echo "Config : $ETC"
echo "Run    : $NAME"
printf '\n'
printf '%s\n' '============================================================'
printf '%s\n' "                     ZAPRET-TEST $VERSION"
printf '%s\n' '============================================================'
printf '\n'
printf '%s' 'Введите для начала работы с программой zapret-test '
read _
printf '\n'
