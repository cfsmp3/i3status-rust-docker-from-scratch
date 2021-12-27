#!/usr/bin/env bash

PACKAGE_VERSION="0.20.7"


mkdir -p packaging
rm -rf packaging/*

if [[ "$DEBEMAIL" == "" ]] || [[ "$DEBFULLNAME" = "" ]] ; then
    echo "Missing Debian environment variables (DEBEMAIL=\"$DEBEMAIL\",  DEBFULLNAME=\"$DEBFULLNAME\")"
    exit 1
fi

docker build -t regolith/i3status-rust-packager:latest .
docker run --user $(id -u):$(id -g)\
    -v $(pwd)/packaging:/packaging\
    -e DEBEMAIL="${DEBEMAIL}" -e DEBFULLNAME="${DEBFULLNAME}"\
    -e PACKAGE_VERSION="${PACKAGE_VERSION}"\
    -t regolith/i3status-rust-packager

echo "Remember to sign (run debsign from inside the source directory)"


