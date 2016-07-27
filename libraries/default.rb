module ChefCookbook
  class TLS
    def initialize(node)
      @node = node
    end

    class CertificateEntry
      def initialize(node, domain, data)
        @node = node
        @data = data

        if @data.fetch('name', nil).nil?
          ::Chef::Log.warn(
            "No name specified in TLS certificate item for domain <#{domain}> in "\
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
        ::File.join @node['tls']['base_dir'], name
      end

      def certificate_path
        ::File.join base_dir, 'server.crt'
      end

      def certificate_data
        @data['chain'].join "\n"
      end

      def certificate_private_key_path
        ::File.join base_dir, 'server.key'
      end

      def certificate_private_key_data
        @data['private_key']
      end

      def scts_data
        @data.fetch('scts', {})
      end

      def scts_dir
        ::File.join base_dir, 'scts'
      end

      def hpkp_pins
        @data.fetch('hpkp_pins', [])
      end
    end

    def certificate_entry(domain)
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

      data = tls_certificates_list.find do |item|
        item.fetch('domains', []).include? domain
      end

      if data.nil?
        ::Chef::Application.fatal!(
          "Couldn't find TLS certificate item for domain <#{domain}> in data "\
          "bag <#{@node['tls']['data_bag_name']}::#{@node.chef_environment}>!",
          99
        )
      else
        CertificateEntry.new @node, domain, data
      end
    end
  end
end
