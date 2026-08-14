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

Traefik uses Lehigh's Let's Encrypt wildcard certificate through Compose
secrets. The weekly wildcard updater invokes `/usr/local/sbin/local-cert-hook`
after it downloads these files:

- Full certificate chain: `/etc/ssl/certs/le/lib.lehigh.edu.pem`
- Private key: `/etc/ssl/private/le/lib.lehigh.edu.key`

Install the hook and its root-only configuration on each Docker host:

```
cd /opt/archivesspace
sudo install -o root -g root -m 0600 \
  scripts/local-cert-hook.env.example /etc/default/local-cert-hook
sudoedit /etc/default/local-cert-hook # set SLACK_WEBHOOK and EXPECTED_HOST
sudo install -o root -g root -m 0755 \
  scripts/lehigh-certs.sh /usr/local/sbin/local-cert-hook
sudo chown root:root /opt/archivesspace /opt/archivesspace/docker-compose.yml certs
sudo chmod go-w /opt/archivesspace /opt/archivesspace/docker-compose.yml certs
```

The hook validates the full chain, hostname, expiry, private key, and key/cert
pair before changing anything. It compares SHA-256 checksums with the files
already backing the Compose secrets, so an unchanged renewal exits without
recreating Traefik. When either file has changed, it atomically installs both
and force-recreates only Traefik so Docker remounts the secrets. Any validation,
Compose, or healthcheck failure is sent to Slack and logged to stderr and
syslog.

The hook and every path it uses for root-level Compose operations must remain
root-owned and not group/world-writable. Salt can manage the two installed
files instead of the commands above; keep `/etc/default/local-cert-hook` at
mode `0600` because it contains the Slack webhook.

To invoke the same hook manually:

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
