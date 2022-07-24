- [Docker DevEnv](#docker-devenv)
- [Prerequisites](#prerequisites)
- [Prerequisites Installation / Configuration](#prerequisites-installation--configuration)
- [Per-Project Configuration](#per-project-configuration)
- [Local Overrides of Project Defaults](#local-overrides-of-project-defaults)
  - [Examples](#examples)
    - [Mount an additional file inside the PHP container](#mount-an-additional-file-inside-the-php-container)
    - [Replace a container service version](#replace-a-container-service-version)
- [Resetting DevEnv to clean slate](#resetting-devenv-to-clean-slate)

## Docker DevEnv

This is a docker-based development environment with hopefully few opinions on
structure. It's meant as a quick-start for those that just want to change a few
options and be up and running. There are some pre-requisites to use this
environment; however, adjustments could be made so that the pre-requisites are
not required.

## Prerequisites

- Docker Desktop
  - This runs the Docker daemon and provides a UI to help manage Docker
  - There are alternatives, like Lima and Colima, but the Docker engine itself
  is required
- DNSMasq
  - This allows routing a specific domain or TLD to a specific IP
  - *This can be ignored if using a live domain and real DNS*
- StepCA
  - Used for the issuance of SSLs for each project
  - This can be replaced by LetsEncrypt (or any ACME-compatible service) and
  your own domain if you want to use a live domain with a real SSL instead
- CoreDNS
  - Provides custom DNS for Traefik / StepCA to validate domains automatically
  - *Can be ignored if using a real ACME-compatible service like Let's Encrypt*
- Mutagen (or Mutagen Compose*)
  - Mutagen is used to synchronize files between the container and the host
  - *DockerSync or other alternatives can be used in Mutagen's place*
  - (!) Mounting the entire filesystem is not suggested as it can have
  performance side effects
- Global Traefik installation
  - This will provide you a single access point to all your development
environments
- Pre-defined Traefik network (in examples named: traefik-backbone)
  - This provides the backbone of the communication network between Traefik and
  the containers it routes traffic to
- [Gitman](https://gitman.readthedocs.io/en/latest/) git dependency tool

## Prerequisites Installation / Configuration

Follow the [Global Services Setup](globalServicesSetup.md) guide to set up
those services that are shared across all projects.


## Per-Project Configuration

1. Install via GitMan
   1. Create a `gitman.yml` ([sample file](https://github.com/bap14/cl-devenv-docker/blob/main/docs/files/gitman.sample.yml)) file:
      - The `gitman_init.sh` script will prompt for the project identifier
         which would be something like "devenv" or "my-test-site". You can
         suppress this prompt by passing the project identifier as an argument 
         to this script. E.g. `./gitman_init.sh "my-development-site"`
      - The project identifier uses all passed arguments to create the project
        the identifier. It will automatically sanitize it so it only includes
        letters, numbers, underscores and dashes. The following commands are
        synonymous:
        ```bash
        # Pass a single argument
        ./gitman_init.sh "my-dev-site"

        # Pass each word as a separate argument
        ./gitman_init.sh my dev site
        ```
   1. Run `gitman install`
1. Update the `dev-db-sync` script for your environment
   1. **For Magento Cloud**
      1. Update `dev-db-sync.cloud.sh` and specify the Magento
         Cloud project ID, or alter it to retrieve data from an separate server
   3. **For On-Prem Magento**
      1. Update `dev-db-sync.on-prem.sh` and specify the SSH host and user to
         connect as.
1. Run the `dev-db-sync` script to populate Docker container with remote data
2. Update your app configuration to point to the proper docker containers
   1. You can use the service name or alias (if one is provided) in the
      `docker-compose.yml` file as the host for your configurations.
      E.g. `'db_host' => 'mysql://docker/my_db'
3. If using Mutagen Compose, [seed the docker volume](mutagen-compose.md#populating-the-docker-volume-first)
4. Start Docker project
   - If using Mutagen Compose
     ```bash
     mutagen-compose up -d
     ```
   - If using Docker
     ```bash
     docker compose up -d && mutagen project start
     ```
   - If using Mutagen and configured with a `beforeCreate` action
     ```bash
     mutagen project start
     ```

## Local Overrides of Project Defaults

If you want to override a project-specific setting locally, you can create a
`docker-compose.local.yml` file alongside the `docker-compose.yml` file. The new
local file just needs to specify the differences, not the full contents of the
compose file.

This will require an adjustment to how the containers are started, as the local
override file will not automatically be picked up. To start the compose project
and include the local override file you need to specify, in reverse order of
preference, the compose files to read:

```bash
docker compose up -d -f docker-compose.yml -f docker-compose.local.yml
```

If you use mutagen-compose the syntax is the same:

```bash
mutagen-compose up -d -f docker-compose.yml -f docker-compose.local.yml
```

If you use the mutagen `beforeCreate` hook, you will need to either edit the
`mutagen.yml` file to change the syntax (and remember not to commit the file)
or create a shell alias to start docker and mutagen:

```bash
alias project-start="docker compose up -d -f docker-compose.yml -f docker-compse.local.yml && mutagen project-start"
```
_This alias not been tested yet and is meant as an example_

### Examples

#### Mount an additional file inside the PHP container

```yaml
services:
  php:
    volumes:
      # Attach my custom script!
      - ${PWD}/bin/my-custom-script.phar:/usr/local/bin/my-custom-script.phar
```

#### Replace a container service version

```yaml
services:
  php:
    # Use the core PHP-maintained debian-based container
    image: php:8.1-fpm

  redis:
    # Test out a specific version of Redis
    image: redis:7.12-alpine
```

## Resetting DevEnv to clean slate

1. Remove all files
   ```
   rm -rf .env \
          .gitignore \
          database \
          elasticsearch \
          docker-compose.yml \
          mutagen.yml \
          nginx \
          repo_sources \
          secrets \
          varnish \
          source \
          dev-db-sync.*.sh
   ```
1. If you had a `docker-compose.local.yml` file you can delete it if you no
   longer need those customizations
1. Remove the docker containers and volumes
   1. Stop any running docker containers for this project
      ```bash
      # Generic Docker command
      docker compose down
      # Mutagen Command
      mutagen project terminate
      # Mutagen-Compose Command
      mutagen-compose down
      ```
   1. List Docker volumes, filtering by project
      ```bash
      . ./.env; docker volume list | grep ${SITE_ID}
      ```
   1. Remove the docker volums listed
      ```bash
      docker volume rm $(. ./.env; docker volume list | grep ${SITE_ID} | awk '{print $2}')
      ```
1. Run through the [Per Project Configuration](#per-project-configuration) steps
   again.
