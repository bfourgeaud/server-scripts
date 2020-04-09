# server-scripts

## Compatibility

* Debian 9.x

## Installation

```shell
sudo apt install git
git clone https://github.com/bfourgeaud/server-scripts.git
cd /server-scripts/
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
- [ ] Choose between verbose or non verbose installation
- [ ] Activate gzip compression
- [x] Do not always reconfigure Firewall
- [ ] Testing performances
- [ ] Webcrawling : Checking if all pages respond
- [ ] Testing SEO
- [ ] Setting up email alerts (Server down, ... )

### NodeJS

- [x] Installing nodejs
- [x] Getting sources from GitHub Repository
- [ ] Installing MongoDB

### Wordpress

- [x] Installing Worpress
- [x] Setting up MariaDB
- [ ] Configure basic informations (wp-admin/install.php)
- [ ] Pre-Install Modules and Templates

### Django

- [ ] Installing django
- [ ] Getting sources from GitHub Repository
- [ ] Installing Database

### Static HTML/PHP

- [x] Getting sources from GitHub Repository
- [x] Creating default index.html / index.php file

##IMPROVEMENTS
- [ ] Configurator in nodeJS app -> Launch script to create/show/edit/delete instance on the fly
- [ ] List of preconfigured modules for Wordpress and NodeJS (Menus, Footers, Layouts, ... )
