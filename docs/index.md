## Docker DevEnv

This is a docker-based development environment with hopefully few opinions on
structure. It's meant as a quick-start for those that just want to change a few
options and be up and running. There are some pre-requisites to use this
environment; however, adjustments could be made so that the pre-requisites are
not required.

## Prerequisites

- Docker Desktop
  - This runs the Docker Daemon
  - There are alternatives, but Docker itself is required
- DNSMasq
  - This allows routing a specific domain or TLD to a specific IP
  - *This can be ignored if using a live domain*
- StepCA
  - Used for the issuance of SSLs for each project
  - This can be replaced by LetsEncrypt (or any ACME service) and your own
  domain if you want to use a live domain with a real SSL instead
- CoreDNS
  - Provides custom DNS for Traefik / StepCA to validate domains
  - *Can be ignored if using a real ACME service like Let's Encrypt*
- Mutagen (or Mutagen Compose*)
  - Mutagen is used to synchronize files between the container and the host
  - *DockerSync or other alternatives can be used in Mutagen's place*
  - (!) Mounting the entire filesystem is not suggested as it can have
  performance side effects
- Global (or generic) Traefik installation
  - This will provide you a single access point to all your development
environments
- Pre-defined network (in examples named: traefik-backbone)
  - This provides the backbone of the communication network between Traefik and
  the containers it routes traffic to
  - Without this you will get Gateway Timeouts from Traefik

## Docker Desktop

Grab the latest version from [docker.com](http://docker.com) and install it.
You can configure the general resource limits in Windows and MacOS for the
shadow VM that Docker needs to run.

### Installation

1. Run the downloaded installer
1. Start Docker Desktop if it isn't already running
1. Configure Docker settings
   1. Click the Cog icon in the top right
      1. Ensure `Use gRPC FUSE for file sharing` is enabled
      1. Ensure `Use Docker Compose V2` is enabled
   1. Under `Resources` tab:
      1. Under `Advanced`:
         1. Set maximum number of CPUs allowed to at most 1/2 of your Mac's CPU
         core count
            - Example: 16-core Intel should have no more than 8 set as the max
         1. Set maximum memory to at most 1/2 of your Mac's memory
            - Example: 16GB Mac should have no more than 8 set as the max
      1. Under `File Sharing`:
         1. Make sure `/Users` or the folder container all your projects is
         shared
      1. Under `Network` (Optional):
         1. Adjust the Docker subnet
   1. Click `Apply & Restart` to apply your changes

### Alternatives

Docker Desktop is not free for everyone, so it may not be a fit for you or your
organization. You do not need to use Docker Desktop for this. This is intended
for use with Docker, so any Docker service will work (e.g. Lima or Colima).

## Core Services Installation / Configuration

Follow the [Global Services Setup](globalServicesSetup.md) guide to set up
those services that are shared across all projects.


## Per-Project Configuration

1. Install via GitMan
1. Create / update `.env` file using this as a template
   ```
   DOMAIN="example.lan"
   WILDCARD_DOMAIN="*.example.lan"
   SITE_ID="example"
   COMPOSE_PROJECT_NAME=$SITE_ID
   ```
1. If using Mutagen Compose, [seed the docker volume](mutagen-compose.md#populating-the-docker-volume-first)
1. Start Docker project
   - If using Mutagen Compose
   ```
   mutagen-compose up -d
   ```
   - If using Docker
   ```
   docker compose up -d && mutagen project start
   ```
   - If using Mutagen and configured with a `beforeCreate` action
    ```
    mutagen project start
    ```
