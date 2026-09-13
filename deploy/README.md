# Deployment

This deployment uses GitHub Actions, GHCR, Docker Compose, and SSH. It does not
use Kubernetes or Terraform.

## One-time Debian setup

Create `/srv/biltongssh` and `/srv/biltongssh/host-keys`, owned by the user used
by the workflow. Generate the application host key once:

```sh
ssh-keygen -t ed25519 -N '' -f /srv/biltongssh/host-keys/host_ed25519
chmod 700 /srv/biltongssh/host-keys
chmod 600 /srv/biltongssh/host-keys/host_ed25519
```

Install Docker Engine and the Docker Compose plugin, and make sure the deploy
user can run Docker. If the GHCR package is private, log in to GHCR as that
user with a read-only package token before the first deployment.

The server must allow inbound TCP port `23234` to the host. After deployment,
connect with:

```sh
ssh -p 23234 <user>@<server-address>
```

## GitHub configuration

Create a protected GitHub Actions environment named `production` and add these
secrets to it:

- `DEPLOY_HOST`: server hostname or IP address
- `DEPLOY_USER`: server deployment username
- `DEPLOY_SSH_PRIVATE_KEY`: private key authorized for that user
- `DEPLOY_KNOWN_HOSTS`: verified `known_hosts` entry for the server

The workflow tests pull requests, publishes a commit-addressed image to GHCR,
and deploys only after a successful push to `master`. The server-side script
deploys by digest and rolls back to the previous image if the new container
does not become reachable on port `23234`.
