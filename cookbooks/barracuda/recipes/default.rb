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
  command "boa in-stable local vagrant@localhost mini o1"
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

 # Only necessary as long as there is a need for it
remote_file "/tmp/fix-remote-import-hostmaster-iaminaweoctopus.patch" do
  source "https://raw.github.com/dnotes/boa-vagrant/master/patches/fix-remote-import-hostmaster-iaminaweoctopus.patch"
  mode 00755
end

execute "Apply Remote Import hostmaster patch" do
  cwd "/data/disk/o1/.drush/provision/remote_import"
  command "patch -p1 < /tmp/fix-remote-import-hostmaster-iaminaweoctopus.patch"
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
  group "o1"
  mode 0744
end

# Install alpine for reading mail
execute "Install alpine" do
  command "sudo apt-get install alpine"
end
