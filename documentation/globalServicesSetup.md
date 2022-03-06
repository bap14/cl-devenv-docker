## Global Project Services Setup

The global project services are a set of container that every project will
share. These provide general services that don't need to be customized on a
per-project basis and simplify the DevEnv. These services are meant to run
separately from any individual project and to be kept running at all times.

## Service Descriptions

### CoreDNS

This provides internal DNS for StepCA and Traefik to aide in generating SSL
certificates for projects.

### StepCA

This is the actual CA that will be used to issue SSL certificates. It will
house and maintain the root CA certificate and sign and issue all requested
certificates. Failure to initialize the CA, as outlined in the installation
instructions below, may result in incorrect certificates.

### Traefik

This is the powerhouse of the DevEnv. It is a reverse-proxy that will handle
all incoming requests and route them to the correct Docker containers. This
will also handle the automatic request for new SSLs and the periodic upkeep
of requesting renewals.

### MailHog

This is a tool to trap mail from Docker containers and to provide a Web
interface to preview / read the emails. The data is ephemeral so if you want
to save an email, screenshot it.

## Installation

All the services listed above will be contained in their own
`docker-compose.yml` file and started as one project.

1. Create a global network for containers to attach to:
   ```
   docker network create \
     --internal \
     --subnet=172.19.0.0/16 \
     --gateway=172.19.0.1 \
     --ip-range=172.19.128.0/17 \
     traefik-backbone
   ```
1. Create a global services project folder and `cd` into it:
   ```
   mkdir ~/global-services && cd ~/global-services
   ```
1. Create a directory for each service to hold configs and cache files:
   ```
   mkdir -p traefik step-ca coredns/zones.d
   ```
1. Create CoreDNS configuration file<br>
   **coredns/Corefile**
   ```
   . {
     auto {
       # Automatically load all zone files in the directory "/zones.d"
       directory /zones.d db\.(.*) {1}
       # Check to see if the zone files need to be reloaded every 20 seconds
       reload 20s
     }
     # Will forward requests that aren't handled by one of the configured zones    to Cloudflare DNS
     forward . 1.1.1.1:53 1.0.0.1:53
     errors
     log
     # Will automatically reload
     reload
   }
   ```
1. 
1. Create a docker-compose.yml file detailing all the configurations for the
core service containers:
   **docker-compose.yml**
   ```yml
   networks:
     # Use the network we already created
     traefik-backbone:
       external: true
    
   services:
     traefik:
       image: traefik:latest
       container_name: traefik
       restart: unless-stopped
       depends_on:
         - coredns
         - mailhog
         - step-ca
       networks:
         - default
         - traefik-backbone
       # Force Traefik to use CoreDNS
       dns:
         - 172.19.0.53
       # Expose these ports to the host
       ports:
         - "80:80"   # Allow HTTP traffic
         - "443:443" # Allow HTTPS traffic
         - "25:25"   # Allow SMTP traffic
         - "587:587" # Allow SMTP (alt port) traffic
       volumes:
         # This exposes the docker socket so Traefik can read running container
         # configurations for automatic registration
         - /var/run/docker.sock:/var/run/docker.sock
         - ${PWD}/step-ca/certs/:/etc/step-ca/certs
         - ${PWD}/step-ca/secrets:/etc/step-ca/private
         - ${PWD}/coredns-acme-dns01-linux-amd64/:/coredns-acme-dns01-linux-amd64
         - ${PWD}/coredns/zones/:/coredns/zones.d/
         - ${PWD}/traefik/traefik.yml:/etc/traefik/traefik.yml
         - ${PWD}/traefik/acme.json:/acme/acme.json
       environment:
         LEGO_CA_CERTIFICATES: /etc/step-ca/certs/root_ca.crt
         EXEC_PATH: /coredns-acme-dns01-linux-amd64
       labels:
         traefik.enable: true
         traefik.docker.network: traefik-backbone
         traefik.http.routers.traefik-dashboard.entrypoints: http,https
         traefik.http.routers.traefik-dashboard.rule: "Host(`traefik.lan`)"
         traefik.http.routers.traefik-dashboard.tls: true
         traefik.http.routers.traefik-dashboard.tls.certresolver: stepCA
         traefik.http.routers.traefik-dashboard.tls.domains[0].main: "traefik.   lan"
         traefik.http.routers.traefik-dashboard.service: "api@internal"
      
     coredns:
       image: coredns/coredns:1.8.7
       container_name: coredns
       networks:
         traefik-backbone:
           ipv4_address: 172.19.0.53
         default: {}
       volumes:
         - ${PWD}/coredns/Corefile:/Corefile
         - ${PWD}/coredns/zones.d/:/zones.d/
    
     mailhog:
       image: mailhog/mailhog:v1.0.1
       container_name: mailhog
       networks:
         - traefik-backbone
       restart: unless-stopped
       labels:
         traefik.enable: true
         traefik.docker.network: traefik-backbone
         traefik.http.routers.traefik-mailhog.entrypoints: http,https
         traefik.http.routers.traefik-mailhog.rule: Host(`mailhog.lan`)
         traefik.http.routers.traefik-mailhog.tls: true
         traefik.http.routers.traefik-mailhog.tls.certresolver: stepCA
         traefik.http.routers.traefik-mailhog.tls.domains[0].main: "mailhog.lan"
         traefik.http.routers.traefik-mailhog.service: mailhog
         traefik.http.services.mailhog.loadbalancer.server.port: 8025
         traefik.http.services.mailhog.loadbalancer.server.scheme: http
         ## This will allow other services on the Mac to route
         ## mail to 127.0.0.1:1025 and have the emails show in Mailhog
         ##
         # traefik.tcp.routers.traefik-mailhog-mail.rule: "HostSNI(`*`)"
         # traefik.tcp.routers.traefik-mailhog-mail.entrypoints: mail
         # traefik.tcp.routers.traefik-mailhog-mail.service: traefik-mailhog-mail
         # traefik.tcp.services.traefik-mailhog-mail.loadbalancer.server.port:    1025
      
     step-ca:
       image: smallstep/step-ca
       container_name: step-ca
       volumes:
         - ${PWD}/step-ca/:/home/step/
       networks:
         traefik-backbone:
           ipv4_address: 172.19.4.43
           aliases:
             - step-ca
       restart: unless-stopped
       environment:
         DOCKER_STEPCA_INIT_NAME: Classy Llama DevEnv
         DOCKER_STEPCA_INIT_DNS_NAMES: localhost,step-ca
         DOCKER_STEPCA_INIT_PROVISIONER_NAME: devenv@devenv.lan
       command: /bin/sh -c "exec /usr/local/bin/step-ca --password-file /home/step/secrets/password --resolver '172.19.0.53:53' /home/step/config/ca.json"
   ```
1. Start the containers:
   ```
   docker compose up -d
   ```