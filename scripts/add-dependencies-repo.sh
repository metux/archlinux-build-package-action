#!/bin/sh

set -u

DEPS_PATH="$GITHUB_WORKSPACE/$1"
DEPS_PATH="${DEPS_PATH%/}"

REPO_PATH="${HOME}/work/${2:-dependencies}"

DEP_FILES="$(find "$DEPS_PATH" -maxdepth 1 -name '*.pkg.*' -print -quit 2>/dev/null)"
if [ ! "$DEP_FILES" ]; then
	echo "no dependency packages found, skipping"
	exit 0
fi

mkdir -p "$REPO_PATH"
cd "$REPO_PATH" || exit

repo-add dependencies.db.tar "$DEPS_PATH"/*.pkg.*
tee -a /etc/pacman.conf <<- EOF

	[dependencies]
	Server = file://$(pwd)
	SigLevel = Optional TrustAll
EOF

sudo pacman -Sy
