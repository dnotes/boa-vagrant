Chef::Log.debug("Running barracuda recipe")

execute "add vagrant user to users group" do
  command "usermod -aG users vagrant"
end

execute "Create ssh key for root" do
  command 'cat /dev/zero | ssh-keygen -q -N ""'
  creates '/root/.ssh/id_rsa.pub'
end

template "/root/.ssh/authorized_keys" do
  source "authorized_keys.erb"
  owner "root"
  group "root"
  mode 0600
end

remote_file "/root/BOA.sh" do
  source "http://files.aegir.cc/BOA.sh.txt"
  owner "root"
  group "root"
  mode 00744
end

#execute "Install linux headers to allow guest additions to update properly" do
#  command "apt-get install dkms build-essential linux-headers-generic -y"
#end

execute "update package index" do
  command "apt-get update"
  ignore_failure true
  action :nothing
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end.run_action(:run)

user "o1" do
  supports :manage_home => true
  home "/data/disk/o1"
  shell "/bin/bash"
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

directory "/data/disk/o1/.ssh" do
  owner "o1"
  group "users"
  mode 00700
  recursive true
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

execute "Add ssh key to user" do
  command "ssh-keygen -b 4096 -t rsa -N \"\" -f /data/disk/o1/.ssh/id_rsa"
  creates "/data/disk/o1/.ssh/id_rsa"
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

file "/data/disk/o1/.ssh/id_rsa" do
  owner "o1"
  group "users"
  mode 00600
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

file "/data/disk/o1/.ssh/id_rsa.pub" do
  owner "o1"
  group "users"
  mode 00600
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end  

# Rebuild VirtualBox Guest Additions
# http://vagrantup.com/v1/docs/troubleshooting.html
#execute "Rebuild VirtualBox Guest Additions" do
#  command "sudo /etc/init.d/vboxadd setup"
#end

template "/etc/postfix/main.cf" do
  source "main.erb"
  owner "root"
  group "root"
  mode 0644
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

template "/etc/postfix/mydestinations" do
  source "mydestinations.erb"
  owner "root"
  group "root"
  mode 0644
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

template "/data/disk/o1/testsite" do
  source "testsite.erb"
  owner "o1"
  group "users"
  mode 0744
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

template "/etc/hosts" do
  source "hosts.erb"
  owner "root"
  group "root"
  mode 0644
end

# Turn off open_basedir so that simpletests will run - see https://drupal.org/comment/6491078#comment-6491078
execute "Turn off open_basedir" do
  cwd "/opt/php56/etc/"
  command "sed -i 's/^open_basedir/;open_basedir/g' ./php56.ini"
  cwd "/opt/php70/etc/"
  command "sed -i 's/^open_basedir/;open_basedir/g' ./php70.ini"
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

# Install alpine for reading mail
execute "Install alpine" do
  command "apt-get install alpine -y"
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

# We need a vanilla drush : https://www.drupal.org/node/2226337#comment-8620107
# Install vanilla drush6
# Symlink vanilla drush6


# xDebug
execute "Install php-pear" do
  command "apt-get install php-pear -y"
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

execute "Install xdebug in php70" do
  command "pecl install -R /opt/php70 xdebug"
  creates "/usr/lib/php5/20131226/xdebug.so"
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

template "/root/xdebug.ini" do
  source "xdebug.erb"
  owner "root"
  group "root"
  mode 0644
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

template "/root/xdebug-sed.txt" do
  source "xdebug-sed.erb"
  owner "root"
  group "root"
  mode 0644
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

execute "Add xdebug to php70" do
  cwd "/opt/php70/etc"
  command "sed -i -f /root/xdebug-sed.txt php70.ini"
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

execute "Reload php70" do
  command "sudo service php70-fpm reload"
  only_if do ::File.exists?('/root/.o1.octopus.cnf') end
end

log "/tmp/BOA.sh" do
  message "Please login as root and run 'cd;bash BOA.sh.txt;'"
  level :info
  not_if do ::File.exists?('/root/.barracuda.cnf') end
end

log "Run the BOA Installer o1" do
  message "Please login as root and run 'boa in-stable local vagrant@aegir.local none php-7.0'"
  level :info
  not_if do ::File.exists?('/root/.o1.octopus.cnf') end
end
