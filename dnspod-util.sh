#!/bin/bash

# Shell script getinfo
SCRIPT_NAME="DnsPod-Util.sh";
VERSION="0.21";
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
REST_RECORD_DDNS="Record.Ddns";

#========================
# Operations
#========================
# getinfo
# usage: getinfo domain sub_domain record_type record_line
function getinfo() {
        if [ $# -ne 2 ]; then
                _log "usage: $FUNCNAME domain sub_domain";
        fi
        _warn "Getting record info...";
        _log "[Record] $*";
        local record_info=$(_traverse_records _record_info_filter ${@:1});
        printf "$record_info";
}

# getid
# usage: getid domain sub_domain record_type record_line
function getid() {
        if [ $# -ne 4 ]; then
                _log "usage: $FUNCNAME record domain sub_domain record_type record_line";
        fi
        _warn "Getting record id...";
        _log "[Record] $*";
        local record_id=$(_traverse_records _record_id_filter ${@:1});
        printf "$record_id";
}

# add
# usage: add domain sub_domain record_type record_line value mx ttl status weight
function add() {
        if [ $# -ne 5 ]; then
                _log "usage: $FUNCNAME domain sub_domain record_type record_line value mx ttl status weight";
        fi
        _warn "Adding record...";
        _log "[Record] $*";
        local response=$(_rest $REST_RECORD_CREATE "domain=$1&sub_domain=$2&record_type=$3&record_line=$4&valu                                                                                                     e=$5&mx=$6&ttl=$7&status=$8&weight=$9");
        _rest_status "$response";
        return $?;
}

# modify
# usage: modify domain sub_domain record_type record_line value mx ttl status weight
function modify() {
        _warn "Modifing record...";
        _log "[Record] $*";
        local response=$(_rest_update $REST_RECORD_MODIFY ${@:1:4} "value=$5&mx=$6&ttl=$7&status=$8&weight=$9"                                                                                                     );
        _rest_status "$response";
        return $?;
}

# ddns
# usage: ddns domain sub_domain record_type record_line
function ddns() {
        _warn "Adding ddns record...";
        _log "[Record] $*";
        local response=$(_rest_update $REST_RECORD_DDNS ${@:1:4});
        _rest_status "$response";
        return $?;
}

# remove
# usage: remove domain sub_domain record_type record_line
function remove() {
        _warn "Removing record...";
        _log "[Record] $*";
        local response=$(_rest_update $REST_RECORD_REMOVE ${@:1:4});
        _rest_status "$response";
        return $?;
}

#========================
# Parsing
#========================

# _parse_domain
# usage: _parse_domain domain
function _parse_domain() {
        printf "${1#*.*} ${1%.*.*}";
}

# _parse_json
# usage: _parse_json response selector
function _parse_json() {
        printf "$1" | jq "$2";
}

# _parse_value
# usage: _parse_value response selector
function _parse_value() {
        _parse_json "$@" | tr -d '"';
}

#========================
# REST
#========================
# _rest
# usage: _rest rest_action rest_data
function _rest() {
        _log "Fetching $REST_API/$1?${@:2}";
        curl -s -X POST "$REST_API/$1" -A "$USER_AGENT" -d "$REST_TOKEN&$2";
}

# _rest_update
# usage: _rest_update rest_action domain sub_domain record_type record_line rest_data
function _rest_update() {
        # _log "$*";
        local record_id=$(getid ${@:2});
        if [ -z "$record_id" ]; then
                printf '{"status":{"code":"10","message":"No records"}}';
                return;
        fi

        local response=$(_rest $1 "domain=$2&record_id=$record_id&sub_domain=$3&record_type=$4&record_line=$5&                                                                                                     $6");
        printf "$response";
}

# _rest_status
# usage: _rest_status response
function _rest_status() {
        if [ -z "$response" ]; then
                _err "Error: No response";
                return 1;
        fi

        local status_code=$(_parse_value "$1" '.status .code');
        local status_message=$(_parse_value "$1" '.status .message');
        if [ $status_code -ne 1 ]; then
                _err "Error: $status_message ($status_code)";
                return 1;
        else
                _succ "$status_message";
        fi
}

#========================
# Record filter
#========================
# _traverse_records
# usage: _traverse_records function domain sub_domain record_type record_line
function _traverse_records() {
        # _warn "Reading record list...";
        # _log "$*";
        local response=$(_rest $REST_RECORD_LIST "domain=$2&sub_domain=$3");
        _rest_status "$response";
        if [ $? -ne 0 ]; then
                return 1;
        fi

        local record_count=$(_parse_value "$response" ".info .record_total");
        if [ $record_count -lt 1 ]; then
                return 1;
        fi

        for ((index=0; index<$record_count; index++))
        do
                local record=$(_parse_json "$response" ".records[$index]");
                $1 "$record" ${@:2};
                if [ $? -ne 0 ]; then
                        break;
                fi
        done
}
# _record_id_filter
# usage: _record_id_filter record domain sub_domain record_type record_line
function _record_id_filter() {
        # _log "$*";
        local record_type=$(_parse_value "$1" ".type");
        local record_line=$(_parse_value "$1" ".line");
        if [[ "$record_type" == "$4" && "$record_line" == "$5" ]]; then
                local record_id=$(_parse_value "$1" ".id");
                printf "$record_id";
        fi
}

# _record_info_filter
# usage: _record_id_filter record domain sub_domain
function _record_info_filter() {
        # _log "$*";
        printf "$1\n\r";
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
# Helping getinformation
#========================
# app_getinfo
function app_getinfo() {
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

# usage_getinfo
function usage_getinfo() {
        printf "%s\n" "Usage: $0 -t <api_token> -o [operation]";
        printf "\t%-15s\t\t%s\n" "-t, --token" "Dnspod api token [id,key]";
        printf "\t%-15s\t\t%s\n" "-o, --operation" "Operations:";
        printf "\t%-15s\t\t%s\t%s\n" "" "getid" "[domain sub_domain record_type record_line]";
        printf "\t%-15s\t\t%s\t%s\n" "" "getinfo" "[domain sub_domain]";
        printf "\t%-15s\t\t%s\t%s\n" "" "add" "[domain sub_domain record_type record_line value mx ttl status                                                                                                      weight]";
        printf "\t%-15s\t\t%s\t%s\n" "" "modify" "[domain sub_domain record_type record_line value mx ttl stat                                                                                                     us weight]";
        printf "\t%-15s\t\t%s\t%s\n" "" "ddns" "[domain sub_domain record_type record_line]";
        printf "\t%-15s\t\t%s\t%s\n" "" "remove" "[domain sub_domain record_type record_line]";
        printf "\t%-15s\t\t%s\n" "-h, --help" "Show help information";
}

#========================
# Entrance
#========================
ARGS=$(getopt -o 't:o:nh' -a -l 'token:,operation:,nologo,help' -n "$0" -- "$@");
eval set -- "$ARGS";

while true
do
        case $1 in
                -t|--token)
                        shift;
                        API_TOKEN=$1;
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
                        usage_getinfo >&2;
                        exit 0;
                        ;;
                --)
                        break;
                        ;;
                *)
                        usage_getinfo >&2;
                        exit 1;
                        ;;
        esac
done


if ([ -z "$API_TOKEN" ] || [ -z "$OPERATION" ]); then
        usage_getinfo >&2;
        exit 1;
fi

if [ -z $FLAG_NO_LOGO ]; then
        app_getinfo >&2;
fi

REST_TOKEN="login_token=$API_TOKEN&format=$REST_FORMAT&lang=$REST_LANG";
$OPERATION;
