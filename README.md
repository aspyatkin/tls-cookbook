# tls-cookbook
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
      "domains": [ // Domain list
        "domain.tld",
        "www.domain.tld"
      ],
      "chain": [ // Certificate chain (from leaf to root, PEM encoded, new lines should be escaped)
        "-----BEGIN CERTIFICATE-----\nMIIFNjCC........4PcGNXXA\n-----END CERTIFICATE-----",
        "-----BEGIN CERTIFICATE-----\nMIIEkjCC........NFu0Qg==\n-----END CERTIFICATE-----"
      ],
      "private_key": "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIB........8tt8JA==\n-----END RSA PRIVATE KEY-----", // Certificate private key (PEM encoded, new lines should be escaped)
      "hpkp_pins": [ // HPKP pins (base64 encoded)
        "wZgbeR6b........",
        "bDSe0744........"
      ],
      "scts": { // SCTs (base64 encoded)
        "google_aviator": "AGj2mPgf........3nYNtNU=",
        "google_pilot": "AKS5CZC0........RnySxdE=",
        "google_rocketeer": "AO5Lvbd1........bdC+zlI="
      }
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

Different software (e.g. Nginx, Postfix) will require paths to deployed certificates, private keys and SCTs. To obtain these paths, `::ChefCookbook::TLS` helper should be used. Below is the example:

``` ruby
tls_item = ::ChefCookbook::TLS.new(node).certificate_entry 'www.domain.tld'

tls_item.certificate_path  # Get path to the certificate
tls_item.certificate_private_key_path  # Get path to the certificate's private key
tls_item.scts_dir  # Get path to the folder with deployed SCTs
tls_item.hpkp_pins  # Get array of HPKP pins
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
