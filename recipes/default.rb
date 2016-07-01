id = 'tls'

directory node[id]['base_dir'] do
  owner 'root'
  group node['root_group']
  mode 0755
  recursive true
  action :create
end
