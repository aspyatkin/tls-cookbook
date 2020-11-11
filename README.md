# tls-cookbook
[![Chef cookbook](https://img.shields.io/cookbook/v/tls.svg?style=flat-square)]()
[![license](https://img.shields.io/github/license/aspyatkin/tls-cookbook.svg?style=flat-square)]()  
Chef cookbook to deploy TLS certificates (including root ones) on a system. Certificate files are placed under a directory specified in attribute `node['tls']['base_dir']` (by default `/etc/chef-tls`). Root certificate files are placed under system directories.

Certificate & private key data is stored either in an [encrypted data bag](https://docs.chef.io/data_bags/) or in HashiCorp's [Vault](https://www.hashicorp.com/products/vault).

## Encrypted data bag format

Data is stored in the encrypted data bag which name is specified in the attribute `node['tls']['data_bag_name']` (by default `tls`). Data bag item name matches `node.chef_environment` value.

``` json
{
  "id": "development",
  "ca_certificates": {
    // Trusted Root CA
    // "name": "----- certificate data -----"
    "Custom_CA": "-----BEGIN CERTIFICATE-----\nMIIF0jCC........UwhJJgNX\n-----END CERTIFICATE-----",
    // other entries
  },
  "certificates": [
    {
      "name": "domain.tld-rsa", // Certificate name (optional)
      "domains": [ // Domain list
        "domain.tld",
        "www.domain.tld"
      ],
      "chain": [ // Certificate chain (from leaf to root, PEM encoded, new lines should be escaped)
        "-----BEGIN CERTIFICATE-----\nMIIFNjCC........4PcGNXXA\n-----END CERTIFICATE-----",
        "-----BEGIN CERTIFICATE-----\nMIIEkjCC........NFu0Qg==\n-----END CERTIFICATE-----"
      ],
      "private_key": "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIB........8tt8JA==\n-----END RSA PRIVATE KEY-----" // Certificate private key (PEM encoded, new lines should be escaped)
    },
    {
      // other entries
    }
  ]
}
```

## Vault format (version 1)

Each certificate entry is supposed to be placed at path `<prefix>/certificate>/<entry_name>` and will be obtained by [vlt](https://supermarket.chef.io/cookbooks/vlt) client. A Chef node must claim a role with read and list permissions for `<prefix>/data/certificate/*` and `<prefix>/metadata/certificate` accordingly. The format is the following:

``` json
{
  "domains": [ // Domain list
    "domain.tld",
    "www.domain.tld"
  ],
  "chain": [ // Certificate chain (from leaf to root, PEM encoded, new lines should be escaped)
    "-----BEGIN CERTIFICATE-----\nMIIFNjCC........4PcGNXXA\n-----END CERTIFICATE-----",
    "-----BEGIN CERTIFICATE-----\nMIIEkjCC........NFu0Qg==\n-----END CERTIFICATE-----"
  ],
  "private_key": "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIB........8tt8JA==\n-----END RSA PRIVATE KEY-----" // Certificate private key (PEM encoded, new lines should be escaped)
}
```

Each CA certificate entry is supposed to be placed at path `<prefix>/ca_certificate>/<ca_entry_name>` and will be obtained by [vlt](https://supermarket.chef.io/cookbooks/vlt) client. A Chef node must claim a role with read permissions for `<prefix>/data/ca_certificate/*`. The format is the following:

```json
{
  "data": "-----BEGIN CERTIFICATE-----\nMIIF0jCC........UwhJJgNX\n-----END CERTIFICATE-----"
}
```

# Vault format (version 2)
CA certificate entry format stays the same as of version 1.

Each certificate entry is supposed to be placed at path `<prefix>/certificate>/<entry_name>` and will be obtained by [vlt](https://supermarket.chef.io/cookbooks/vlt) client. A Chef node must claim a role with read permissions for each `<prefix>/data/certificate/<entry_name>` or `<prefix>/data/certificate/*`. The format is the following:

``` json
{
  "chain": [ // Certificate chain (from leaf to root, PEM encoded, new lines should be escaped)
    "-----BEGIN CERTIFICATE-----\nMIIFNjCC........4PcGNXXA\n-----END CERTIFICATE-----",
    "-----BEGIN CERTIFICATE-----\nMIIEkjCC........NFu0Qg==\n-----END CERTIFICATE-----"
  ],
  "private_key": "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIB........8tt8JA==\n-----END RSA PRIVATE KEY-----" // Certificate private key (PEM encoded, new lines should be escaped)
}
```

In comparison to version 1, there is no `domains` field. Instead, domain lists are placed into an index entry at `<prefix>/certificate/index` (a chef node must claim a role with read permissions for `<prefix>/data/certificate/index`), which has the following format:

```json
{
  "rsa": {
    "entry1_name": [
      "domain1.tld",
      "domain2.tld"
    ],
    "entry2_name": [
      "domain3.tld",
      "*.domain3.tld"
    ]
  },
  "ecc": {
    "entry1_name_ecc": [
      "domain1.tld",
      "domain2.tld"
    ],
    "entry2_name_ecc": [
      "domain3.tld",
      "*.domain3.tld"
    ]
  }
}
```

The example above defines 4 certificate entries:
- `<prefix>/certificate/entry1_name` (RSA for `domain1.tld` and `domain2.tld`)
- `<prefix>/certificate/entry2_name` (RSA for `domain3.tld` and `*.domain3.tld`)
- `<prefix>/certificate/entry1_name_ecc` (ECC for `domain1.tld` and `domain2.tld`)
- `<prefix>/certificate/entry2_name_ecc` (ECC for `domain3.tld` and `*.domain3.tld`)

## Resources

### tls_certificate

Certificate deployment is made by using `tls_certificate` resource. For example,

``` ruby
tls_vlt = ::Vlt::Client.new(::Vlt.file_auth_provider, 'tls')
tls_vlt_provider = lambda { tls_vlt }

tls_certificate 'www.domain.tld' do
  vlt_provider tls_vlt_provider  # required only when Vault is used
  vlt_format 2  # defaults to 1
  action :deploy
end
```

Different software (e.g. Nginx, Postfix) will require paths to deployed certificates and private keys. To obtain these paths, `::ChefCookbook::TLS` helper should be used. Below is the example:

``` ruby
tls_item = ::ChefCookbook::TLS.new(node).certificate_entry('www.domain.tld', vlt_provider: tls_vlt_provider, vlt_format: 2)  # vlt_provider is required only when Vault is used, vlt_format defaults to 1

tls_item.certificate_path  # Get path to the certificate
tls_item.certificate_checksum  # Get certificate's CRC32
tls_item.certificate_private_key_path  # Get path to the certificate's private key
tls_item.certificate_private_key_checksum  # Get private key's CRC32
```

If there are several certificates for the same set of domains (e.g. RSA and ECDSA ones), both `tls_certificate` resource and `certificate_entry` helper method will operate with the first item found in the data bag. To pick out the exact certificate, you should use either `tls_rsa_certificate` resource / `rsa_certificate_entry` helper method or `tls_ec_certificate` resource / `ec_certificate_entry` helper method.

### tls_rsa_certificate

``` ruby
tls_rsa_certificate 'www.domain.tld' do
  action :deploy
end

tls_item = ::ChefCookbook::TLS.new(node).rsa_certificate_entry('www.domain.tld')
```

### tls_ec_certificate

``` ruby
tls = ::ChefCookbook::TLS.new(node)

if tls.has_ec_certificate?('www.domain.tld')
  tls_ec_certificate 'www.domain.tld' do
    action :deploy
  end

  tls_item = tls.ec_certificate_entry('www.domain.tld')
end
```

### tls_ca_certificate
Installing/uninstalling CA certificates only works on Ubuntu systems.
To obtain path to CA certificate bundle, `::ChefCookbook::TLS` helper should be used. Below is the example:

``` ruby
tls_helper = ::ChefCookbook::TLS.new(node)

tls_helper.ca_bundle_path  # Get CA certificate bundle path
```

#### Installing

``` ruby
tls_ca_certificate 'Custom_CA' do
  action :install
end
```

#### Uninstalling

``` ruby
tls_ca_certificate 'Custom_CA' do
  action :uninstall
end
```

## License
MIT @ [Alexander Pyatkin](https://github.com/aspyatkin)
