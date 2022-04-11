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
1. Copy the files from the host to volume: `docker compose cp ../../. php:/app/`
   The path `../../.` is used because this command must be run from the directory
   where the docker-compose.yml file is located, and to only copy the contents of
   the directory and not the directory itself.
1. Optional: Clean up unnecessary files that were copied over
   ```
   docker compose exec php /bin/sh -c "rm -rf /app/tools /app/.idea"
   ```
1. Wait for the process to finish
1. Stop the container: `docker compose down`
