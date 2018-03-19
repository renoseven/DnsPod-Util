#!/bin/bash

# Shell script info
SCRIPT_NAME="DnsPod-Util";
VERSION="0.1";
AUTHOR="dev@renoseven.net";
USER_AGENT="$SCRIPT_NAME/$VERSION($AUTHOR)";

# Dnspod.cn domain api
REST_API="https://dnsapi.cn";
REST_FORMAT="json";
REST_LANG="en";
REST_RECORD_LIST="Record.List";
REST_RECORD_CREATE="Record.Create";
REST_RECORD_MODIFY="Record.Modify";
REST_RECORD_REMOVE="Record.Remove";
REST_RECORD_ddns="Record.Ddns";

#========================
# Operations
#========================
# add
# usage: add domain sub_domain record_type record_line value mx ttl status weight
function add() {
	_warn "$FUNCNAME $*";

	_log "Adding record...";
	local response=$(_rest $REST_RECORD_CREATE "domain=$1&sub_domain=$2&record_type=$3&record_line=$4&value=$5&mx=$6&ttl=$7&status=$8&weight=$9");
	if [ -z "$response" ]; then
		_err "Failed";
		return 1;
	fi

	_succ "Success";
	return 0;
}

# modify
# usage: modify domain sub_domain record_type record_line value mx ttl status weight 
function modify() {
	_warn "$FUNCNAME $*";
	
	local response=$(_rest_record_update $REST_RECORD_MODIFY ${@:1:4} "value=$5&mx=$6&ttl=$7&status=$8&weight=$9");
	if [ -z "$response" ]; then
		_err "Failed";
		return 1;
	fi

	_succ "Success";
	return 0;
}

# ddns
# usage: ddns domain sub_domain record_type record_line
function ddns() {
	_warn "$FUNCNAME $*";
	
	local response=$(_rest_record_update $REST_RECORD_ddns ${@:1:4});
	if [ -z "$response" ]; then
		_err "Failed";
		return 1;
	fi

	_succ "Success";
	return 0;
}

# remove
# usage: remove domain sub_domain record_type record_line
function remove() {
	_warn "$FUNCNAME $*";
	
	local response=$(_rest_record_update $REST_RECORD_REMOVE ${@:1:4});
	if [ -z "$response" ]; then
		_err "Failed";
		return 1;
	fi

	_succ "Success";
	return 0;
}

#========================
# Requesting
#========================
# _rest
# usage: _rest rest_action rest_data
function _rest() {
	_log "Fetching $REST_API/$1?${@:2}";
	local response=$(curl -s -X POST "$REST_API/$1" -A "$USER_AGENT" -d "$REST_TOKEN&$2");
	if [ -z "$response" ]; then
		_err "Failed";
		return 1
	fi
	# _log "response: $response";
	local status_code=$(_parse_response "$response" '.status .code');
	local status_message=$(_parse_response "$response" '.status .message');
	if [ $status_code -ne 1 ]; then
		_err "Status code: $status_code, $status_message";
		return 1;
	fi
	# _log "status code: $status_code";
	printf "$response";
	return 0;
}

# _rest_record_update
# usage: _rest_record_update rest_action domain sub_domain record_type record_line rest_data
function _rest_record_update() {
	# _log "$FUNCNAME $*";
	_log "Getting record id...";
	local record_id=$(_get_record_id ${@:2:5});
	if [ -z "$record_id" ]; then
		_err "No matches record";
		return 1;
	fi
	
	local response=$(_rest $1 "domain=$2&record_id=$record_id&sub_domain=$3&record_type=$4&record_line=$5&$6");
	if [ -z "$response" ]; then
		return 1;
	fi

	printf "$response";
}

# _get_record_id
# usage: _get_record_id domain sub_domain record_type record_line
function _get_record_id() {
	# _log "$FUNCNAME $*";
	local response=$(_rest $REST_RECORD_LIST "domain=$1&sub_domain=$2");
	if [ -z "$response" ]; then
		return 1;
	fi

	local record_count=$(_parse_response "$response" ".info .record_total");
	if [ -z "$record_count" ]; then
		return 1;
	fi

	_log "Record count: $record_count";
	for ((index=0; index<$record_count; index++))
	do
		local record_name=$(_parse_response "$response" ".records[$index] .name");
		local record_type=$(_parse_response "$response" ".records[$index] .type");
		local record_line=$(_parse_response "$response" ".records[$index] .line");
		if [[ "$record_type" == "$3" && "$record_line" == "$4" ]]; then
			local record_id=$(_parse_response "$response" ".records[$index] .id");
			break;
		fi
	done

	if [ -z "$record_id" ]; then
		return 1;
	fi

	_log "Record id: $record_id";
	printf "$record_id";
}

