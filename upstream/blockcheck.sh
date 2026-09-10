#!/bin/sh
# zapret-test launcher/reference. Runtime uses the real installed upstream script.
for p in /opt/zapret/blockcheck.sh /usr/share/zapret/blockcheck.sh /usr/lib/zapret/blockcheck.sh /usr/bin/blockcheck.sh /usr/sbin/blockcheck.sh; do
    [ -x "$p" ] && exec "$p" "$@"
done
echo "ERROR: installed zapret blockcheck.sh was not found." >&2
exit 127
