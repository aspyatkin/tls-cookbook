resource_name :tls_ec_certificate

property :domain, String, name_property: true
property :owner, String, default: 'root'
property :group, String, default: node['root_group']

property :vlt_provider, Proc, default: lambda { nil }

default_action :deploy

action :deploy do
  tls_certificate "Deploy ECDSA certificate for #{new_resource.domain}" do
    domain new_resource.domain
    owner new_resource.owner
    group new_resource.group
    key_type :ec
    vlt_provider new_resource.vlt_provider
    action :deploy
  end
end
