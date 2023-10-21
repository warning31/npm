#!/usr/bin/env sh

main() {

    START_PATH=${PWD}
    touch ${START_PATH}/npm.log
    OUTPUTLOG=${START_PATH}/npm.log

    printf "\033c"

    echo  "NPM Kurulumuna Hosgeldiniz"
    echo

    sleep 5

    echo
    echo "Kurulumu Basliyor"
    echo

    exec 3>&1 1>>${OUTPUTLOG} 2>&1

    _paketlerikaldir

    _klasorolustur

    _repoekleniyor

    _dockerkuruluyor

    _docketcomposekur

    _dockercomposeymlolustur

    _npminstall

}

_paketlerikaldir() {
    echo  "Paketler Kaldiriliyor" 1>&3
    apt-get  -y remove docker docker-engine docker.io containerd runc
    echo  "Paketler Kaldirildi" 1>&3

}

_klasorolustur() {
    echo  "Klasor Olusturluyor" 1>&3
    mkdir -p /root/npm
    mkdir -p /root/npm/data
    echo "Klasor Olusturuldu" 1>&3
}

_repoekleniyor() {
    echo  "Repo Ekleniyor" 1>&3
    apt-get update
    apt-get install  -y ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    echo "Repo Eklendi" 1>&3

}

_dockerkuruluyor() { 
    echo  "Docker Kuruluyor" 1>&3
      apt-get update
      apt-get -y install docker-ce docker-ce-cli containerd.io
    echo  "Docker Kuruldu" 1>&3
}

_docketcomposekur() {
    echo  "Docker Compose Kuruluyor" 1>&3
   curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   chmod +x /usr/local/bin/docker-compose
   ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    echo "Docker Compose Kuruldu" 1>&3
}

_dockercomposeymlolustur() {
    echo  "Dockercompose yml Olusturluyor" 1>&3
    cat <<EOF >/root/npm/docker-compose.yml
version: '3.8'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      # These ports are in format <host-port>:<container-port>
      - '80:80' # Public HTTP Port
      - '443:443' # Public HTTPS Port
      - '81:81' # Admin Web Port
      # Add any other Stream port you want to expose
      # - '21:21' # FTP
    environment:
      # Mysql/Maria connection parameters:
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "npm"
      DB_MYSQL_PASSWORD: "npm"
      DB_MYSQL_NAME: "npm"
      # Uncomment this if IPv6 is not enabled on your host
      # DISABLE_IPV6: 'true'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    depends_on:
      - db

  db:
    image: 'jc21/mariadb-aria:latest'
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: 'npm'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: 'npm'
      MYSQL_PASSWORD: 'npm'
    volumes:
      - ./mysql:/var/lib/mysql
EOF
    
    echo "Dockercompose yml Olusturuldu" 1>&3
}

_npminstall() {
    echo  "Npm Kuruluyor" 1>&3
    cd /root/npm
    docker-compose up -d
    echo "Npm Kuruldu" 1>&3
}

main