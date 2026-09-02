#!/usr/bin/env bash
set -euo pipefail

HOSTNAME="${1:-registry.lab.local}"
CERT_DIR="$(cd "$(dirname "$0")/../certs" && pwd)"

mkdir -p "$CERT_DIR"

openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout "$CERT_DIR/${HOSTNAME}.key" \
  -out "$CERT_DIR/${HOSTNAME}.crt" \
  -days 365 \
  -subj "/CN=${HOSTNAME}" \
  -addext "subjectAltName=DNS:${HOSTNAME}"

chmod 600 "$CERT_DIR/${HOSTNAME}.key"
chmod 644 "$CERT_DIR/${HOSTNAME}.crt"

echo "Generated TLS certificate for ${HOSTNAME}"
echo "Certificate: ${CERT_DIR}/${HOSTNAME}.crt"
echo "Private key: ${CERT_DIR}/${HOSTNAME}.key"
