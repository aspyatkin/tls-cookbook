name 'tls'
maintainer 'Alexander Pyatkin'
maintainer_email 'aspyatkin@gmail.com'
license 'MIT'
description 'Deploy SSL/TLS certificates'
long_description ::IO.read(::File.join(::File.dirname(__FILE__), 'README.md'))
version '1.0.1'

recipe 'tls', 'Deploy SSL/TLS certificates'

source_url 'https://github.com/aspyatkin/tls-cookbook' if respond_to?(:source_url)
issues_url 'https://github.com/aspyatkin/tls-cookbook/issues' if respond_to?(:issues_url)
