id = 'tls'

default[id]['data_bag_name'] = 'tls'

default[id]['base_dir'] = '/etc/chef-tls'

case node['platform']
when 'ubuntu'
  default[id]['local_certificate_store_dir'] = '/usr/local/share/ca-certificates'
  default[id]['system_certificate_store_dir'] = '/etc/ssl/certs'
else
  default[id]['local_certificate_store_dir'] = nil
  default[id]['system_certificate_store_dir'] = nil
end
