# reverse-proxy-icap-docker (Release 2)

[Source](https://github.com/k8-proxy/k8-reverse-proxy)

Release 2 includes the completed/tested pieces of the Reverse Proxy project as a "reverse-proxy-icap-docker" to run inside a standard Ubuntu 18.04 (WSL and contianerized environements arent supported) server OVA image. The completed pieces of this project so far are:

- Squid based reverse Proxy for a specific website, with ICAP integration.
- Two Way URL rewrite/ with the help of NGINX in front of Squid.
- SSL termination.
- GW Rebuild ICAP service

**Default configuration includes proxy for**

- assets.publishing.service.gov.uk.glasswall-icap.com
- gov.uk.glasswall-icap.com
- www.gov.uk.glasswall-icap.com
- Built-in GW Rebuild ICAP service, can be change by setting **ICAP_URL** in `gwproxy.env`

## Preparation

We needed to check the website requests to check domains of interest, (domains that should be proxied), which typically are:

- Website main domain and www subdomain (if applicable)

- Domains used in redirects between website pages (example: authentication redirections)

- Domains that hosts files that should be rebuilt against Glasswall rebuild engine

### Finding domains of interest

- Open a browser that included dev tools (i.e : **Mozilla Firefox**)

- Open dev tools and switch to **Network** tab (CTRL+SHIFT+E in **Firefox**)

- Visit target website main page, surf the website and try to download files while watching requested domains 

- Save domains in question to be used in configuration

### Preparing environment:

```bash
sudo apt-get update && sudo apt-get install curl git -y
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker $( whoami )
```

You will have to logout and relogin before deploying the solution

## Preparing source code

0. Clone repository and goto the stable-src

```bash
git clone --recursive https://github.com/k8-proxy/k8-reverse-proxy
cd stable-src
git submodule update # Update submodules
wget -O c-icap/Glasswall-Rebuild-SDK-Evaluation/Linux/Library/libglasswall.classic.so https://github.com/filetrust/sdk-rebuild-eval/raw/master/libs/rebuild/linux/libglasswall.classic.so # Get latest evaluation build of GW Rebuild engine
```

This means that any occurence of **.gov.uk** in the response should be replaced with **.gov.uk.glasswall-icap.com** , and **.amazonaws.com** will be replaced with **.amazonaws.com.glasswall-icap.com** .

1. If you are deploying the proxy for other websites, tweak `gwproxy.env`:
   **ALLOWED_DOMAINS** variable to include a comma-separated list of proxied domains, any requests to other domains will be denied.
   
   Set **ROOT_DOMAIN** to match the domain used as suffix for backend domains.
   
   You can modify the file using `nano gwproxy.env`, save and exit using`CTRL+X`, then `Y`

   Use [this configuration file](https://github.com/k8-proxy/k8-reverse-proxy/blob/master/stable-src/gwproxy.env) as example

   - `ROOT_DOMAIN`: Domain used by the proxy (example: www.gov.uk.glasswall-icap.com is proxying www.gov.uk) 

   - `ALLOWED_DOMAINS` : Comma separated domains accepted by the proxy, typically this should be domains of interest with the `ROOT_DOMAIN` value appended

   - `SQUID_IP` IP address of squid proxy, used by nginx, should be only changed on advanced usage of the docker image

   - `SUBFILTER_ENV`: Space separated text substitution rules in response body, foramtted as **match,replace** , used for url rewriting as in **.gov.uk,.gov.uk.glasswall-icap.com**
  
   - `ICAP_EXCLUDE_MIME_TYPE`: Comma separated mime types in Content-Type header format to exclude from ICAP adaptation, leave empty to disable


## Deployment

2. Execute the following
   
   ```bash
   docker-compose up -d
   ```

3. Verify that all containers are up
   
   ```bash
   docker-compose ps
   ```

## Troubleshooting

- Check if docker service is active
  
  ```bash
  systemctl status docker
  ```

- Check if containers are up and running (not Restarting...)
  
  ```bash
  docker-compose ps
  ```

- If squid or nginx is not started correctly, the configuration parameters in `gwproxy.env` has been modified, execute:
  
  ```bash
  docker-compose up -d --force-recreate
  ```

- You have to assign all proxied domains to the docker host ip address by adding them to hosts file ( `C:\Windows\System32\drivers\etc\hosts` on Windows , `/etc/hosts` on Linux )
  for example: 

```
192.168.0.10 gov.uk.glasswall-icap.com www.gov.uk.glasswall-icap.com assets.publishing.service.gov.uk.glasswall-icap.com
```

where `192.168.0.10` is an example for the IP address for the docker host (i.e Cloud or local VM), You will need to replace domains with domains in **ALLOWED_DOMAINS** from `gwproxy.env` in case you are deploying to target another backend site.

Make sure you are able to connect to the docker host and that no firewall/routes rules are preventing connections to TCP ports 80 or 443.

You can test the stack functionality by downloading [a rich PDF file](https://assets.publishing.service.gov.uk.glasswall-icap.com/government/uploads/system/uploads/attachment_data/file/901225/uk-internal-market-white-paper.pdf) through the proxy and testing it against [file-drop.co.uk](https://file-drop.co.uk)
You can also visit [the proxied main page](https://www.gov.uk.glasswall-icap.com/) and make sure that the page loads correctly and no requests/links is pointing to the original `*.gov.uk` or other malformed domains.
