NAME ?= zapret-test
VERSION ?= 0.6.7.1
DIST := $(NAME)-$(VERSION).zip
PREFIX_ROOT ?=
PREFIX_RUN ?=

.PHONY: all check shellcheck package clean install test

all: check package

check:
	sh -n zapret-test
	command -v busybox >/dev/null 2>&1 && busybox ash -n zapret-test 2>/dev/null || true
	sh -n install.sh
	command -v busybox >/dev/null 2>&1 && busybox ash -n install.sh 2>/dev/null || true
	sh -n build.sh
	@test -x build.sh
	@grep -q '^VERSION="$(VERSION)"' zapret-test
	@test "$$(cat VERSION)" = "$(VERSION)"
	@test "$$(cat RELEASE)" = "$(VERSION)"
	@echo "Build checks: OK"

package: check
	./build.sh

install: check
	PREFIX_ROOT="$(PREFIX_ROOT)" PREFIX_RUN="$(PREFIX_RUN)" ./install.sh

test: check
	@echo "Static build checks passed. Runtime integration tests require OpenWrt/Linux test environments."

clean:
	rm -rf build "$(DIST)"
