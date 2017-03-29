require 'base64'

resource_name :tls_certificate

property :domain, String, name_property: true
property :owner, String, default: 'root'
property :group, String, default: node['root_group']
property :scts, [TrueClass, FalseClass], default: true
property :key_type, [Symbol, nil], default: nil

default_action :deploy

action :deploy do
  helper = ::ChefCookbook::TLS.new(node)

  actual_item = helper.certificate_entry(domain, new_resource.key_type)

  directory node['tls']['base_dir'] do
    owner 'root'
    group node['root_group']
    mode 0755
    recursive true
    action :create
  end

  directory actual_item.base_dir do
    owner new_resource.owner
    group new_resource.group
    mode 0755
    recursive true
    action :create
  end

  file actual_item.certificate_path do
    owner new_resource.owner
    group new_resource.group
    mode 0600
    content actual_item.certificate_data
    sensitive true
    action :create
  end

  file actual_item.certificate_private_key_path do
    owner new_resource.owner
    group new_resource.group
    mode 0600
    content actual_item.certificate_private_key_data
    sensitive true
    action :create
  end

  if new_resource.scts && !actual_item.scts_data.empty?
    directory actual_item.scts_dir do
      owner new_resource.owner
      group new_resource.group
      mode 0755
      recursive true
      action :create
    end

    actual_item.scts_data.each do |name, data|
      sct_path = ::File.join(actual_item.scts_dir, "#{name}.sct")

      file sct_path do
        owner new_resource.owner
        group new_resource.group
        mode 0644
        content ::Base64.decode64(data)
        sensitive true
        action :create
      end
    end
  end
end
