
Vagrant.configure('2') do |config|

    config.vm.provider :linode do |provider, override|

        override.vm.box = 'linode'
        override.vm.box_url = "https://github.com/displague/vagrant-linode/raw/master/box/linode.box"

        ## SSH Configuration
        override.ssh.username = ENV['LINODE_SSH_USER']
        override.ssh.private_key_path = ENV['LINODE_SSH_KEY_LOCATION']
        override.ssh.port = ENV['LINODE_SSH_PORT']

        #Linode Settings
        provider.token = ENV['LINODE_API_KEY']
        provider.distribution = 'Debian 8'
        provider.datacenter = 'london'
        provider.plan = '2048'
        provider.label = ENV['LINODE_HOSTNAME']

    end

    config.vm.provision "shell", run: "always" do |shell|
        shell.path = 'init.sh'
        shell.env = Hash(ENV)
    end

    config.vm.provision "ansible" do |ansible|
        ansible.playbook = 'ansible/playbook.yml'
        ansible.inventory_path = ENV['ANSIBLE_INVENTORY']
        ansible.extra_vars = Hash(ENV)
    end
end
