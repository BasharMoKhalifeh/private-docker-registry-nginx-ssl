# Private Docker Registry with Nginx & SSL/TLS

A hands-on DevOps lab for building and securing a private Docker image registry behind an Nginx reverse proxy with SSL/TLS.

This project documents the container registry, reverse-proxy, certificate, Docker trust, Linux/SELinux troubleshooting, and image push/pull workflow used in the lab environment.

## Architecture

```text
Docker Client
     |
     | HTTPS :443
     v
+----------------------+
| Nginx Reverse Proxy  |
| SSL/TLS termination   |
+----------+-----------+
           |
           | HTTP :5000
           v
+----------------------+
| Docker Registry :5000|
|      registry:2      |
+----------------------+
           |
           v
     Registry Storage
```

The registry is kept behind Nginx instead of being directly exposed to the client. Nginx terminates TLS and forwards registry API requests to the Docker Registry container.

## Technologies

- Docker
- Docker Registry v2 (`registry:2`)
- Nginx
- SSL/TLS
- Linux / Oracle Linux
- SELinux
- Docker CLI
- Docker networking

## What I Implemented

- Deployed a private Docker Registry using the official Registry image.
- Configured persistent registry storage using a Docker volume.
- Created a dedicated Docker network for the registry and reverse proxy.
- Configured Nginx as a reverse proxy in front of the registry.
- Added HTTPS/SSL termination at Nginx.
- Configured the registry endpoint using a local lab hostname such as `registry.lab.local`.
- Worked through Docker certificate trust issues, including the `x509: certificate signed by unknown authority` error.
- Troubleshot Linux file permissions and SELinux restrictions that prevented Nginx from accessing certificate files.
- Verified image push and pull operations through the HTTPS registry endpoint.

## Project Structure

```text
private-docker-registry-nginx-ssl/
├── README.md
├── .gitignore
├── docker-compose.yml
├── registry/
│   └── config.yml
├── nginx/
│   └── nginx.conf
├── certs/
│   └── README.md
└── scripts/
    └── generate-certs.sh
```

> Private keys and generated certificates are intentionally excluded from Git. Generate them locally following `certs/README.md`.

## Prerequisites

- Linux host with Docker and Docker Compose available.
- Docker client on the machine used to push/pull images.
- A hostname resolving to the registry server, for example:

```text
registry.lab.local -> <registry-server-ip>
```

For a lab environment, this can be configured through `/etc/hosts` or a local DNS server.

## 1. Clone the Repository

```bash
git clone https://github.com/BasharMoKhalifeh/private-docker-registry-nginx-ssl.git
cd private-docker-registry-nginx-ssl
```

## 2. Generate Local TLS Certificates

Create the certificate directory and make the script executable:

```bash
mkdir -p certs
chmod +x scripts/generate-certs.sh
```

Run:

```bash
./scripts/generate-certs.sh registry.lab.local
```

The script creates:

```text
certs/
├── registry.lab.local.crt
└── registry.lab.local.key
```

These files are ignored by Git and must never be committed to a public repository.

For a production deployment, use certificates issued by a trusted Certificate Authority rather than a self-signed certificate.

## 3. Start the Registry and Nginx

```bash
docker compose up -d
```

Check the containers:

```bash
docker compose ps
```

Check logs:

```bash
docker compose logs registry
docker compose logs nginx
```

## 4. Verify the Registry

From the registry host:

```bash
curl -k https://registry.lab.local/v2/
```

A healthy Registry API normally responds with:

```text
{}
```

The `-k` option is useful for a self-signed certificate during lab testing. A properly trusted CA certificate should be used without `-k`.

## 5. Trust the Lab Certificate

When using a self-signed certificate, Docker may reject the registry with:

```text
x509: certificate signed by unknown authority
```

Docker can be configured to trust a private registry certificate by placing the CA/certificate in Docker's registry certificate directory on the client:

```text
/etc/docker/certs.d/registry.lab.local/ca.crt
```

Then restart Docker if required by the client environment:

```bash
sudo systemctl restart docker
```

> The exact trust configuration depends on whether the certificate is self-signed or signed by an internal CA. Never disable TLS verification as a production solution.

## 6. Push an Image

Build or pull a test image:

```bash
docker pull nginx:latest
```

Tag it for the private registry:

```bash
docker tag nginx:latest registry.lab.local/nginx:latest
```

Push it:

```bash
docker push registry.lab.local/nginx:latest
```

## 7. Pull an Image

Remove the local tag/image if desired and pull through the registry:

```bash
docker pull registry.lab.local/nginx:latest
```

Verify the image:

```bash
docker images | grep nginx
```

## 8. Troubleshooting

### `x509: certificate signed by unknown authority`

The Docker client does not trust the registry certificate.

Check:

```bash
ls -l /etc/docker/certs.d/registry.lab.local/
```

Make sure the appropriate CA certificate is installed and that the registry hostname matches the certificate SAN.

### Nginx cannot read the certificate

Typical checks:

```bash
ls -l certs/
ls -Z certs/
```

On SELinux-enabled systems, access can be denied even when normal Unix permissions look correct. The lab required SELinux troubleshooting so Nginx could access the TLS material.

Do not permanently disable SELinux just to work around a labeling or policy problem. Investigate the denial and apply the narrowest appropriate SELinux configuration.

### Check Nginx configuration

```bash
docker compose exec nginx nginx -t
```

### Check Registry API directly inside the Docker network

```bash
docker compose exec nginx wget -qO- http://registry:5000/v2/
```

### Check listening ports

```bash
ss -lntp
```

## Security Notes

- Do not commit `.key`, `.pem`, password files, or real credentials.
- Use a trusted internal/public CA for production environments.
- Restrict access to the registry network and host firewall.
- Consider authentication and authorization for production registries.
- Keep the registry and Nginx images patched.
- Use persistent storage with appropriate backup procedures.

## Key Learning Outcomes

- How a Docker Registry stores and serves container images.
- How Nginx can act as a reverse proxy for a registry.
- How TLS protects registry traffic.
- How Docker validates registry certificates.
- How hostname/SAN configuration affects TLS validation.
- How Linux permissions and SELinux can affect Nginx access.
- How to diagnose issues across the Docker, Nginx, TLS, and Linux layers.

## Future Improvements

- Add registry authentication with `htpasswd`.
- Add an internal Certificate Authority.
- Add image retention and garbage-collection procedures.
- Add monitoring and health checks.
- Integrate the registry with a CI/CD pipeline.
- Add vulnerability scanning for pushed images.

## Author

**Bashar Khalifeh** — DevOps-focused Computer Science graduate building practical infrastructure and automation projects.
