# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'uri'

VAGRANFILE_API_VERSION = '2'
TOP_LEVEL_DOMAIN       = 'test'
SCM_REMOTE_ORIGIN_URI  = URI.parse(`git config --get remote.origin.url`.strip!)
SCM_BRANCH             = `git rev-parse --abbrev-ref HEAD`.downcase.tr("/", "-").tr(".", "-").strip!

if SCM_REMOTE_ORIGIN_URI.path.start_with?('/') then
    SCM_REMOTE_ORIGIN_PATH = SCM_REMOTE_ORIGIN_URI.path[1..-1].gsub('.git', '')
else
    SCM_REMOTE_ORIGIN_PATH = SCM_REMOTE_ORIGIN_URI.path.gsub('.git', '')
end

PROJECT        = SCM_REMOTE_ORIGIN_PATH.tr("/", "-")
PROJECT_KEY    = PROJECT.tr(".", "-") + '-' + SCM_BRANCH
PROJECT_DOMAIN = PROJECT_KEY + '.' + TOP_LEVEL_DOMAIN

if Vagrant::Util::Platform.windows? then
    NETRC            = `for /f "tokens=2" %a in ('type \"%userprofile%\\.netrc\" ^| findstr /v "git.kistner-media.de"') do @echo %a`
    GIT_CREDENTIALS  = NETRC.split(/\n+/)
    GIT_USER         = GIT_CREDENTIALS[0]
    GIT_PASS         = GIT_CREDENTIALS[1]
else
    GIT_USER         = `awk '/git.kistner-media.de/{getline; print $2; exit;}' $HOME/.netrc`
    GIT_PASS         = `awk '/git.kistner-media.de/{getline; getline; print $2; exit;}' $HOME/.netrc`

    `if [ -f $HOME/.composer/auth.json ] && [ ! -d ./.composer ]; then mkdir ./.composer/ && cp $HOME/.composer/auth.json ./.composer/; fi;`
end

################################################
#      Add variables for provisioned check     #
################################################
isBoxProvisioned = File.exists?(File.join(File.dirname(__FILE__),".vagrant/machines/default/virtualbox/id"));

Vagrant.configure(VAGRANFILE_API_VERSION) do |config|
    config.vagrant.plugins     = ["vagrant-hostmanager", "vagrant-vbguest"]
    config.vbguest.auto_update = false

    ###############################################################
    #                Configure the virtual machine                #
    ###############################################################
    config.vm.provider "virtualbox" do |v|
        if (not isBoxProvisioned)
            v.name = PROJECT_KEY
        end
        v.memory = 4096
        v.cpus   = 4
    end

    ###############################################################
    #        We use debian in production and so we do here        #
    ###############################################################
    config.vm.box = "el8ctric/docker"
    config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

    ###############################################################
    #          DNS config and create a private network,           #
    #          which allows host-only access to machine           #
    ###############################################################
    if (not isBoxProvisioned)
        config.vm.hostname = PROJECT_KEY
    end

    config.hostmanager.enabled           = false
    config.hostmanager.manage_host       = true
    config.hostmanager.ignore_private_ip = false

    config.vm.network 'private_network', type: :dhcp

    config.hostmanager.aliases     = [PROJECT_DOMAIN, 'dash.' + PROJECT_DOMAIN, 'mysql.' + PROJECT_DOMAIN, 'proc.' + PROJECT_DOMAIN]
    config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
        vm.provider.driver.read_guest_ip(1)
    end

    config.vm.provision :shell,
        :path => 'vagrant/setup.sh',
        :args => [GIT_USER, GIT_PASS, PROJECT_DOMAIN]

    ### This needs to be set after all docker / k3s stuff is up as otherwise we get an wrong IP
    if (not isBoxProvisioned)
        config.vm.provision :hostmanager
    end
end
