**UPDATE** It seems like simp_le isn't really getting supported any more, whilst this version of the container still works (with the acme branch), I envisage it stopping working in the near future, and i'll have to update this to a different method of cert generation.  I'm open to pull requests :D

# nginx
This is an nginx reverse proxy designed to front microservices with HTTPS, using [letsencrypt](https://letsencrypt.org/).

## Volumes
You need to persist your certificates, so mount the `/etc/letsencrypt/live` folder!

## Automatic certificate generation
When the container boots, if no certificates are found, it will do the following:

  - First create a self signed certificate for the domain in question (so we can start nginx, and letsencrypt can do it's host checks).
  - Use [simp_le](https://github.com/kuba/simp_le) to generate, or update the letsencrypt certificates for the domain.

## Multiple domains, no configuration
You can host multiple domains on the same NGINX:443 host (see the example below).

The default server part is important, as we're hosting multiple SSL certificates on the same IP, Nginx will use [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) to serve up the relevant endpoint.  If the client doesn't support SNI (for example, my curl client on macosx?!) then you'll get the default server. 

```
version: '2'

services:
  nginx:
    image: stono/docker-nginx-letsencrypt 
    restart: always
	volumes:
	  - ./certs:/etc/letsencrypt/live
    environment:
      - HOST_WEBSITE1=website1.yourdomain.net,localhost:9000,default_server
      - HOST_DASHBOARD=website2.yourdomain.net,localhost:9001
    ports:
      - 443
      - 80
```
