#!/usr/bin/env sh

main() {

    START_PATH=${PWD}
    touch ${START_PATH}/npm.log
    OUTPUTLOG=${START_PATH}/npm.log


    printf "\033c"


    # Gerekli paketler kuruluyor... 

    _paketlerikaldir


    echo
    echo "Kurulum Basliyor"
    echo

    exec 3>&1 1>>${OUTPUTLOG} 2>&1


    # Klasor Olustur cekiliyor...
    _klasorolustur

    # Klasor Olustur cekiliyor...
    _repoekleniyor

    # Klasor Olustur cekiliyor...
    _dockerkuruluyor

    # Klasor Olustur cekiliyor...
    _docketcomposekur

    # Klasor Olustur cekiliyor...
    _dockercomposeymlolustur


}



_paketlerikaldir() {
    echo -n "Paketler Kaldiriliyor" 1>&3
    sudo apt-get  -y remove docker docker-engine docker.io containerd runc
        echo "Paketler Kaldirildi" 1>&3

}

_klasorolustur() {
    echo -n "Klasor Olusturluyor" 1>&3
    mkdir -p /root/npm

    echo "Paketler Kaldirildi" 1>&3
}

_repoekleniyor() {
    echo -n "Repo Ekleniyor" 1>&3
    apt-get update
    sudo apt-get install \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # "yes" seçeneğini otomatik olarak kabul et
    user_input="yes"

    if [ "$user_input" = "yes" ]; then
        # Docker yüklemesini gerçekleştir
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        echo "Repo Eklendi" 1>&3
    else
        echo "Docker yüklemesi iptal edildi."
    fi
}


_dockerkuruluyor() { 
    echo -n "Docker Kuruluyor" 1>&3
    sudo apt-get update
    sudo apt-get -y install docker-ce docker-ce-cli containerd.io
    echo "Docker Kuruldu" 1>&3
}

_docketcomposekur() {
    echo -n "Docker Compose Kuruluyor" 1>&3
   sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    echo "Docker Compose Kuruldu" 1>&3
}

_dockercomposeymlolustur() {

    echo -n "Dockercompose yml Olusturluyor" 1>&3
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


main