<p>
  <a href="https://github.com/Enucatl/telegram-bot-api/actions/workflows/multiarch.yml">
    <img alt="build: passing" src="https://img.shields.io/github/actions/workflow/status/Enucatl/telegram-bot-api/multiarch.yml?branch=main&label=build&logo=githubactions">
  </a>
  <a href="https://github.com/Enucatl/telegram-bot-api/pkgs/container/telegram-bot-api">
    <img alt="latest tag" src="https://img.shields.io/badge/ghcr.io%2Fenucatl%2Ftelegram--bot--api-latest-blue?logo=docker">
  </a>
</p>

# What is this fork about?

- runs the Telegram Bot API as a non-root container user instead of starting as root and dropping privileges inside the binary
- supports constrained runtime profiles: all Linux capabilities can be dropped, `no-new-privileges` can be enabled, the root filesystem can be read-only, and writable paths can be limited to explicit volumes and bounded tmpfs mounts
- exposes persistent working and temporary directories as Docker volumes so operators can keep writable state separate from the image filesystem
- keeps copy-pasteable examples off public interfaces by binding published ports to `127.0.0.1`
- reads Telegram API credentials from `TELEGRAM_API_ID_FILE` and `TELEGRAM_API_HASH_FILE`, so examples can use file-based secrets instead of direct environment variables
- binds the optional statistics endpoint to `127.0.0.1` inside the container by default when enabled, because it exposes operational data and can change log verbosity
- hardens the nginx file-serving example with read-only access to bot API data, a read-only root filesystem, dropped capabilities, bounded tmpfs mounts, connection/request limits, and download throttling while preserving support for large Telegram media files
- builds entrypoint arguments as argv instead of a shell command string, preserving argument boundaries at `exec`
- reduces build and CI exposure by ignoring local metadata/secrets in Docker build contexts and using explicit least-privilege GitHub Actions token permissions
- runs vulnerability and configuration scanning in CI with Trivy: the maintained Dockerfile is scanned before publishing, the published image is scanned after push, SARIF results are uploaded to GitHub code scanning, and vendored upstream TDLib example files are excluded from the filesystem scan so the fork is judged on the Docker surface it maintains
- has a HEALTHCHECK

### Minimal secure compose example

```yaml
services:
  telegram-bot-api:
    image: aiogram/telegram-bot-api:latest
    user: "101"
    read_only: true
    tmpfs:
      - /tmp/telegram-bot-api:rw,noexec,nosuid,nodev,size=256m
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    pids_limit: 256
    mem_limit: 512m
    volumes:
      - telegram-bot-api-data:/var/lib/telegram-bot-api
    ports:
      - "127.0.0.1:8081:8081"
    environment:
      TELEGRAM_API_ID_FILE: /run/secrets/telegram_api_id
      TELEGRAM_API_HASH_FILE: /run/secrets/telegram_api_hash
    secrets:
      - telegram_api_id
      - telegram_api_hash

secrets:
  telegram_api_id:
    file: ./secrets/telegram_api_id
  telegram_api_hash:
    file: ./secrets/telegram_api_hash
```

# Unofficial Docker image of Telegram Bot API

Here is Docker image for https://github.com/tdlib/telegram-bot-api

