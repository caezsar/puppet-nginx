class nginx::fproxy (

# Use the varaibles to setup domain forward proxy
  $enable_proxy	= false,
  $listen_port	= '8080',
  $resolver	= '1.1.1.1',
  $access_log	= '/var/log/nginx/proxy_access.log',
  $error_log	= '/var/log/nginx/proxy_error.log',
  $fproxy_file	= 'forward_proxy.conf'		
  
) {

## Enable and Apply proxy forward conf file only if the $enable_proxy variable is set to true in hiera

if $enable_proxy == true { 
  
  file { "/etc/nginx/conf.d/${fproxy_file}":
    mode    => '0640',
    owner   => root,
    group   => root,
    content => template('nginx/forward_proxy.conf.erb'),
    require => Package['nginx'],
    notify => Service['nginx'],
  }

} else {

file { "/etc/nginx/conf.d/${fproxy_file}":
      ensure  => absent,
      notify => Service['nginx'],
           }

    }

  }
