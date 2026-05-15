#!/bin/sh

set -u

DEPS_PATH="$GITHUB_WORKSPACE/$1"
DEPS_PATH="${DEPS_PATH%/}"

REPO_PATH="${HOME}/work/${2:-dependencies}"

mkdir -p "$REPO_PATH"
cd "$REPO_PATH" || exit

find "$DEPS_PATH" -maxdepth 1 -name '*.pkg.tar*' -not -name '*.pkg.*.sig' \
	-exec sh -c 'for PKG in "$@"; do repo-add dependencies.db.tar "$PKG"; done' - {} +

if [ ! -e depedencies.db.tar ]; then
	echo "no dependency packages found, skipping"
	exit 0
fi

tee -a /etc/pacman.conf <<- EOF

	[dependencies]
	Server = file://$(pwd)
	SigLevel = Optional TrustAll
EOF

sudo pacman -Sy
