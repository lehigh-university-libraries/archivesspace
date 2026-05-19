# Lehigh University ArchivesSpace

## Public URLs
- Production: https://archivesspace.lib.lehigh.edu/
- Staging: https://as-test.lib.lehigh.edu/

## Staff URLs (on-campus only)

- Production: https://archivesspace.lib.lehigh.edu/staff
- Staging: https://as-test.lib.lehigh.edu/staff

## Initial setup

```
cd /opt
git clone https://github.com/lehigh-university-libraries/archivesspace archivesspace-docker-config
## follow instructions at https://docs.archivesspace.org/administration/docker/
sudo cp /opt/archivesspace-docker-config/scripts/systemd/archivesspace.service /etc/systemd/system/archivesspace.service
sudo systemctl enable archivesspace
sudo systemctl start archivesspace
```

## Systemd

ArchivesSpace's docker compose stack is bound to the docker service so when the docker daemon restarts on the host the service will start back up. The systemd unit is in [./scripts/systemd](./scripts/systemd/archivesspace.service)

### TLS

Lehigh's default TLS setup is managed by SET using apache. To stay inline with SET's TLS management TLS requests to ArchiveSpace are terminated by apache on the host machine and forwarded to docker via an Apach config like this

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
## Docker overriddes

SET ships syslog to their ELK stack. So to get docker's logs there we ship them to syslog.
```
$ cat /etc/docker/daemon.json
{
  "log-driver": "syslog",
  "log-opts": {
    "tag": "{{.Name}}"
  }
}
```

## Docker Compose Overrides

- **Pinned docker image tags** and **removed host ports binds** solr and mariadb no longer expose their ports on the host, leaving their network only available inside the docker network namespace
  - https://github.com/lehigh-university-libraries/archivesspace/commit/2346946d223c423984e099068d4ea69cb555a329
- **Replaced ArchivesSpace NGINX proxy with Traefik** We replaced Archivesspace's default proxy nginx config with traefik. This is so we can easily add CloudFlare Turnstile in front of the public UI
  - https://github.com/lehigh-university-libraries/archivesspace/commit/bf25dfe5d00b61b3dd85e3049825226b06833abf
