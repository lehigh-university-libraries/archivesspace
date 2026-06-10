#!/usr/bin/env bash

set -eou pipefail

echo "Copying Lehigh's certs into traefik"

cat /etc/ssl/certs/lib.lehigh.edu.crt /etc/ssl/certs/gd_bundle-g2-g1.crt | sudo tee certs/cert.pem

sudo cp /etc/ssl/private/lib.lehigh.edu.key certs/privkey.pem
sudo chmod 700 certs/privkey.pem
sudo chown root certs/privkey.pem
