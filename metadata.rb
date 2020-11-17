name 'tls'
maintainer 'Alexander Pyatkin'
maintainer_email 'aspyatkin@gmail.com'
license 'MIT'
description 'Deploy TLS certificates'
long_description ::IO.read(::File.join(::File.dirname(__FILE__), 'README.md'))
version '4.1.1'

scm_url = 'https://github.com/aspyatkin/tls-cookbook'
source_url scm_url if respond_to?(:source_url)
issues_url "#{scm_url}/issues" if respond_to?(:issues_url)

chef_version '>= 12.0'

supports 'debian'
supports 'ubuntu'
