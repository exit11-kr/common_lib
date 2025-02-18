#!/usr/bin/env bash

# letsencrypt 인증서 설치하기

# 파라미터
while getopts "d:" flag; do
    case "${flag}" in
    d) P__DOMAIN=${OPTARG} ;;
    esac
done

if [[ -z $P__DOMAIN ]]; then
    echo "[FAIL] P__DOMAIN is unset"
    exit 1
fi

DOMAIN=${P__DOMAIN}
LETSENCRYPT_CERT_PATH="/etc/letsencrypt/archive/${DOMAIN}"
WS_CERT_PATH="/var/ssl/certs/${DOMAIN}"
VHOST_SSL_CONF_PATH="/opt/docker/etc/nginx/vhost.ssl.conf"
CERT_FILE="cert.pem"
KEY_FILE="key.pem"

echo "Letsencrypt install start ... : ${DOMAIN}"

echo "1. apt-get install letsencrypt ..."
apt-get install letsencrypt

echo "2. sudo letsencrypt ..."
# 인증서 발급받기(webroot 방식 인증실패로 DNS 방식으로 진행)
## 1. IP 로깅을 허용하겠냐고 묻는 화면에서 Y 를 입력
## 2. TXT 에 등록할 내용이 출력되면 복사
## 3. DNS 서버에 TXT 레코드를 등록(https://www.domainclub.kr/ > 무료 웹DNS)
sudo letsencrypt certonly --manual --preferred-challenges dns -d ${DOMAIN}

## 인증서 교체
echo "3. Replacing cert files ..."
if [ ! -d "${WS_CERT_PATH}" ]; then
    mkdir -p ${WS_CERT_PATH}
fi
cp ${LETSENCRYPT_CERT_PATH}/fullchain2.pem ${WS_CERT_PATH}/${CERT_FILE}
cp ${LETSENCRYPT_CERT_PATH}/privkey2.pem ${WS_CERT_PATH}/${KEY_FILE}

# 인증서 경로 수정: /opt/docker/etc/nginx/vhost.ssl.conf
echo "4. Update cert path(vhost.ssl.conf) ..."
sed -i "s%\(ssl_certificate[ \t]\+\)[a-z/.]\+;%\1${WS_CERT_PATH}/${CERT_FILE};%g" ${VHOST_SSL_CONF_PATH}
sed -i "s%\(ssl_certificate_key[ \t]\+\)[a-z/.]\+;%\1${WS_CERT_PATH}/${KEY_FILE};%g" ${VHOST_SSL_CONF_PATH}

## 웹서비스 재시작
echo "5. restart nginx:nginxd ..."
supervisorctl restart nginx:nginxd

echo "Letsencrypt install completed!!"
