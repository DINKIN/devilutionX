#!/usr/bin/env bash

set -euo pipefail

DEVKITPRO="${DEVKITPRO:-/opt/devkitpro}"

declare -r DIR="$(dirname "${BASH_SOURCE[0]}")"
cd "$DIR"

main() {
	prepare_devkitpro
	set -x
	install_deps
	build
}

build() {
	mkdir -p ../../build
	cd ../../build
	rm -f CMakeCache.txt
	DEVKITPRO="$DEVKITPRO" cmake .. \
		-DJOY_BUTTON_DPAD_LEFT=16 \
		-DJOY_BUTTON_DPAD_UP=17 \
		-DJOY_BUTTON_DPAD_RIGHT=18 \
		-DJOY_BUTTON_DPAD_DOWN=19 \
		-DBINARY_RELEASE=ON \
		-DNONET=ON \
		-DPREFILL_PLAYER_NAME=ON \
		-DCMAKE_TOOLCHAIN_FILE=../CMake/switch/devkita64-libnx.cmake
	DEVKITPRO="$DEVKITPRO" make -j "$(getconf _NPROCESSORS_ONLN)"
	cd -
}

package() {
	./package.sh ../../build/devilutionx-opendingux-musl-sdl1.ipk
}

install_deps() {
	"$DEVKITPRO/pacman/bin/pacman" -S --needed --noconfirm --quiet \
		switch-freetype switch-mesa switch-glad switch-glm switch-sdl2 \
		switch-sdl2_ttf switch-sdl2_mixer switch-libvorbis switch-libmikmod switch-libsodium  \
		libnx devkitA64 devkitA64 general-tools switch-tools devkitpro-pkgbuild-helpers
}

prepare_devkitpro() {
	if [[ -d $DEVKITPRO ]]; then
		return;
	fi
	if which dpkg > /dev/null; then
		install_devkitpro_debian
	else
		>&2 printf "Please set DEVKITPRO:\nhttps://devkitpro.org/wiki/Getting_Started\n"
		exit 1
	fi
}

install_devkitpro_debian() {
	>&2 echo 'Installing devkitpro-pacman.deb from GitHub...'
	local -r dpkg_path=/tmp/devkitpro-pacman.deb
	set -x
	\curl -L https://github.com/devkitPro/pacman/releases/download/devkitpro-pacman-1.0.1/devkitpro-pacman.deb -o "$dpkg_path"
	sudo dpkg -i "$dpkg_path"
	rm "$dpkg_path"
	{ set +x; } 2>/dev/null
}

main