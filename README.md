# File Proxy Service

A lightweight, high-performance file proxy service built on OpenResty that allows you to proxy file downloads through your server while handling redirects transparently.

## Purpose

This service acts as a proxy for file downloads, allowing you to:

- **Proxy file downloads**: Access remote files through your server using a simple URL pattern
- **Handle redirects automatically**: The service follows redirects to reach the final file location
- **Rate limiting**: Protection against abuse with configurable request rate limits

## How It Works

When you access `http://YOUR_SERVER/PREFIX/https://example.com/file.zip`, the service extracts the target URL and proxies your request to it, handling any redirects along the way.

## Usage

### URL Pattern

```
http://YOUR_SERVER_NAME/PREFIX/TARGET_URL
```

- `YOUR_SERVER_NAME`: Your deployed server's domain or IP
- `PREFIX`: Configurable path prefix (default: `fp`)
- `TARGET_URL`: The complete URL of the file you want to proxy

### Examples

If deployed with default settings on `proxy.example.com`:

```bash
# Download a file from GitHub releases
curl "http://proxy.example.com/fp/https://github.com/user/repo/releases/download/v1.0/file.zip"

# Access a file with redirects
curl "http://proxy.example.com/fp/https://bit.ly/some-shortened-url"

# Support git clone
git clone "http://proxy.example.com/fp/https://github.com/user/repo"
```

It can also be used with [this Scoop version which supports URL_PROXY](https://gitee.com/scoop-installer/scoop).

## Deployment

Notice that the service itself doesn't come with SSL support.
If you want HTTPS, please deploy it behind a reverse proxy (nginx, Cloudflare, etc.) for SSL termination.

### Using Docker

#### Quick Start

```bash
# Run with default settings
docker run -d \
  --name fileproxy \
  -p 80:80 \
  ghcr.io/zodiacg/fileproxy:latest
```

#### Custom Configuration

```bash
# Run with custom server name and prefix
docker run -d \
  --name fileproxy \
  -p 80:80 \
  -e SERVER_NAME=proxy.mydomain.com \
  -e PREFIX=files \
  ghcr.io/zodiacg/fileproxy:latest
```

#### Using Docker Compose with Traefik as Reverse Proxy

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  traefik:
    image: traefik
    container_name: traefik
    volumes:
      - traefikdb:/etc/traefik
      - /var/run/docker.sock:/var/run/docker.sock
    command:
      - --entrypoints.web.address=:80
      - --entrypoints.web.forwardedheaders.insecure=true
      - --entrypoints.web.http.redirections.entrypoint.to=websecure
      - --entrypoints.web.http.redirections.entrypoint.scheme=https
      - --entrypoints.websecure.address=:443
      - --entrypoints.websecure.forwardedheaders.insecure=true
      - --entrypoints.websecure.http.tls.certresolver=letsencrypt
      - --providers.docker.exposedbydefault=false
      - --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web
      - --certificatesresolvers.letsencrypt.acme.email=YOUR@EMAIL.COM
      - --certificatesresolvers.letsencrypt.acme.storage=/etc/traefik/acme.json
      - --log.level=INFO
    ports:
      - 80:80
      - 443:443
    restart: unless-stopped
  fileproxy:
    image: ghcr.io/zodiacg/fileproxy:latest
    ports:
      - "80:80"
    environment:
      - SERVER_NAME=proxy.example.com
      - PREFIX=fp
    restart: unless-stopped
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.fileproxy.entrypoints=websecure'
      - 'traefik.http.routers.fileproxy.rule=Host(`proxy.example.com`)'

volumes:
  traefikdb:
    driver: local
```

Then run:

```bash
docker-compose up -d
```

### Configuration Options

The service can be configured using environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `SERVER_NAME` | The server name/domain for nginx | `example.com` |
| `PREFIX` | URL path prefix for the proxy service | `fp` |

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.