# nginx


## Description

This Puppet module helps you install Nginx via Debian-based package manager.
Use it to configure Nginx to redirect a domain via a proxy to an array of backend servers.

Also, it has a buil-t in proxy module configuration file to forward HTTP requests comming from internal LANs to internet. 
To use this setup, client browsers must be configured to pass reqests via nginx proxy on the specified network socket (IP:PORT)


## Setup and Use this module

First added Nginx class to Hiera file configured for the specified host or cluster. 
EX: `/etc/puppet/code/hiera/nodes/nginx-p-vm001.yaml`

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


In order to specify the name of the domain and an alias for the domain, if that's the case, insert the below lines in hiera.

```
nginx::domain_name: 'domain.com'
nginx::domain_alias: 'www.domain.com'
```
On a cluster, you can setup the domain name using each cluster node `fqdn` fact. Then, just insert the below lines in each node `fqdn.yaml` file to setup custom node configurations.

```
nginx::domain_name: "%{facts.hostname}"
```

Define some upstream backends servers that you will be using to redirect requests for your domain. 
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

The following upstreams definitions will be inserted in Nginx configuration file for your domain:

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
    
To redirect HTTPS requests for `domain.com` to the first backend server, assuming that the backend server is listening on port 80, insert the below line in hiera (the `base_domain_proxy_pass` variable must have the following content `Protocol://IP:PORT` EX: `http://20.20.20.20:80`)

This first example uses direct proxy connection to a backend server  -  it does not reference one of the above defined upstreams. 

```
nginx::base_domain_proxy_pass: 'http://10.10.10.10:80'
```

However, you could use one of the above defined upstream servers. So, the above line should have the below content:
### When you referencing a upstream backend server in `base_domain_proxy_pass`, make sure you previously define the backend in hiera.
```
nginx::base_domain_proxy_pass: 'http://to_10.10.10.10'
```

To redirect all requests to comming to `resource2`, add the below line.  We also are referencing a pre-defined upstream server.  

```
# Redirect https://domain.com/resource2 requests to http://to_20.20.20.20 upstream backend previously defined in hiera.
nginx::resource2_domain_proxy_pass: 'http://to_20.20.20.20'
```

This line will insert the follwoing block of code in your domain conf file:

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

If you want to stop disable nginx service system-wide, on a node, insert the below lines:
```
nginx::service_status: 'stopped'
nginx::service_enabled: false
```

## Nginx forward proxy and log HTTP requests

To forward HTTP reqests from internal LANs to internet via Nginx forward, first add `nginx::fproxy` class to hiera classes array.

```
---
classes:
  - nginx
  - nginx::fproxy
```

Then, enable the proxy configuration file. However, if you first set the argument to `true` and then you change it `false` or delete this line, this causes the proxy conf file to be automatically removed.

```
nginx::fproxy::enable_proxy: true
```

To rename Nginx default proxy file (`forward_proxy.conf`):

```
nginx::fproxy::fproxy_file: 'my_proxy.conf'
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

In the forward proxy conf file, the first block of code defines how requests should be logged. Nginx will also write to the log the follwoing requests: request protocol, remote IP and time take to serve the request, as illustrated in the below log file output:

```
root@stg01-p-buc:~# tailf /var/log/nginx/proxy_access.log 
192.168.168.121 - - [09/May/2018:08:50:07 +0300] "CONNECT js-agent.newrelic.com:443 HTTP/1.1" 400 325 "-" "-" "-"0.001 - .
192.168.168.121 - - [09/May/2018:08:50:11 +0300] "GET http://docs.nginx.com/nginx/ HTTP/1.1" 200 19592 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:59.0) Gecko/20100101 Firefox/59.0" "-"0.555 0.555 .
192.168.168.121 - - [09/May/2018:08:50:11 +0300] "CONNECT www.googletagmanager.com:443 HTTP/1.1" 400 325 "-" "-" "-"0.001 - .
192.168.168.121 - - [09/May/2018:08:50:11 +0300] "GET http://docs.nginx.com/nginx/admin-guide/ HTTP/1.1" 200 1459 "http://docs.nginx.com/nginx/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:59.0) Gecko/20100101 Firefox/59.0" "-"0.115 0.115 .
192.168.168.121 - - [09/May/2018:08:50:14 +0300] "CONNECT amplify.nginx.com:443 HTTP/1.1" 400 325 "-" "-" "-"0.001 - .
192.168.168.121 - - [09/May/2018:08:50:18 +0300] "CONNECT www.googletagmanager.com:443 HTTP/1.1" 400 325 "-" "-" "-"0.000 - .
192.168.168.121 - - [09/May/2018:08:50:18 +0300] "GET http://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-plus-amazon-web-services/ HTTP/1.1" 200 7258 "http://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:59.0) Gecko/20100101 Firefox/59.0" "-"0.114 0.114 .
192.168.168.121 - - [09/May/2018:08:50:35 +0300] "CONNECT www.nginx.com:443 HTTP/1.1" 400 325 "-" "-" "-"0.001 - .
192.168.168.121 - - [09/May/2018:08:50:38 +0300] "CONNECT 1-edge-chat.facebook.com:443 HTTP/1.1" 400 325 "-" "-" "-"0.001 - .
192.168.168.121 - - [09/May/2018:08:50:39 +0300] "CONNECT 1-edge-chat.facebook.com:443 HTTP/1.1" 400 325 "-" "-" "-"0.001 - .
^X^C
root@stg01-p-buc:~# 
```




### A complete hiera configuration should look like this:

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
