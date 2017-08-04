#!/bin/bash

ROOT_DIR=$PWD
TEMP_DIR=$PWD/tmp
VERSION="0.5.2"

mkdir -p $TEMP_DIR && cd $TEMP_DIR

# Install NW.js
if [[ ! -f $ROOT_DIR/src/nw/nw ]]; then
  wget http://dl.nwjs.io/v0.22.3/nwjs-sdk-v0.22.3-linux-x64.tar.gz
  tar xvzf nwjs-sdk-v0.22.3-linux-x64.tar.gz
  mv nwjs-sdk-v0.22.3-linux-x64/* "$ROOT_DIR/src/nw"
  rm nwjs-sdk-v0.22.3-linux-x64.tar.gz
  rmdir nwjs-sdk-v0.22.3-linux-x64
  rmdir nw
fi

cd $TEMP_DIR

# Install Gchange web
if [[ ! -f $ROOT_DIR/src/nw/gchange/index.html ]]; then
    mkdir gchange_unzip && cd gchange_unzip
    wget https://github.com/duniter-gchange/gchange-client/releases/download/v$VERSION/gchange-v$VERSION-web.zip
    unzip gchange-*.zip
    rm gchange-*.zip
    sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "index.html"
    sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "debug.html"
    mv * "$ROOT_DIR/src/nw/gchange/"
    cd ..
    rmdir gchange_unzip
fi

cd $ROOT_DIR
rmdir $TEMP_DIR

./src/nw/nw
