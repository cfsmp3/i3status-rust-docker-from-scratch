#!/usr/bin/env bash

env

dquilt () {
    /usr/bin/quilt --quiltrc=/tmp/quiltrc-dpkg $@
}


cd /packaging
base="i3status-rust-${PACKAGE_VERSION}"
release="https://github.com/greshake/i3status-rust/archive/refs/tags/v${PACKAGE_VERSION}.tar.gz"
wget -q -O "${base}.tar.gz" $release || { echo  "wget failed (${release})." ; exit 1 ; }

tar -xvzf ${base}.tar.gz
mv ${base} regolith-${base}
mv ${base}.tar.gz regolith-${base}.tar.gz

cd regolith-${base}
dh_make -y -s -f ../regolith-${base}.tar.gz
ls -F ..
mkdir debian/patches


cat <<EOT > /tmp/quiltrc-dpkg
d=. ; while [ ! -d \$d/debian -a \$(readlink -e \$d) != / ]; do d=$d/..; done
if [ -d \$d/debian ] && [ -z \$QUILT_PATCHES ]; then
    # if in Debian packaging tree with unset \$QUILT_PATCHES
    QUILT_PATCHES="debian/patches"
    QUILT_PATCH_OPTS="--reject-format=unified"
    QUILT_DIFF_ARGS="-p ab --no-timestamps --no-index --color=auto"
    QUILT_REFRESH_ARGS="-p ab --no-timestamps --no-index"
    QUILT_COLORS="diff_hdr=1;32:diff_add=1;34:diff_rem=1;31:diff_hunk=1;33:diff_ctx=35:diff_cctx=33"
    if ! [ -d \$d/debian/patches ]; then mkdir \$d/debian/patches; fi
fi
EOT
echo "Created this:"
cat /tmp/quiltrc-dpkg

dquilt new create-makefile
dquilt add Makefile

TAB="$(printf '\t')"

cat <<EOT > Makefile
BIN 	= \$(DESTDIR)/usr/bin

build:
${TAB}echo "Building..."
${TAB}cargo build --release

install:
${TAB}install -d \$(BIN)
${TAB}install target/release/i3status-rs \$(BIN)

all: build install

help:
${TAB}@echo "usage: make"
EOT

echo "Makefile created, look"
cat Makefile

dquilt refresh

cat <<EOT > debian/control
Source: regolith-i3status-rust
Section: utils
Priority: optional
Maintainer: ${DEBFULLNAME} <${DEBEMAIL}>
Build-Depends: debhelper-compat (= 12), rustc, libdbus-1-dev, libpulse-dev
Standards-Version: 4.6.0
Homepage: https://github.com/greshake/i3status-rust
#Vcs-Browser: https://salsa.debian.org/debian/regolith-i3status-rust
#Vcs-Git: https://salsa.debian.org/debian/regolith-i3status-rust.git
Rules-Requires-Root: no

Package: regolith-i3status-rust
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends}
Description: feature-rich and resource-friendly replacement for i3status.
 i3status-rs is a feature-rich and resource-friendly replacement for i3status,
 written in pure Rust. It provides a way to display "blocks" of system information
 (time, battery status, volume, etc) on the i3 bar. It is also compatible with sway.
EOT

cat <<EOT > debian/copyright
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: regolith-i3status-rust
Upstream-Contact: https://github.com/greshake/i3status-rust/issues
Source: https://github.com/greshake/i3status-rust

Files: *
Copyright: 2019-2021 The i3status-team, check github

License: GPL-3

Files: debian/*
Copyright: 2021 ${DEBFULLNAME} <${DEBEMAIL}>
License: GPL-3
EOT

sed -i "s/.*Initial.*/  * Created package with script/g" debian/changelog

mkdir -p debian/source
cat <<EOT > debian/source/options
extend-diff-ignore = "(^|/)(target).*$"
EOT

dquilt add vendor/*
mkdir /tmp/cargohome
CARGO_HOME=/tmp/cargohome cargo vendor --no-delete
dquilt add .cargo/config.toml
mkdir .cargo
dquilt refresh

cat <<EOT > .cargo/config.toml
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"
EOT
cargo build

EDITOR=/bin/true dpkg-source -q --commit . autopackage-patches

dpkg-buildpackage -us -uc

