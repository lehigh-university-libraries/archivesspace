# Lehigh University ArchivesSpace

## Public URLs
- Production: https://archivesspace.lib.lehigh.edu/
- Staging: https://as-test.lib.lehigh.edu/

## Staff URLs (on-campus only)

- Production: https://archivesspace.lib.lehigh.edu/staff
- Staging: https://as-test.lib.lehigh.edu/staff

## Quick start

To run the stack locally you can

```
git clone git@github.com:lehigh-university-libraries/archivesspace.git
cd archivesspace
make up
```

The stack should then be available at [https://localhost](https://localhost)

## Initial setup (staging and production)

```
cd /opt
git clone https://github.com/lehigh-university-libraries/archivesspace archivesspace
## follow instructions at https://docs.archivesspace.org/administration/docker/
sudo cp /opt/archivesspace/scripts/systemd/archivesspace.service /etc/systemd/system/archivesspace.service
sudo systemctl enable archivesspace
sudo systemctl start archivesspace
```

## Systemd

ArchivesSpace's docker compose stack is bound to the docker service so when the docker daemon restarts on the host the service will start back up. The systemd unit is in [./scripts/systemd](./scripts/systemd/archivesspace.service)


## TLS Certs

Traefik is configured to use Lehigh's wildcard cert. When copying the cert for traefik, ensure the full chain is in `./certs/cert.pem`

```
cd /opt/archivesspace
make lehigh-certs
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
