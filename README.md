# nginx

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with nginx](#setup)
    * [What nginx affects](#what-nginx-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with nginx](#beginning-with-nginx)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This Puppet module helps you install Nginx via Debian-based package manager.
Use it to configure Nginx to redirect a domain via a proxy to an array of backend servers.

Also, it has a buil-t in proxy module configuration file to forward HTTP requests comming from internal LANs to internet. 
To use this setup, client browsers must be configured to pass reqests via nginx proxy on the specified network socket (IP:PORT)


## Setup and Use this module

First added Nginx class to Hiera file configured for the specified host or cluster. EX: `/etc/puppet/code/hiera/nodes/nginx-p-vm001.yaml`

This will just install a nginx server on the specified node with nginx default configurations provided by the distro. The default configurations will not be tampered for the moment

`nginx-p-vm001.yaml` file excerpt:

```
---
classes:
  - nginx
```


To Enable nginx `domain.conf` file via Hiera without any proxy redirection (use some standard nginx vhost configurations), add the below line in Hiera:

```
nginx::enable_domain_conf: true
```


In order to specify the name of the domain and an alias for the if that's the case, insert the below lines in hiera.

```
nginx::domain_name: 'domain.com'
nginx::domain_alias: 'www.domain.com'
```


To define some upstream backends servers that you will be using to redirect requests for your domain. 
You can define as many upstream servers as required. Just specify the name of the upstream backend and insert new items containing `server` directives, comments, load balancing methods, 'Passive Health Checks' for each server line or other upstream block settings. The advantage of this approach is that you can insert as many backend servers as required.

```
nginx::upstream_servers:
  'to_10.10.10.10':
    - 'server 10.10.10.10:80'
  'to_20.20.20.20':
    - 'ip_hash'
    - '#Implement backend server passive Health Checks'
    - 'server 20.20.20.20:8080 max_fails=3 fail_timeout=30s'
    - 'server 20.20.20.21:8080'
    - 'keepalive 32'
```

The following upstreams will be inserted in Nginx configuration file for your domain:

```
        upstream to_10.10.10.10 {
        server 10.10.10.10:80;
}
        upstream to_20.20.20.20 {
        ip_hash;
        #Implement backend server passive Health Checks;
        server 20.20.20.20:8080 max_fails=3 fail_timeout=30s;
        server 20.20.20.21:8080;
        keepalive 32;
}
```
    
To redirect HTTPS requests for `domain.com` to the first backend server assuming that the backend server is listening on port 80, insert the line in hiera (the `base_domain_proxy_pass` variable must have the following content `Protocol://IP:PORT` EX:(string) `http://20.20.20.20:80`)

This first example uses direct proxy connection to a backend server  -  it does not reference one of the above defined upstreams. 

```
nginx::base_domain_proxy_pass: 'http://10.10.10.10:80'
```

However, you could use one of the defined upstream servers from above. So, the above line should have the below content:
# When you referencing a upstream  backend server, make sure you define the backend in hiera .
```
nginx::base_domain_proxy_pass: 'http://to_10.10.10.10'
```

To redirect all requests to comming to resource2, add the below line.  We also are referencing a pre-defined upstream server.  

```
# Redirect https://domain.com/resource2 to http://to_20.20.20.20 upstream defined above in hiera.
nginx::resource2_domain_proxy_pass: 'http://to_20.20.20.20'
```

This line will insert the follwoing block in Nginx configuration file defined for your domain:

```
    location /resource2 {
      proxy_pass  http://to_20.20.20.20;
      #Return location of the request
      proxy_redirect   http://to_20.20.20.20 https://domain.com/resource2/;
      proxy_set_header        Host $host;
      proxy_set_header        X-Real-IP $remote_addr;
      proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto $scheme;
      proxy_read_timeout  10;

    }
```



To forward HTTP reqests from internal LANs to internet via Nginx forward, first add `nginx::fproxy` class to hiera classes array.

```
---
classes:
  - nginx
  - nginx::fproxy
```

Then enable the proxy configuration file. Otherwise it will not apply the proxy conf or the proxy conf file will be removed removed in the absence of this line or the argument set to `false`.

```
nginx::fproxy::enable_proxy: true
```

You can specify your own values for listening port, resolver and logs. Otherwise use defaults set-up via the module file

To change forward proxy listening port:

```
nginx::fproxy::listen_port: '8090'
```

To change the proxy resolver:

```
nginx::fproxy::resolver: '8.8.8.8'
```


# A complete hiera configuration should look like this:

```
---
classes:
  - nginx
  - nginx::fproxy

nginx::enable_domain_conf: true
nginx::domain_name: 'domain.com'
nginx::domain_alias: 'www.domain.com'
nginx::upstream_servers:
  'to_10.10.10.10':
    - 'server 10.10.10.10:80'
  'to_20.20.20.20':
    - 'ip_hash'
    - '#Implement backend server passive Health Checks'
    - 'server 20.20.20.20:8080 max_fails=3 fail_timeout=30s'
    - 'server 20.20.20.21:8080'
    - 'keepalive 32'
nginx::base_domain_proxy_pass: 'http://10.10.10.10:80'
nginx::resource2_domain_proxy_pass: 'http://to_20.20.20.20'

nginx::fproxy::enable_proxy: true
nginx::fproxy::listen_port: '8090'
nginx::fproxy::resolver: '8.8.8.8'

```

## Limitations

This module has been deployed and tested only in:

Server side:

```
root@storage-vm002:~# puppet -V
4.8.2

root@storage-vm002:~# hiera -V
3.2.0

root@storage-vm002:~# lsb_release -a
No LSB modules are available.
Distributor ID: Debian
Description:    Debian GNU/Linux 9.4 (stretch)
Release:        9.4
Codename:       stretch

root@storage-vm002:~# nginx -v
nginx version: nginx/1.10.3
```

Tested clients: Ubuntu 16.04 and 18.04, Debian 9.



## Release Notes/Contributors/Etc. **Optional**

Copyright Matei Cezar
