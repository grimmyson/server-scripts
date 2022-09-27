#!/bin/bash

COMMAND=$1
APP=$2

info() {
  echo "Syntax:"
  echo ""
  echo "./installer.sh install|update micro|centrifugo"
  echo ""
  exit 1
}

install_micro() {
  wget https://github.com/zyedidia/micro/releases/download/v2.0.11/micro-2.0.11-linux64.tar.gz
  tar zxvf micro-2.0.11-linux64.tar.gz
  sudo chown root:root micro-2.0.11/micro
  sudo mv micro-2.0.11/micro /usr/bin
  rm -rf micro-2.0.11 micro-2.0.11-linux64.tar.gz
}

install_centrifugo() {
  wget https://github.com/centrifugal/centrifugo/releases/download/v4.0.1/centrifugo_4.0.1_linux_amd64.tar.gz
  tar zxvf centrifugo_4.0.1_linux_amd64.tar.gz
  sudo chown root:root centrifugo
  sudo mv centrifugo /usr/bin
  rm -rf centrifugo_4.0.1_linux_amd64.tar.gz CHANGELOG.md LICENSE README.md
}

if [[ "$COMMAND" == "install" ]]; then
  if [[ "$APP" == "micro" ]]; then
    install_micro
  elif [[ "$APP" == "centrifugo" ]]; then
    which micro 1> /dev/null 2> /dev/null
    if [[ $? -ne 0 ]]; then
      echo "First install micro text editor, use:"
      echo ""
      echo "./installer.sh install micro"
      echo ""
      exit 1
    fi

    install_centrifugo
    sudo mkdir /etc/centrifugo && sudo micro /etc/centrifugo/config.json

    wget https://github.com/centrifugal/centrifugo/raw/master/misc/packaging/initd.sh
    sed -i 's/USER=centrifugo/USER=root/g' initd.sh
    sed -i 's/GROUP=centrifugo/GROUP=root/g' initd.sh
    sudo chown root:root initd.sh
    sudo chmod 755 initd.sh
    sudo mv initd.sh /etc/init.d/centrifugo
    sudo update-rc.d centrifugo defaults
    sudo service centrifugo start
    sudo service centrifugo status
  else
    info
  fi
elif [[ "$COMMAND" == "update" ]]; then
  if [[ "$APP" == "micro" ]]; then
    install_micro
  elif [[ "$APP" == "centrifugo" ]]; then
    sudo service centrifugo stop
    install_centrifugo
    sudo service centrifugo start
    sudo service centrifugo status
  else
    info
  fi
else
  info
fi
