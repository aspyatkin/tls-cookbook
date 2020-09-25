require 'base64'

resource_name :tls_certificate

property :domain, String, name_property: true
property :owner, String, default: 'root'
property :group, String, default: node['root_group']
property :key_type, [Symbol, nil], default: nil

property :vlt_provider, Proc, default: lambda { nil }

default_action :deploy

action :deploy do
  helper = ::ChefCookbook::TLS.new(node, vlt_provider: new_resource.vlt_provider)

  actual_item = helper.certificate_entry(new_resource.domain, new_resource.key_type)

  directory node['tls']['base_dir'] do
    owner 'root'
    group node['root_group']
    mode 0o755
    recursive true
    action :create
  end

  directory actual_item.base_dir do
    owner new_resource.owner
    group new_resource.group
    mode 0o755
    recursive true
    action :create
  end

  file actual_item.certificate_path do
    owner new_resource.owner
    group new_resource.group
    mode 0o644
    content actual_item.certificate_data
    sensitive true
    action :create
  end

  file actual_item.certificate_private_key_path do
    owner new_resource.owner
    group new_resource.group
    mode 0o600
    content actual_item.certificate_private_key_data
    sensitive true
    action :create
  end
end
