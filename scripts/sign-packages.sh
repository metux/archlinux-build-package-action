#!/bin/sh

echo "HERE sign-packages.sh"

set -e -u


# Arguments

# $1: path to packages
# $2: ascii armored key to use
# $3: optional: key password
SIGNING_KEY="$2"
SIGNING_KEY_PASSWORD="$3"


# Constants

GNUPGHOME="${GNUPGHOME:-$(mktemp)}"
SIGNING_KEY_ID=''
TZ='UTC'


# Main

if [ ! "$SIGNING_KEY_ID" ] ; then
	SIGNING_KEY_ID="$( \
		printf '%s\n' "$SIGNING_KEY" \
			| gpg --import-options show-only --with-colon --import \
			| grep '^fpr:' | cut -d ':' -f 10 | head -n 1 \
	)"
fi

printf '%s\n' "$SIGNING_KEY" | gpg --batch --import

ls "$1"/*.pkg.* > packages.csv

while IFS= read -r PKG ; do
	if [ "$SIGNING_KEY_PASSWORD" ]; then
		echo "$SIGNING_KEY_PASSWORD" | gpg --batch --no-tty --passphrase --passphrase-fd 0 \
			--pinentry-mode loopback \
			--default-key "$SIGNING_KEY_ID" --detach-sign \
			--output "$PKG".sig --sign "$PKG"
	else
		gpg --batch --no-tty \
			--default-key "$SIGNING_KEY_ID" --detach-sign \
			--output "$PKG".sig --sign "$PKG"
	fi
done < packages.csv

#EOF