The Telegram Bot API provides an HTTP API for creating [Telegram Bots](https://core.telegram.org/bots).

If you've got any questions about bots or would like to report an issue with your bot, kindly contact us at [@BotSupport](https://t.me/BotSupport) in Telegram.

## Quick reference

Before start, you will need to obtain `api-id` and `api-hash` as described in https://core.telegram.org/api/obtaining_api_id and specify them using `TELEGRAM_API_ID_FILE` and `TELEGRAM_API_HASH_FILE`. Direct `TELEGRAM_API_ID` and `TELEGRAM_API_HASH` environment variables are also supported, but file-based secrets avoid exposing credentials through container metadata.

And then to start the Telegram Bot API all you need to do is
`docker run -d -p 127.0.0.1:8081:8081 --name=telegram-bot-api --restart=always --read-only --cap-drop=ALL --security-opt=no-new-privileges:true --pids-limit=256 --memory=512m --tmpfs /tmp/telegram-bot-api:rw,noexec,nosuid,nodev,size=256m -v telegram-bot-api-data:/var/lib/telegram-bot-api -v /path/to/secrets:/run/secrets:ro -e TELEGRAM_API_ID_FILE=/run/secrets/telegram_api_id -e TELEGRAM_API_HASH_FILE=/run/secrets/telegram_api_hash aiogram/telegram-bot-api:latest`

The API port is intentionally bound to localhost in the examples. Do not expose it directly to the public internet without a trusted reverse proxy and the network controls you need for your deployment.

## Configuration

Container can be configured via environment variables

### `TELEGRAM_API_ID`, `TELEGRAM_API_HASH`

Application identifiers for Telegram API access, which can be obtained at https://my.telegram.org as described in https://core.telegram.org/api/obtaining_api_id

Use `TELEGRAM_API_ID_FILE` and `TELEGRAM_API_HASH_FILE` to read these values from files instead of direct environment variables.

### `TELEGRAM_STAT`

Enable statistics HTTP endpoint.

When enabled, the stats endpoint binds to `127.0.0.1` inside the container by default because it exposes operational data and can change log verbosity. Check it with `docker exec <container> curl http://127.0.0.1:8082`.

Use `TELEGRAM_HTTP_STAT_IP_ADDRESS` and `TELEGRAM_HTTP_STAT_PORT` only on a trusted private network. Do not publish the stats endpoint to the public internet.

### `TELEGRAM_FILTER`

"<remainder>/<modulo>". Allow only bots with 'bot_user_id % modulo == remainder'

### `TELEGRAM_MAX_WEBHOOK_CONNECTIONS`

default value of the maximum webhook connections per bot

### `TELEGRAM_VERBOSITY`

log verbosity level

### `TELEGRAM_LOG_FILE`

Filename where logs will be redirected (By default logs will be written to stdout/stderr streams)

### `TELEGRAM_MAX_CONNECTIONS`

maximum number of open file descriptors

### `TELEGRAM_PROXY`

HTTP proxy server for outgoing webhook requests in the format http://host:port

### `TELEGRAM_LOCAL`

allow the Bot API server to serve local requests

### `TELEGRAM_HTTP_IP_ADDRESS`

Use the `TELEGRAM_HTTP_IP_ADDRESS: "[::]"` parameter to listen on the ipv6 intranet

### `TELEGRAM_HTTP_PORT`

Set which port the api server should listen to if you want to run the image in network mode as host and want to change the port.

If not set then the api server will listen to port 8081.

## Start with persistent storage

Server working directory is `/var/lib/telegram-bot-api` so if you want to persist the server data you can mount this folder as volume:

`-v telegram-bot-api-data:/etc/telegram/bot/api`

Note that all files in this directory will be owned by user `telegram-bot-api` and group `telegram-bot-api` (uid: `101`, gid: `101`, compatible with [nginx](https://hub.docker.com/_/nginx) image)

## Usage via docker stack deploy or docker-compose

```yaml
version: '3.7'

services:
  telegram-bot-api:
    image: aiogram/telegram-bot-api:latest
    user: "101"
    read_only: true
    tmpfs:
      - /tmp/telegram-bot-api:rw,noexec,nosuid,nodev,size=256m
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    pids_limit: 256
    mem_limit: 512m
    environment:
      TELEGRAM_API_ID_FILE: /run/secrets/telegram_api_id
      TELEGRAM_API_HASH_FILE: /run/secrets/telegram_api_hash
    secrets:
      - telegram_api_id
      - telegram_api_hash
    volumes:
      - telegram-bot-api-data:/var/lib/telegram-bot-api
    ports:
      - "127.0.0.1:8081:8081"

volumes:
  telegram-bot-api-data:

secrets:
  telegram_api_id:
    file: ./secrets/telegram_api_id
  telegram_api_hash:
    file: ./secrets/telegram_api_hash
```
