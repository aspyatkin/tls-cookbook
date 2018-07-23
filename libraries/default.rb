require 'openssl'

module ChefCookbook
  class TLS
    def initialize(node)
      @node = node
    end

    class CertificateEntry
      def initialize(node, domains, data)
        @node = node
        @data = data

        if @data.fetch('name', nil).nil?
          ::Chef::Log.warn(
            "No name specified in TLS certificate item for domains <#{domains.join(' ')}> in "\
            "data bag <#{@node['tls']['data_bag_name']}::#{@node.chef_environment}>. "\
            "Using <#{@data['domains'][0]}> as a name."
          )
          @data['name'] = @data['domains'][0]
        end

        if @data.fetch('chain', []).empty?
          ::Chef::Application.fatal!(
            'No certificates are specified for TLS certificate item '\
            "<#{name}> in data bag "\
            "<#{@node['tls']['data_bag_name']}::#{@node.chef_environment}>!",
            99
          )
        end

        if @data.fetch('private_key', nil).nil?
          ::Chef::Application.fatal!(
            'No private key is specified for TLS certificate item '\
            "<#{name}> in data bag "\
            "<#{@node['tls']['data_bag_name']}::#{@node.chef_environment}>!",
            99
          )
        end
      end

      def name
        @data['name']
      end

      def base_dir
        ::File.join(@node['tls']['base_dir'], name)
      end

      def certificate_path
        ::File.join(base_dir, 'server.crt')
      end

      def certificate_data
        @data['chain'].join("\n")
      end

      def certificate_private_key_path
        ::File.join(base_dir, 'server.key')
      end

      def certificate_private_key_data
        @data['private_key']
      end

      def scts_data
        @data.fetch('scts', {})
      end

      def has_scts?
        !scts_data.empty?
      end

      def scts_dir
        ::File.join(base_dir, 'scts')
      end

      def hpkp_pins
        @data.fetch('hpkp_pins', [])
      end
    end

    def _wildcard?(s)
      s.start_with?('*.')
    end

    def _wilcardize(s)
      s.split('.').each_with_index.map { |x, ndx| (ndx == 0) ? '*' : x }.join('.')
    end

    def _subset?(a, b)
      a.all? { |x| b.include?(x) || (!_wildcard?(x) && b.include?(_wilcardize(x))) }
    end

    def certificate_entry(domains, key_type = nil)
      tls_data_bag_item = nil
      begin
        tls_data_bag_item = ::Chef::EncryptedDataBagItem.load(
          @node['tls']['data_bag_name'],
          @node.chef_environment
        )
      rescue
      end

      tls_certificates_list = \
        if tls_data_bag_item.nil?
          []
        else
          tls_data_bag_item.to_hash.fetch('certificates', [])
        end

      unless domains.is_a?(Array)
        domains = [domains]
      end

      data = tls_certificates_list.find do |item|
        match_domain = _subset?(domains, item.fetch('domains', []))

        if match_domain
          if key_type.nil?
            next true
          else
            begin
              pk = ::OpenSSL::PKey.read(item.fetch('private_key', ''))
              if key_type == :rsa && pk.class == ::OpenSSL::PKey::RSA
                next true
              elsif key_type == :ec && pk.class == ::OpenSSL::PKey::EC
                next true
              else
                next false
              end
            rescue ::OpenSSL::PKey::PKeyError
              ::Chef::Application.fatal!(
                "Couldn't find valid private key in certificate item for domains <#{domains.join(' ')}> in data "\
                "bag <#{@node['tls']['data_bag_name']}::#{@node.chef_environment}>!",
                99
              )
            end
          end
        else
          next false
        end
      end

      if data.nil?
        ::Chef::Application.fatal!(
          "Couldn't find TLS certificate item for domains <#{domains.join(' ')}> in data "\
          "bag <#{@node['tls']['data_bag_name']}::#{@node.chef_environment}>!",
          99
        )
      else
        CertificateEntry.new(@node, domains, data)
      end
    end

    def rsa_certificate_entry(domains)
      certificate_entry(domains, :rsa)
    end

    def ec_certificate_entry(domains)
      certificate_entry(domains, :ec)
    end

    class RootCertificateEntry
      def initialize(node, name, data)
        @node = node
        @_name = name
        @_data = data

        if @node['tls']['local_certificate_store_dir'].nil? ||
           @node['tls']['system_certificate_store_dir'].nil?
          ::Chef::Application.fatal!(
            "Unsupported system <#{@node['platform']}>!",
            99
          )
        end
      end

      def name
        @_name
      end

      def certificate_path
        ::File.join(@node['tls']['local_certificate_store_dir'], "#{name}.crt")
      end

      def certificate_data
        @_data
      end
    end

    def ca_bundle_path
      case @node['platform']
      when 'ubuntu'
        ::File.join(
          @node['tls']['system_certificate_store_dir'],
          'ca-certificates.crt'
        )
      else
        ::Chef::Application.fatal!(
          "Unsupported system <#{@node['platform']}>!",
          99
        )
      end
    end

    def ca_certificate_entry(name)
      tls_data_bag_item = nil
      begin
        tls_data_bag_item = ::Chef::EncryptedDataBagItem.load(
          @node['tls']['data_bag_name'],
          @node.chef_environment
        )
      rescue
      end

      tls_ca_certificates_list = \
        if tls_data_bag_item.nil?
          []
        else
          tls_data_bag_item.to_hash.fetch('ca_certificates', {})
        end

      data = tls_ca_certificates_list[name]

      if data.nil?
        ::Chef::Application.fatal!(
          "Couldn't find TLS CA certificate item <#{name}> in data "\
          "bag <#{@node['tls']['data_bag_name']}::#{@node.chef_environment}>!",
          99
        )
      else
        RootCertificateEntry.new(@node, name, data)
      end
    end
  end
end
