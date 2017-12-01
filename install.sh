#!/bin/bash

ROOT_DIR=$PWD
TEMP_DIR=$PWD/tmp

NW_VERSION=0.22.3
#NW_VERSION=0.26.6

# Check first arguments = version
if [[ $1 =~ ^[0-9]+.[0-9]+.[0-9]+((a|b)[0-9]+)?$ ]];
then
  VERSION="$1"
  echo "Using given version: $VERSION"
else
  if [[ -f $ROOT_DIR/src/nw/cesium/manifest.json ]];
  then
    VERSION=`grep -oP "version\": \"\d+.\d+.\d+((a|b)[0-9]+)?\"" $ROOT_DIR/src/nw/cesium/manifest.json | grep -oP "\d+.\d+.\d+((a|b)[0-9]+)?"`
  fi

  if [[ $VERSION =~ ^[0-9]+.[0-9]+.[0-9]+((a|b)[0-9]+)?$ ]];
  then
    echo "Using detected version: $VERSION"
  else
    VERSION="0.6.1";
    echo "No version detected. Using default: $VERSION"
  fi
fi

mkdir -p $TEMP_DIR && cd $TEMP_DIR

# Install NW.js
if [[ ! -f $ROOT_DIR/src/nw/nw ]];
then
  wget http://dl.nwjs.io/v$NW_VERSION/nwjs-sdk-v$NW_VERSION-linux-x64.tar.gz
  tar xvzf nwjs-sdk-v$NW_VERSION-linux-x64.tar.gz
  mv nwjs-sdk-v$NW_VERSION-linux-x64/* "$ROOT_DIR/src/nw"
  rm nwjs-sdk-v$NW_VERSION-linux-x64.tar.gz
  rmdir nwjs-sdk-v$NW_VERSION-linux-x64
  rmdir nw
fi

# Remove old Cesium version
if [[ -f $ROOT_DIR/src/nw/cesium/index.html ]];
then
  OLD_VERSION=`grep -oP "version\": \"\d+.\d+.\d+((a|b)[0-9]+)?\"" $ROOT_DIR/src/nw/gchange/manifest.json | grep -oP "\d+.\d+.\d+((a|b)[0-9]+)?"`
  if [[ ! "$VERSION" = "$OLD_VERSION" ]];
  then
    rm -rf $ROOT_DIR/src/nw/gchange/dist_*
    rm -rf $ROOT_DIR/src/nw/gchange/fonts
    rm -rf $ROOT_DIR/src/nw/gchange/img
    rm -rf $ROOT_DIR/src/nw/gchange/lib
    rm -rf $ROOT_DIR/src/nw/gchange/*.html
  fi
fi

# Install Gchange web
if [[ ! -f $ROOT_DIR/src/nw/cesium/index.html ]]; then
    echo "Downloading Gchange ${VERSION}..."

    mkdir gchange_unzip && cd gchange_unzip
    wget "https://github.com/duniter-gchange/gchange-client/releases/download/v${VERSION}/gchange-v${VERSION}-web.zip"
    unzip "gchange-v${VERSION}-web.zip"
    rm "gchange-v${VERSION}-web.zip"
    sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "index.html"
    sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "debug.html"
    mv * "$ROOT_DIR/src/nw/gchange/"
    cd ..
    rmdir gchange_unzip
fi

cd $ROOT_DIR
rmdir $TEMP_DIR

