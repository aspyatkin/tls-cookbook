resource_name :tls_rsa_certificate

property :domain, String, name_property: true
property :owner, String, default: 'root'
property :group, String, default: node['root_group']

default_action :deploy

action :deploy do
  tls_certificate "Deploy RSA certificate for #{new_resource.domain}" do
    domain new_resource.domain
    owner new_resource.owner
    group new_resource.group
    key_type :rsa
    action :deploy
  end
end
