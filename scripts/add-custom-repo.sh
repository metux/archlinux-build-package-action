#!/bin/sh

set -u

# Arguments

REPO_NAME="$1"
REPO_ARCH="$2"
REPO_URL="$3"
REPO_SIGLEVEL="$4"


# Functions

url_exists() {
	curl -I "$1" 1>/dev/null 2>&1
	return $?
}


# Main

if [ url_exists "$REPO_URL/$REPO_ARCH/$REPO_NAME.db" -ne 0 ] ; then
	echo "package database of custom repo not found, skipping"
	exit 0
fi

tee -a /etc/pacman.conf <<- EOF

	[$REPO_NAME]
	Server = $REPO_URL/\$arch
	SigLevel = $REPO_SIGLEVEL
EOF

sudo pacman -Sy
