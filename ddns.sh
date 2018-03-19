#!/bin/bash
if [ -z $1 ] || [ -z $2 ]; then
	echo "Usage: $0 example.com www";
	exit 1;
fi

if [ -z "$(./dnspod-util.sh -i "$(cat api_id)" -k "$(cat api_key)" -o "_get_record_id $1 $2 A 默认")" ]; then
	./dnspod-util.sh -i "$(cat api_id)" -k "$(cat api_key)" -o "add $1 $2 A 默认 0.0.0.0" --nologo;
fi
./dnspod-util.sh -i "$(cat api_id)" -k "$(cat api_key)" -o "ddns $1 $2 A 默认" --nologo;