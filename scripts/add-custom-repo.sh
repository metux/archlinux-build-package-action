#!/bin/sh

set -e -u

# Arguments

REPO_NAME="$1"
REPO_ARCH="$2"
REPO_URL="$3"
REPO_SIGLEVEL="$4"


# Main

set +e
DB_URL="${REPO_URL}/${REPO_ARCH}/${REPO_NAME}.db"
curl --silent --head "$DB_URL"
if [ $? -ne 0 ] ; then
	echo "package database of custom repo not found, skipping"
	exit 0
fi
set -e

tee -a /etc/pacman.conf <<- EOF

	[$REPO_NAME]
	Server = $REPO_URL/\$arch
	SigLevel = $REPO_SIGLEVEL
EOF

sudo pacman -Sy
