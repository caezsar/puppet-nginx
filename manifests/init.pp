# By Matei Cezar
class nginx (

# Use the varaibles to setup domain proxies for base domain and resource2 path defined in domain conf file
  $domain_name		= 'domain.com',
  $domain_alias		= undef,
  $enable_domain_conf	= false,
  $domain_file		= "${domain_name}.conf",
  $service_status	= 'running',
  $service_enabled	= true,
  $location_set		= false,
  $upstream_servers	= {},
  $locations		= {}, 
# Old variables for old function in .erb file
	
#	$loc_name				= undef,
#   $proxy_pass				= undef,
#	$proxy_set_header		= undef,
#	$proxy_set_header1		= undef,
#	$proxy_set_header2		= undef,
#	$proxy_set_header3		= undef,
#	$proxy_read_timeout		= undef,
#	$proxy_redirect			= undef
	
	## domain.conf.erb Function to iterate the commented variables
#------------------------------------------------------------------------------------------#
#<% @locations.each do |x| -%>
#location <%= x["loc_name"] %> {
#    proxy_pass    <%= x["proxy_pass"] %>;
#<% if x['proxy_set_header'] -%>    proxy_set_header    <%= x['proxy_set_header'] %>;<% end -%>		
#<% if x['proxy_set_header1'] -%>    proxy_set_header    <%= x['proxy_set_header1'] %>;<% end -%>	
#<% if x['proxy_set_header2'] -%>    proxy_set_header    <%= x['proxy_set_header2'] %>;<% end -%>	
#<% if x['proxy_set_header3'] -%>    proxy_set_header    <%= x['proxy_set_header3'] %>;<% end -%>		
#<% if x['proxy_read_timeout'] -%>    proxy_read_timeout    <%= x['proxy_read_timeout'] %>;<% end -%>		
#<% if x['proxy_redirect'] -%>    proxy_redirect    <%= x['proxy_redirect'] %> https://<%= @domain_name %><%= x["loc_name"] %>;<% end -%>	
#    }
#<% end -%>	
#-------------------------------------------------------------------------------------------#	
) {

# Install Nginx
  package { 'nginx':
    ensure => 'installed',
  }

    # Setup nginx service

    service { 'nginx' :
      ensure => $service_status,
      enable => $service_enabled,
    }
  

## Enable and Apply domain configuration file only if the $enable_conf variable is set to true

if $enable_domain_conf {

  file { "/etc/nginx/sites-available/${domain_file}":
    mode    => '0640',
    owner   => root,
    group   => root,
    content => template('nginx/domain.conf.erb'),
    require => Package['nginx'],
    notify => Service['nginx'],
  }

  file { "/etc/nginx/sites-enabled/${domain_file}":
    ensure   => 'link',
    target   => "/etc/nginx/sites-available/${domain_file}",
    require  => File["/etc/nginx/sites-available/${domain_file}"],
    notify => Service['nginx'],
  }
  
} else {

    file { "/etc/nginx/sites-enabled/${domain_file}":
      ensure  => absent,
      notify => Service['nginx'],
         }
		 
}

  }
