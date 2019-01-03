#!/bin/bash

TAG="$3"

case "$1" in
make)
  case "$2" in
  linux)
    cd arch/linux
    if [[ ! -f "gchange-desktop-v$TAG-linux-x64.deb" ]]; then
      [[ $? -eq 0 ]] && echo ">> Copying Gchange Desktop sources..."
      [[ $? -eq 0 ]] && cp ../../src/nw/yarn.lock ./
      [[ $? -eq 0 ]] && cp ../../src/nw/package.json ./
      [[ $? -eq 0 ]] && cp ../../src/nw/gchange/node.js ./
      [[ $? -eq 0 ]] && echo ">> Starting Vagrant Ubuntu VM..."
      [[ $? -eq 0 ]] && vagrant up
      [[ $? -eq 0 ]] && echo ">> VM: building Gchange..."
      [[ $? -eq 0 ]] && vagrant ssh -- 'bash -s' < ./build-deb.sh
      if [[ ! $? -eq 0 ]]; then
        echo ">> Something went wrong. Stopping build."
      else
        echo ">> Build success. Shutting the VM down."
      fi
      vagrant halt
      echo ">> VM closed."
    else
      echo ">> Debian binaries already built. Ready for upload."
    fi
    ;;
  win)
    cd arch/windows
    if [[ ! -f "gchange-desktop-v$TAG-windows-x64.exe" ]]; then
      [[ $? -eq 0 ]] && echo ">> Copying Gchange Desktop sources..."
      [[ $? -eq 0 ]] && cp ../../src/nw/package.json ./
      [[ $? -eq 0 ]] && cp ../../src/nw/LICENSE.txt ./
      [[ $? -eq 0 ]] && cp ../../src/nw/gchange/node.js ./
      # Win build need a copy iof the web asset, because build.bat has error while download from PowerShell
      [[ $? -eq 0 ]] && cp "../../downloads/gchange-v$TAG-web.zip" ./
      if [[ $? -eq 0 && ! -f ./duniter_win7.box ]]; then
        echo ">> Downloading Windows VM..."
        wget -kL https://s3.eu-central-1.amazonaws.com/duniter/vagrant/duniter_win7.box
      fi
      [[ $? -eq 0 ]] && echo ">> Starting Vagrant Windows VM..."
      [[ $? -eq 0 ]] && vagrant up
      if [[ ! $? -eq 0 ]]; then
        echo ">> Something went wrong. Stopping build."
      fi
      vagrant halt
      echo ">> VM closed."
    else
      echo ">> Windows binary already built. Ready for upload."
    fi
    ;;
  *)
    echo "Unknown binary « $2 »."
    ;;
  esac
    ;;
*)
  echo "Unknown task « $1 »."
  ;;
esac
