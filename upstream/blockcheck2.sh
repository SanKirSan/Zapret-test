#!/bin/sh
# zapret-test launcher/reference. Runtime uses the real installed upstream script.
for p in /opt/zapret2/blockcheck2.sh /usr/share/zapret2/blockcheck2.sh /usr/lib/zapret2/blockcheck2.sh /usr/bin/blockcheck2.sh /usr/sbin/blockcheck2.sh; do
    [ -x "$p" ] && exec "$p" "$@"
done
echo "ERROR: installed zapret2 blockcheck2.sh was not found." >&2
exit 127
