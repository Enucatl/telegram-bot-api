#!/usr/bin/env sh
set -e

# Build argv directly so POSIX sh preserves argument boundaries at exec.
set -- telegram-bot-api

# Sets $env_var from $file_env_var content or directly from $env_var.
file_env() {
    env_var="$1"
    file_env_var="$2"
    env_value=$(printenv "$env_var") || env_value=""
    file_path=$(printenv "$file_env_var") || file_path=""

    if [ -z "$env_value" ] && [ -z "$file_path" ]; then
        echo "error: expected $env_var or $file_env_var env vars to be set"
        exit 1
    elif [ -n "$env_value" ] && [ -n "$file_path" ]; then
        echo "both $env_var and $file_env_var env vars are set, expected only one of them"
        exit 1
    elif [ -n "$file_path" ]; then
        if [ -f "$file_path" ]; then
            export "$env_var=$(cat "$file_path")"
        else
            echo "error: $env_var=$file_path: file '$file_path' does not exist"
            exit 1
        fi
    fi
}

check_required_env() {
  var_name="$1"

  if [ -z "$(printenv "$var_name")" ]; then
    echo "error: environment variable $var_name is required"
    exit 1
  fi
}

arg_from_env() {
    var_name="$1"
    arg_name="$2"
    default_value="$3"
    env_value=$(printenv "$var_name") || env_value=""
    ARG_VALUE=""

    [ -n "$env_value" ] || env_value="$default_value"
    if [ -n "$env_value" ]; then
      ARG_VALUE="${arg_name}=$env_value"
    fi
}

flag_from_env() {
  var_name="$1"
  flag_name="$2"
  ARG_VALUE=""

  if [ -n "$(printenv "$var_name")" ]; then
    ARG_VALUE="$flag_name"
  fi
}

check_required_env "TELEGRAM_WORK_DIR"

file_env "TELEGRAM_API_ID" "TELEGRAM_API_ID_FILE"
file_env "TELEGRAM_API_HASH" "TELEGRAM_API_HASH_FILE"

arg_from_env "TELEGRAM_WORK_DIR" "--dir"
set -- "$@" "$ARG_VALUE"
check_required_env "TELEGRAM_TEMP_DIR"
arg_from_env "TELEGRAM_TEMP_DIR" "--temp-dir"
set -- "$@" "$ARG_VALUE"

check_required_env "TELEGRAM_API_ID"
check_required_env "TELEGRAM_API_HASH"

arg_from_env "TELEGRAM_HTTP_PORT" "--http-port" "8081"
set -- "$@" "$ARG_VALUE"

flag_from_env "TELEGRAM_LOCAL" "--local"
[ -z "$ARG_VALUE" ] || set -- "$@" "$ARG_VALUE"

if [ -n "$(printenv "TELEGRAM_STAT")" ]; then
  arg_from_env "TELEGRAM_HTTP_STAT_PORT" "--http-stat-port" "8082"
  set -- "$@" "$ARG_VALUE"
  arg_from_env "TELEGRAM_HTTP_STAT_IP_ADDRESS" "--http-stat-ip-address" "127.0.0.1"
  set -- "$@" "$ARG_VALUE"
fi

arg_from_env "TELEGRAM_LOG_FILE" "--log"
[ -z "$ARG_VALUE" ] || set -- "$@" "$ARG_VALUE"
arg_from_env "TELEGRAM_FILTER" "--filter"
[ -z "$ARG_VALUE" ] || set -- "$@" "$ARG_VALUE"
arg_from_env "TELEGRAM_MAX_WEBHOOK_CONNECTIONS" "--max-webhook-connections"
[ -z "$ARG_VALUE" ] || set -- "$@" "$ARG_VALUE"
arg_from_env "TELEGRAM_VERBOSITY" "--verbosity"
[ -z "$ARG_VALUE" ] || set -- "$@" "$ARG_VALUE"
arg_from_env "TELEGRAM_MAX_CONNECTIONS" "--max-connections"
[ -z "$ARG_VALUE" ] || set -- "$@" "$ARG_VALUE"
arg_from_env "TELEGRAM_PROXY" "--proxy"
[ -z "$ARG_VALUE" ] || set -- "$@" "$ARG_VALUE"
arg_from_env "TELEGRAM_HTTP_IP_ADDRESS" "--http-ip-address"
[ -z "$ARG_VALUE" ] || set -- "$@" "$ARG_VALUE"

echo "Starting telegram-bot-api"
exec "$@"
