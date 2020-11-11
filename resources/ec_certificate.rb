resource_name :tls_ec_certificate
provides :tls_ec_certificate

property :domain, String, name_property: true
property :owner, String, default: 'root'
property :group, String, default: node['root_group']

property :vlt_provider, Proc, default: lambda { nil }
property :vlt_format, Integer, default: 1

default_action :deploy

action :deploy do
  tls_certificate "Deploy ECDSA certificate for #{new_resource.domain}" do
    domain new_resource.domain
    owner new_resource.owner
    group new_resource.group
    key_type :ec
    vlt_provider new_resource.vlt_provider
    vlt_format new_resource.vlt_format
    action :deploy
  end
end
