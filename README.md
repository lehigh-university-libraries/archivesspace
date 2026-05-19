# https://archivesspace.lib.lehigh.edu/

## Overrides

We replaced Archivesspace's default proxy nginx config with traefik

### Bot traffic

### TLS

TLS is terminated by apache on the host machine and forwarded to docker via a config like this

```
        RequestHeader set X-Forwarded-Proto "https"

        # Exclude /server-status from the proxy
        ProxyPass /server-status !

        # Reverse proxy to Docker container
        ProxyPreserveHost On
	RequestHeader set X-Forwarded-For "%{REMOTE_ADDR}e"
        ProxyPass / http://localhost:8200/
        ProxyPassReverse / http://localhost:8200/
```
