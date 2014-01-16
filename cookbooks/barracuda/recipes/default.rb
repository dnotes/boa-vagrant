Chef::Log.debug("Running barracuda recipe")

execute "update package index" do
   command "apt-get update"
   ignore_failure true
   action :nothing
end.run_action(:run)

execute "Install linux headers to allow guest additions to update properly" do
 command "apt-get install dkms build-essential linux-headers-generic -y"
end

remote_file "/tmp/BOA.sh" do
  source "http://files.aegir.cc/BOA.sh.txt"
  mode 00755
end

execute "/tmp/BOA.sh" do
  creates "/usr/local/bin/boa"
end

execute "Run the BOA Installer o1" do
  command "boa in-stable local nobody@example.com mini o1"
end

user "o1" do
  supports :manage_home => true
  home "/data/disk/o1"
  shell "/bin/bash"
end

directory "/data/disk/o1/.ssh" do
  owner "o1"
  group "users"
  mode 00700
  recursive true
end

execute "Add ssh key to user" do
  command "ssh-keygen -b 4096 -t rsa -N \"\" -f /data/disk/o1/.ssh/id_rsa"
  creates "/data/disk/o1/.ssh/id_rsa"
end

file "/data/disk/o1/.ssh/id_rsa" do
  owner "o1"
  group "users"
  mode 00600
end

file "/data/disk/o1/.ssh/id_rsa.pub" do
  owner "o1"
  group "users"
  mode 00600
end  

# Rebuild VirtualBox Guest Additions
# http://vagrantup.com/v1/docs/troubleshooting.html
execute "Rebuild VirtualBox Guest Additions" do
  command "sudo /etc/init.d/vboxadd setup"
end

template "/etc/postfix/main.cf" do
  source "main.erb"
  owner "root"
  group "root"
  mode 0644
end

template "/etc/postfix/mydestinations" do
  source "mydestinations.erb"
  owner "root"
  group "root"
  mode 0644
end

template "/data/disk/o1/testsite" do
  source "testsite.erb"
  owner "o1"
  group "users"
  mode 0744
end

template "/etc/hosts" do
  source "hosts.erb"
  owner "root"
  group "root"
  mode 0644
end

# Turn off open_basedir so that simpletests will run - see https://drupal.org/comment/6491078#comment-6491078
execute "Turn off open_basedir in php53" do
  cwd "/opt/local/etc/"
  command "sed -i 's/^open_basedir/;open_basedir/g' ./php53.ini"
end

execute "Reload php53" do
  command "sudo service php53-fpm reload"
end

# Install alpine for reading mail
execute "Install alpine" do
  command "sudo apt-get install alpine"
end
