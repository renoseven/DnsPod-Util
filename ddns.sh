#!/bin/bash

if [ $# -ne 2 ]; then
        echo "Usage: $0 example.com www";
        exit 1;
fi

record_id=$(./dnspod-util.sh -t "$(cat api_token)" -o "getid $1 $2 A 默认");
if [ -z "$record_id" ]; then
        ./dnspod-util.sh -t "$(cat api_token)" -o "add $1 $2 A 默认 0.0.0.0" --nologo;
fi

if [ $? -eq 0 ]; then
        ./dnspod-util.sh -t "$(cat api_token)" -o "ddns $1 $2 A 默认" --nologo;
fi
