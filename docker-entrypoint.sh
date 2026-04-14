#!/usr/bin/env sh
set -e

COMMAND="telegram-bot-api"

# Appends an argument to the COMMAND variable.
append_args() {
  COMMAND="$COMMAND $1"
}

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

append_arg_from_env() {
    var_name="$1"
    arg_name="$2"
    default_value="$3"
    env_value=$(printenv "$var_name") || env_value=""

    [ -n "$env_value" ] || env_value="$default_value"
    if [ -n "$env_value" ]; then
      append_args "${arg_name}=$env_value"
    fi
}

append_flag_from_env() {
  var_name="$1"
  flag_name="$2"

  if [ -n "$(printenv "$var_name")" ]; then
    append_args "$flag_name"
  fi
}

check_required_env "TELEGRAM_WORK_DIR"

file_env "TELEGRAM_API_ID" "TELEGRAM_API_ID_FILE"
file_env "TELEGRAM_API_HASH" "TELEGRAM_API_HASH_FILE"

append_arg_from_env "TELEGRAM_WORK_DIR" "--dir"
check_required_env "TELEGRAM_TEMP_DIR"
append_arg_from_env "TELEGRAM_TEMP_DIR" "--temp-dir"

check_required_env "TELEGRAM_API_ID"
check_required_env "TELEGRAM_API_HASH"

append_arg_from_env "TELEGRAM_HTTP_PORT" "--http-port" "8081"
append_flag_from_env "TELEGRAM_LOCAL" "--local"
append_flag_from_env "TELEGRAM_STAT" "--http-stat-port=8082"
append_arg_from_env "TELEGRAM_LOG_FILE" "--log"
append_arg_from_env "TELEGRAM_FILTER" "--filter"
append_arg_from_env "TELEGRAM_MAX_WEBHOOK_CONNECTIONS" "--max-webhook-connections"
append_arg_from_env "TELEGRAM_VERBOSITY" "--verbosity"
append_arg_from_env "TELEGRAM_MAX_CONNECTIONS" "--max-connections"
append_arg_from_env "TELEGRAM_PROXY" "--proxy"
append_arg_from_env "TELEGRAM_HTTP_IP_ADDRESS" "--http-ip-address"

echo "$COMMAND"
exec $COMMAND
