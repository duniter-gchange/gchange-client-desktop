#!/bin/bash

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Prepare
NVER=`node -v`
GCHANGE_TAG=
ADDON_VERSION=48
NW_VERSION=0.22.3
NW_RELEASE="v${NW_VERSION}"
NW="nwjs-${NW_RELEASE}-linux-x64"
NW_GZ="${NW}.tar.gz"

# Folders
ROOT=`pwd`
DOWNLOADS="$ROOT/downloads"
RELEASES="$ROOT/releases"

mkdir -p "$DOWNLOADS"

# -----------
# Clean sources + releases
# -----------
rm -rf "$DOWNLOADS/gchange"
rm -rf "$DOWNLOADS/gchange_src"
rm -rf "$RELEASES"
rm -rf /vagrant/*.deb
rm -rf /vagrant/*.tar.gz

mkdir -p $DOWNLOADS/gchange

# -----------
# Downloads
# -----------

cd "$DOWNLOADS"

if [ ! -d "$DOWNLOADS/gchange_src" ]; then
  git clone https://github.com/duniter-gchange/gchange-client.git gchange_src
fi

cd gchange_src
COMMIT=`git rev-list --tags --max-count=1`
GCHANGE_TAG=`echo $(git describe --tags $COMMIT) | sed 's/^v//'`
cd ..

GCHANGE_RELEASE="gchange-v$GCHANGE_TAG-web"
echo "Checking that Gchange binary has been downloaded"
if [ ! -e "$DOWNLOADS/$GCHANGE_RELEASE.zip" ]; then
echo "Have to download it"
    cd gchange
    wget "https://github.com/duniter-gchange/gchange-client/releases/download/v$GCHANGE_TAG/$GCHANGE_RELEASE.zip"
    unzip gchange-*.zip
    rm gchange-*.zip
    cd ..
fi

GCHANGE_DEB_VER=" $GCHANGE_TAG"
GCHANGE_TAG="v$GCHANGE_TAG"

if [ ! -f "$DOWNLOADS/$NW_GZ" ]; then
  wget https://dl.nwjs.io/${NW_RELEASE}/${NW_GZ}
  tar xvzf ${NW_GZ}
fi

# -----------
# Releases
# -----------

rm -rf "$RELEASES"
mkdir -p "$RELEASES"

cp -r "$DOWNLOADS/gchange" "$RELEASES/gchange"
cd "$RELEASES"

# Releases builds
cd ${RELEASES}/gchange
# Remove git files
rm -Rf .git

# -------------------------------------------------
# Build Desktop version (Nw.js is embedded)
# -------------------------------------------------

## Install Nw.js
mkdir -p "$RELEASES/desktop_release"

# -------------------------------------------------
# Build Desktop version .tar.gz
# -------------------------------------------------

cp -r "$DOWNLOADS/${NW}" "$RELEASES/desktop_release/nw"
cp -r "$DOWNLOADS/gchange" "$RELEASES/desktop_release/nw/"

# Specific desktop files
cp -r /vagrant/package.json "$RELEASES/desktop_release/nw/"
cp -r /vagrant/yarn.lock "$RELEASES/desktop_release/nw/"
cp -r /vagrant/node.js "$RELEASES/desktop_release/nw/gchange"
# Injection
sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "$RELEASES/desktop_release/nw/gchange/index.html"
sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "$RELEASES/desktop_release/nw/gchange/debug.html"

# Specific desktop dependencies (for reading Duniter conf, ...)
cd "$RELEASES/desktop_release/nw"
yarn

# Releases
cp -R "$RELEASES/desktop_release" "$RELEASES/desktop_release_tgz"
cd "$RELEASES/desktop_release_tgz"
tar czf /vagrant/gchange-desktop-${GCHANGE_TAG}-linux-x64.tar.gz * --exclude ".git" --exclude "coverage" --exclude "test"

# -------------------------------------------------
# Build Desktop version .deb
# -------------------------------------------------

# Create .deb tree + package it
cp -r "/vagrant/package" "$RELEASES/gchange-x64"
mkdir -p "$RELEASES/gchange-x64/opt/gchange/"
chmod 755 ${RELEASES}/gchange-x64/DEBIAN/post*
chmod 755 ${RELEASES}/gchange-x64/DEBIAN/pre*
sed -i "s/Version:.*/Version:$GCHANGE_DEB_VER/g" ${RELEASES}/gchange-x64/DEBIAN/control
cd ${RELEASES}/desktop_release/nw
zip -qr ${RELEASES}/gchange-x64/opt/gchange/nw.nwb *

sed -i "s/Package: .*/Package: gchange-desktop/g" ${RELEASES}/gchange-x64/DEBIAN/control
cd ${RELEASES}/
fakeroot dpkg-deb --build gchange-x64
mv gchange-x64.deb /vagrant/gchange-desktop-${GCHANGE_TAG}-linux-x64.deb
