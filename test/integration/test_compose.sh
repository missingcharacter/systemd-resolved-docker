#!/usr/bin/env bash

. ./functions.sh

exec 10<<EOF
services:
  webserver:
    image: nginx
    labels:
     - $TEST_LABEL
    networks:
      - network
  broker:
    image: redis
    labels:
     - $TEST_LABEL
    networks:
      - network

networks:
  network:
    driver: bridge
    enable_ipv6: false
    labels:
     - $TEST_LABEL
    ipam:
      driver: default
EOF

exec 20<<EOF
services:
  broker:
    image: redis
    labels:
     - $TEST_LABEL
    networks:
      - network

networks:
  network:
    driver: bridge
    enable_ipv6: false
    labels:
     - $TEST_LABEL
    ipam:
      driver: default
EOF

echo 'Before ALLOWED_DOMAINS'

ALLOWED_DOMAINS=.docker,.$TEST_PREFIX start_systemd_resolved_docker

echo 'After ALLOWED_DOMAINS'
echo 'Before first docker compose'

docker compose --file /dev/fd/10 --project-name $TEST_PREFIX up --detach --scale webserver=2

echo 'After first docker compose'
echo "Before docker_ip ${TEST_PREFIX}-broker-1"

broker1_ip=$(docker_ip ${TEST_PREFIX}-broker-1)
echo "broker1_ip is ${broker1_ip}"
webserver1_ip=$(docker_ip ${TEST_PREFIX}-webserver-1)
echo "webserver1_ip is ${webserver1_ip}"
webserver2_ip=$(docker_ip ${TEST_PREFIX}-webserver-2)
echo "webserver2_ip is ${webserver2_ip}"

query_ok     broker.$TEST_PREFIX $broker1_ip
query_ok   1.broker.$TEST_PREFIX $broker1_ip

query_ok     webserver.$TEST_PREFIX $webserver1_ip
query_ok     webserver.$TEST_PREFIX $webserver2_ip
query_ok   1.webserver.$TEST_PREFIX $webserver1_ip
query_ok   2.webserver.$TEST_PREFIX $webserver2_ip

query_ok     broker.docker $broker1_ip

echo 'Before second docker compose'

docker compose --file /dev/fd/20 --project-name ${TEST_PREFIX}_2 up --detach

echo 'After second docker compose'

query_fail   broker.docker
