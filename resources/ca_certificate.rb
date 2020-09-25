resource_name :tls_ca_certificate
provides :tls_ca_certificate

property :name, String, name_property: true
property :vlt_provider, Proc, default: lambda { nil }

default_action :install

action :install do
  helper = ::ChefCookbook::TLS.new(node, vlt_provider: new_resource.vlt_client_provider)

  actual_item = helper.ca_certificate_entry(new_resource.name)

  file actual_item.certificate_path do
    owner 'root'
    group node['root_group']
    mode 0o644
    content actual_item.certificate_data
    sensitive true
    action :create
    notifies :run,
             "execute[install CA certificate <#{actual_item.name}>]",
             :immediately
  end

  execute "install CA certificate <#{actual_item.name}>" do
    command 'update-ca-certificates --fresh'
    user 'root'
    group node['root_group']
    action :nothing
  end
end

action :uninstall do
  helper = ::ChefCookbook::TLS.new(node, vlt_provider: new_resource.vlt_client_provider)

  actual_item = helper.ca_certificate_entry new_resource.name

  file actual_item.certificate_path do
    action :delete
    notifies :run,
             "execute[uninstall CA certificate <#{actual_item.name}>]",
             :immediately
  end

  execute "uninstall CA certificate <#{actual_item.name}>" do
    command 'update-ca-certificates --fresh'
    user 'root'
    group node['root_group']
    action :nothing
  end
end
