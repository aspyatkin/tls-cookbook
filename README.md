# tls-cookbook
[![Chef cookbook](https://img.shields.io/cookbook/v/tls.svg?style=flat-square)]()
[![license](https://img.shields.io/github/license/aspyatkin/tls-cookbook.svg?style=flat-square)]()  
Chef cookbook to deploy SSL/TLS certificates (including root ones) on a system. Data is stored in the encrypted data bag which name is specified in the attribute `node['tls']['data_bag_name']` (by default `tls`). Data bag item name matches `node.chef_environment` value.

Certificate files will be placed under the directory specified in attribute `node['tls']['base_dir']` (by default `/etc/chef-tls`).

Root certificate files will be placed under system directories.

## Encrypted data bag format

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

## Resources

### tls_certificate

Certificate deployment is made by using `tls_certificate` resource. For example,

``` ruby
tls_certificate 'www.domain.tld' do
  action :deploy
end
```

Different software (e.g. Nginx, Postfix) will require paths to deployed certificates and private keys. To obtain these paths, `::ChefCookbook::TLS` helper should be used. Below is the example:

``` ruby
tls_item = ::ChefCookbook::TLS.new(node).certificate_entry('www.domain.tld')

tls_item.certificate_path  # Get path to the certificate
tls_item.certificate_private_key_path  # Get path to the certificate's private key
```

If there are several certificates for the same set of domains (e.g. RSA and ECDSA ones), both `tls_certificate` resource and `certificate_entry` helper method will operate with the first item found in the data bag. To pick out the exact certificate, you should use either `tls_rsa_certificate` resource / `rsa_certificate_entry` helper method or `tls_ec_certificate` resource / `ec_certificate_entry` helper method.

### tls_rsa_certificate

``` ruby
tls_rsa_certificate 'www.domain.tld' do
  action :deploy
end
```

``` ruby
tls_item = ::ChefCookbook::TLS.new(node).rsa_certificate_entry('www.domain.tld')
```

### tls_ec_certificate

``` ruby
tls_ec_certificate 'www.domain.tld' do
  action :deploy
end
```

``` ruby
tls_item = ::ChefCookbook::TLS.new(node).ec_certificate_entry('www.domain.tld')
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
