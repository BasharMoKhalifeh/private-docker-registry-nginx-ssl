# TLS Certificates

This directory is intentionally kept free of real certificate/private-key material.

The Nginx configuration expects:

```text
registry.lab.local.crt
registry.lab.local.key
```

Generate them locally with:

```bash
./scripts/generate-certs.sh registry.lab.local
```

The generated files are ignored by Git.

## Important

The certificate must contain the registry hostname in its Subject Alternative Name (SAN). For this lab:

```text
DNS:registry.lab.local
```

For production, replace the self-signed certificate with a certificate issued by a trusted internal or public Certificate Authority.
