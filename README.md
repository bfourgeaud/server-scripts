# server-scripts

## Compatibility

* Debian 9.x

## Installation

```shell
sudo apt install git
git clone
sudo chmod +x ./configure.sh
sudo chmod +x ./web_server.sh
```
## Running Script

```shell
sudo ./configure.sh
```

## Available options

- [x] Installing Apache or Nginx web server
- [x] Configuring Firewall (ufw) for HTTP/https
- [x] Setting Up VirtualHosts for Apache and NGINX
- [x] Configuring Multiple site instances
- [x] Setting up Let's Encrypt certificates

- [x] Installing nodejs
- [x] Installing Worpress & MariaDB
- [x] Getting sources from GitHub Repository

- [ ] Installing MongoDB
- [ ] Choose between verbose or non verbose installation

## TODO
- [ ] Do not always reconfigure Firewall
- [ ] Getting files from GitHub also for static files (not just NodeJS)
- [ ] Wordpress : Configure basic informations (wp-admin/install.php)
- [ ] Wordpress : Pre-Install Modules and Templates
- [ ] Activate gzip compression
