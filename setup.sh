#!/bin/bash

set -eax -o pipefail

if [ -z "${CROSS_FILE}" ]; then
    if [ -z "${NEED_WINE}" ]; then
        export CROSS_FILE=/usr/share/mingw/toolchain-mingw64.meson
    else
        export CROSS_FILE=/usr/share/mingw/toolchain-mingw64-wine.meson
        export MESON_EXE_WRAPPER=/usr/bin/x86_64-w64-mingw64-wine
    fi
fi

if [ ! -e ./.venv/Scripts/activate ]; then
    rye sync
fi

# shellcheck disable=SC1091
. ./.venv/Scripts/activate

pacman -Syu --noconfirm
pacman -S --needed --noconfirm \
    "filesystem" \
    "${MINGW_PACKAGE_PREFIX}-gstreamer" \
    "${MINGW_PACKAGE_PREFIX}-pango" \
    "${MINGW_PACKAGE_PREFIX}-gcc" \
    "${MINGW_PACKAGE_PREFIX}-binutils" \
    "${MINGW_PACKAGE_PREFIX}-cairo" \
    "${MINGW_PACKAGE_PREFIX}-gdk-pixbuf2" \
    "${MINGW_PACKAGE_PREFIX}-glib2" \
    "${MINGW_PACKAGE_PREFIX}-libepoxy" \
    "${MINGW_PACKAGE_PREFIX}-pango" \
    "${MINGW_PACKAGE_PREFIX}-cairo"

args=(
    # --prefix /usr/x86_64-w64-mingw32/sys-root/mingw
    # --libdir /usr/x86_64-w64-mingw32/sys-root/mingw/lib
    # --libexecdir /usr/x86_64-w64-mingw32/sys-root/mingw/lib
    # --bindir /usr/x86_64-w64-mingw32/sys-root/mingw/bin
    # --sbindir /usr/x86_64-w64-mingw32/sys-root/mingw/bin
    # --includedir /usr/x86_64-w64-mingw32/sys-root/mingw/include
    # --datadir /usr/x86_64-w64-mingw32/sys-root/mingw/share
    # --mandir /usr/x86_64-w64-mingw32/sys-root/mingw/share/man
    # --infodir /usr/x86_64-w64-mingw32/sys-root/mingw/share/info
    # --localedir /usr/x86_64-w64-mingw32/sys-root/mingw/share/locale
    # --sysconfdir /usr/x86_64-w64-mingw32/sys-root/mingw/etc
    # --localstatedir /var
    # --sharedstatedir /var/lib
    --buildtype release
    --wrap-mode nofallback
    -D b_lto=true
    -D strip=true
    --default-library shared
    "$@"
)

if [ -e "${CROSS_FILE}" ]; then
    args+=(--cross-file "${CROSS_FILE}")
fi

# shellcheck disable=SC1091
. .gitlab-ci/show-info-linux.sh

export PATH="$HOME/.local/bin:$PATH"
# pip3 install --user meson~=1.0
meson subprojects download
meson subprojects update --reset
meson \
    -Dgobject-introspection:werror=false \
    -Dgraphene:introspection=disabled \
    -Dintrospection=disabled \
    -Dmedia-gstreamer=disabled \
    -Dvulkan=disabled \
    _build
meson compile -C _build

# exec meson "${args[@]}" .build .
