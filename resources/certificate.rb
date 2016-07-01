id = 'tls'
resource_name :tls_certificate

property :domain, String, name_property: true
property :owner, String, default: 'root'
property :group, String, default: node['root_group']

default_action :deploy

action :deploy do
  helper = ChefCookbook::TLS.new node

  actual_item = helper.certificate_entry domain

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
    action :create
  end

  file actual_item.certificate_private_key_path do
    owner new_resource.owner
    group new_resource.group
    mode 0600
    content actual_item.certificate_private_key_data
    action :create
  end
end
