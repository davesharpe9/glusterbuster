# -*- mode: ruby -*-
# vi: set ft=ruby :

$proxyscript = <<EOF
sudo apt-get -y install puppet
cd /vagrant/source/mitmproxy
./mitmkeygen
EOF

paramsfile="params.conf"
dir=File.dirname(__FILE__) 

params = Hash[*File.read(dir+"/"+paramsfile).split(/=|\n/)]

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "dummy"

  config.vm.provider :aws do |aws, override|
    aws.access_key_id = params['AWS_ACCESS_KEY_ID']
    aws.secret_access_key = params['AWS_SECRET_ACCESS_KEY']
    aws.keypair_name = params['KEYPAIR_NAME']
    aws.ami = params['AMI']
    aws.region = params['AWS_DEFAULT_REGION']
    aws.availability_zone = params['AZ']
    aws.subnet_id = params['SUBNET']
    aws.instance_type = params['INSTANCE_TYPE']

    override.ssh.username = "ubuntu"
    override.ssh.private_key_path = params['KEY_PATH']

  end

  config.vm.define 'candidate' do |candidate|
    candidate.vm.synced_folder '.', '/vagrant', :rsync_excludes => ['params.conf'] 
    candidate.vm.provider :aws do |aws|
      aws.elastic_ip = true
      aws.security_groups = [params['SGMISC']]
      aws.tags = {
        'Name' => params['MYUID']+'-candidate'
      }
    end
    candidate.vm.provision "shell",
      inline: "apt-get -y install puppet"
    
    candidate.vm.provision "puppet" do |puppet|
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "candidate.pp"
    end
  end

  config.vm.define 'proxy' do |proxy|
    proxy.vm.synced_folder '.', '/vagrant', :rsync_excludes => ['params.conf'] 
    proxy.vm.provider :aws do |aws|
      aws.elastic_ip = true
      aws.security_groups = [params['SGMISC']]
       aws.tags = {
        'Name' => params['MYUID']+'-proxy'
      }
    end
    proxy.vm.provision "shell" do |s|
      s.privileged = false
      s.inline = $proxyscript
    end
    
    proxy.vm.provision "puppet" do |puppet|
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "proxy.pp"
    end
  end

end
