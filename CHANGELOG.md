# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [4.1.2] - 2020-11-20
### Fixed
- Fix search for certificate entries (Vault format version 2).

## [4.1.1] - 2020-11-16
### Changed
- Improved search for certificate entries (Vault format version 2), so that exact matches will be preferred over wildcards ones.

### Fixed
- Fix unexpectedly broken `tls_ca_certificate` resource.

## [4.1.0] - 2020-11-11
### Added
- Introduce a new and more efficient Vault format (version 2).

## [4.0.1] - 2020-09-28
### Fixed
- Fix Chef 16 support (`provides` for resources).
- Fix FC108 warning.

## [4.0.0] - 2020-09-28
### Added
- Add CHANGELOG and CONTRIBUTING files.
- Add HashiCorp's [Vault](https://www.hashicorp.com/products/vault) support.

### Changed
- Update README.
- Include `chef_version` and `supports` to cookbook metadata.
