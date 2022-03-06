# Docker DevEnv

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

## DNSMasq (Optional)

If you want to work offline or use a custom TLD (e.g. .lan or .devenv) this
will allow you to route any domain to a specific IP. It will only resolve what
it has authority to resolve and will pass along all other requests to a real
DNS server.

### Installation

1. Install the DNSMasq package
    - `brew install dnsmasq `
    - **Windows:** ?? Isn't supported, but any other DNS Proxy where you can
    define specific entries get routed to a particular IP would work
      - It may be possible to use the CoreDNS Docker container for this;
      however, that is outside the scope of this document.
1. Add record to forward all requests for `.lan` addresses to DNSMasq
    - `echo "address=/.lan/127.0.0.1" | sudo tee -a /usr/local/etc/dnsmasq.conf`
1. Add custom resolver for `.lan`
    - Create the resolver directory (if it doesn't already exist):
    `sudo mkdir /etc/resolver`
    - Add DNSMasq as the resolver for `.lan`:
    `echo nameserver 127.0.0.1" | sudo tee /etc/resolver/lan`
1. Restart MacOS Resolver
   `sudo killall -HUP mDNSResponder;
   sudo killall mDNSResponderHelper;
   sudo dscacheutil -flushcache`
1. Validate the resolver is now able to use DNSMasq:
   `scutil --dns | rep -A3 -B1 lan`
    - You should expect to see something like the following:
      ```
      resolver #8
         domain   : lan
         nameserver[0] : 127.0.0.1
         flags    : Request A records, Request AAAA records
         reach    : 0x00030002 (Reachable,Local Address,Directly Reachable Address)

## Mutagen

Install mutagen via Homebrew like any other package: `brew install mutagen`

Once installed you can use the sample file as a guide on how to configure this
project.

## Mutagen-Compose

Mutagen-Compose is a docker-compose replacement that will start a separate
container process to keep files inside a docker volume and on the host in sync.
There are some caveats to this which require some initial workflow adjustments.

### Installation

Install mutagen-compose via Homebrew: `brew install mutagen-compose`

Once installed you will need to adjust your `docker-compose.yml` file to include
a new `x-mutagen` key with the Mutagen sync configuration you want.

Examples of this are forthcoming, but the sample `mutagen.yml` file has most of
what you need and can generally be copied as-is to the `x-mutagen` key. One of
the few updates would be the `beta` source as that no longer requires the special
URL of `docker://` but can reference the volume directly.

### You need to populate the docker volume first before you start Mutagen-Compose

Mutagen-Compose will run as a "root" user and will not necessarily respect the
existing permissions of the Docker volume (if it exists). This means that files
inside the Docker container will be owned by root and unable to be edited by
the user the container runs as. This will present problems as PHP or other
containers attempt to write files (e.g. logs, static content).

#### Populating the Docker volume first

Pre-populating the volume is a relatively straight forward process that should
only need to be completed when initializing the project (or after deleting
the volume):

1. Start the PHP container (or any container that uses the volume)
`docker compose up -d php`
1. Copy the files from the host to volume: `docker compose copy -R . php:/app`
1. Wait for the process to finish
1. Stop the container: `docker compose down`

#### Starting the project

Once the volume has been prepopulated with the code, then to start the project
you just use `mutagen-compose` instead of `docker compose`. The mutagen script
is a wrapper for `docker compose` and supports all of Docker Compose's
commands.

## Global Project Services Setup

You can read how to install Traefik, StepCA and CoreDNS in the [Global Project Services Setup](documentation/globalServicesSetup.md) document.