#========================
# Parsing
#========================
# _parse_response
# usage: _parse_response response selector
function _parse_response() {
	printf "$1" | jq "$2" | tr -d '"';
}

#========================
# Logging
#========================
# _log
# usage: _log message
function _log() {
	_format_output "$1" >&2;
}

# _err
# usage: _err message
function _err() {
	printf '\033[31m' >&2;
	_format_output "$1" >&2;
	printf '\033[0m' >&2;
}

# _succ
# usage: _succ message
function _succ() {
	printf '\033[32m' >&2;
	_format_output "$1" >&2;
	printf '\033[0m' >&2;
}

# _warn
# usage: _warn message
function _warn() {
	printf '\033[33m' >&2;
	_format_output "$1" >&2;
	printf '\033[0m' >&2;
}


# _format_output
# usage: _format_output message
function _format_output() {
	# printf "[%s] %-20s -- %s\n" "$(date +'%F %T')" "${FUNCNAME[2]}" "$1";
	printf "[%s] -- %s\n" "$(date +'%F %T')" "$1";
}

#========================
# Helping information
#========================
# app_info
function app_info() {
	printf "\n";
	printf "====================================================================\n";
	printf "                                  #                #       #   ###  \n";
	printf " ###               ###            #        #   #   #             #  \n";
	printf " #  #  ####  ####  #  #  ###    ###        #   #  ####   ###     #  \n";
	printf " #  #  #  #  #     #  # #   #  #  #        #   #   #       #     #  \n";
	printf " #  #  #  #   ##   ###  #   #  #  #  ###   #   #   #       #     #  \n";
	printf " #  #  #  #     #  #    #   #  #  #        #   #   #       #     #  \n";
	printf " ###   #  #  ####  #     ###    ###         ###     ##   ####  #### \n";
	printf "====================================================================\n";
	printf "$SCRIPT_NAME\n";
	printf "Version: $VERSION\n";
	printf "Author: $AUTHOR\n";
	printf "\n";
}

# usage_info
function usage_info() {
	printf "%s\n" "Usage: $0 -i <api_id> -k <api_key> -o [operation]";
	printf "\t%-15s\t\t%s\n" "-h, --help" "Help information";
	printf "\t%-15s\t\t%s\n" "-i, --id" "Dnspod API ID";
	printf "\t%-15s\t\t%s\n" "-k, --key" "Dnspod API Key";
	printf "\t%-15s\t\t%s\n" "-o, --operation" "Operations:";
	printf "\t%-15s\t\t%s\t%s\n" "" "add" "[domain sub_domain record_type record_line value mx ttl status weight]";
	printf "\t%-15s\t\t%s\t%s\n" "" "modify" "[domain sub_domain record_type record_line value mx ttl status weight]";
	printf "\t%-15s\t\t%s\t%s\n" "" "ddns" "[domain sub_domain record_type record_line]";
	printf "\t%-15s\t\t%s\t%s\n" "" "remove" "[domain sub_domain record_type record_line]";
}

# help_info
function help_info() {
	usage_info;
}

#========================
# Entrance
#========================
ARGS=$(getopt -o 'i:k:o:nh' -a -l 'id:,key:,operation:,nologo,help' -n "$0" -- "$@");
eval set -- "$ARGS";

while true
do
	case $1 in  
		-i|--id)
			shift;
			API_ID=$1;
			shift;
			;;
		-k|--key)
			shift;
			API_KEY=$1;
			shift;
			;;
		-o|--operation)
			shift;
			OPERATION=$1;
			shift;
			;;
		-n|--nologo)
			FLAG_NO_LOGO="TRUE";
			shift;
			;;
		-h|--help)
			usage_info >&2;
			exit 0;
			;;
		--)
			break;
			;;
		*)
			usage_info >&2;
			exit 1;
			;;  
	esac
done

if ([ -z "$API_ID" ] || [ -z "$API_KEY" ] || [ -z "$OPERATION" ]); then
	usage_info >&2;
	exit 1;
else
	if [ -z $FLAG_NO_LOGO ]; then
		app_info >&2;
	fi
	REST_TOKEN="login_token=$API_ID,$API_KEY&format=$REST_FORMAT&lang=$REST_LANG";
	#eval "$OPERATION";
fi