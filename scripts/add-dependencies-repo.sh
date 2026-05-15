#!/bin/sh

set -e -u

DEPS_PATH="$GITHUB_WORKSPACE/$1"
DEPS_PATH="${DEPS_PATH%/}"

REPO_PATH="${HOME}/work/${2:-dependencies}"

mkdir -p "$REPO_PATH"
cd "$REPO_PATH" || exit

find "$DEPS_PATH" ! -name '*.pkg.tar*.sig' -prune -name '*.pkg.tar*' \
	-exec sh -c "cp \"$@\" $REPO_PATH" sh {} +
if [ $? -ne 0 ] ; then
	echo "no dependency packages found, skipping"
	exit 0
fi

repo-add dependencies.db.tar *.pkg.*

tee -a /etc/pacman.conf <<- EOF

	[dependencies]
	Server = file://$(pwd)
	SigLevel = Optional TrustAll
EOF

sudo pacman -Sy
