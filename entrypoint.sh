#!/bin/bash

set -e -u


# Constants

HOME=/home/builder

CARCH=$(uname -m) # TODO make configurable
SRCDIR="$GITHUB_WORKSPACE/$INPUT_PATH"
SRCDIR="${SRCDIR%/}"

BUILDDIR="$HOME"/work
SCRIPTS_PATH="$HOME/bin"


# Set up environment

# shellcheck source=./scripts/gh-helpers.sh
. "$SCRIPTS_PATH"/gh-helpers.sh

mkdir -p "$BUILDDIR"

echo "HERE"

sudo chmod -R 0777 /etc/pacman.conf #"$GITHUB_ENV" "$GITHUB_WORKSPACE"

echo "AFTER sudo

# The default alpm user can't read our custom file-based databases...
sed -i 's/DownloadUser = alpm/DownloadUser = builder/g' /etc/pacman.conf

cat <<-EOMPC > ~/.makepkg.conf
	NPROC="$(nproc)"
	MAKEFLAGS="-j$(nproc)"
EOMPC

# Install optional helpers

if [ "$INPUT_AUR" = 'true' ]; then
	glgrp "Installing yay"
	cd "$HOME"
	git clone --depth 1 https://aur.archlinux.org/yay-bin.git
	cd yay-bin && makepkg -si --noconfirm
	cd "$SRCDIR"
fi

if [ "$INPUT_NAMCAP" = 'true' ]; then
	glgrp "Installing namcap"
	sudo pacman -Syu --needed --noconfirm namcap
fi

if [ "$INPUT_SIGNING_KEY" ] ; then
	glgrp "Installing gnupg"
	sudo pacman -Syu --needed --noconfirm gnupg
fi

if [ "$INPUT_PGPKEYS" ]; then
	glgrp "Receiving PGP keys"
	for key in ${INPUT_PGPKEYS//,/$'\n'}; do
		gpg --keyserver "$INPUT_PGPKEYSERVER" --recv-keys "$key"
	done
fi

if [ "$INPUT_UPDATE_ARCHLINUX_KEYRING" = 'true' ]; then
	glgrp "Updating the archlinux-keyring"
	sudo pacman-key --init
	sudo pacman -Syu --noconfirm archlinux-keyring
fi

if [ "$INPUT_CUSTOM_REPO_NAME" ]; then
	glgrp "Adding custom package repository $INPUT_CUSTOM_REPO_NAME"
	"$SCRIPTS_PATH"/add-custom-repo.sh \
		"$INPUT_CUSTOM_REPO_NAME" "$CARCH" "$INPUT_CUSTOM_REPO_URL" \
		"$INPUT_CUSTOM_REPO_SIGLEVEL"
fi

if [ "$INPUT_DEPENDENCIES_PATH" ]; then
	glgrp "Adding dependencies repository"
	"$SCRIPTS_PATH"/add-dependencies-repo.sh "$INPUT_DEPENDENCIES_PATH"
fi

if [ "$INPUT_PKGVER" ]; then
	glgrp 'Updating pkgver of PKGBUILD'
	sed -i "s:^pkgver=.*$:pkgver=$INPUT_PKGVER:g" PKGBUILD
	git --no-pager diff PKGBUILD
fi

if [ "$INPUT_PKGREL" ]; then
	glgrp 'Updating pkgrel of PKGBUILD'
	sed -i "s:^pkgrel=.*$:pkgrel=$INPUT_PKGREL:g" PKGBUILD
	git --no-pager diff PKGBUILD
fi

if [ "$INPUT_UPDPKGSUMS" = 'true' ]; then
	glgrp 'Updating checksums on PKGBUILD'
	updpkgsums
	git --no-pager diff PKGBUILD
fi

if [ "$INPUT_SRCINFO" = 'true' ]; then
	glgrp 'Generating new .SRCINFO based on PKGBUILD'
	makepkg --printsrcinfo > .SRCINFO
	git --no-pager diff .SRCINFO
fi

if [ "$INPUT_NAMCAP" = 'true' ]; then
	glgrp 'Validating PKGBUILD with namcap'
	# shellcheck disable=2086
	namcap $INPUT_NAMCAP_OPTS PKGBUILD
fi

if [ "$INPUT_AUR" = 'true' ]; then
	glgrp "Installing depends using yay"
	# shellcheck disable=1091
	source PKGBUILD
	"$HOME"/yay-bin/yay -Syu --removemake --needed --noconfirm \
		"${depends[@]}" "${makedepends[@]}"
fi

cd "$BUILDDIR"

if [ "$INPUT_MAKEPKG_OPTS" ]; then
	glgrp "Running makepkg with options"
	cp "$SRCDIR"/PKGBUILD ./
	# shellcheck disable=2086
	makepkg $INPUT_MAKEPKG_OPTS
fi

if [ "$INPUT_SIGNING_KEY" ] && [ "$INPUT_MAKEPKG_OPTS" ]; then
	glgrp "Signing packages"
	"$SCRIPTS_PATH"/sign-packages.sh . "$INPUT_SIGNING_KEY" \
		"$INPUT_SIGNING_KEY_PASSWORD"
fi

cd "$SRCDIR"

# shellcheck disable=1091
source PKGBUILD
gh_env_set PKGVER "$pkgver"
gh_env_set PKGREL "$pkgrel"

glgrp "Copying packages from $BUILDDIR to $SRCDIR"
cp -fv "$BUILDDIR"/*.pkg.* "$SRCDIR"/

#if [ "$INPUT_REPO_ADD_PATH" ]; then
#	glgrp "Adding package to repo"
#	REPOPATH="$GITHUB_WORKSPACE/$INPUT_REPO_ADD_PATH"
#	repo-add "$REPOPATH" ./*.pkg.*
#fi

glgrpend
