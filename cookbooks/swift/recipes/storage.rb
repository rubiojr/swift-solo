#
# Sergio Rubio <rubiojr@frameos.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'swift::default'

Chef::Log.info("START Storage Recipe")

storage_ip = Evaluator.get_ip_by_type(node, :storage_ip_expr)
log_level = 'INFO'

%w{ swift-account xfsprogs swift-container swift-object sqlite }.each do |pkg|
  package pkg do
    action :upgrade
    options "--force-yes"
  end
end

%w{account object container}.each do |service_name|
  cookbook_file "/etc/init/swift-#{service_name}.conf" do
    source "swift-#{service_name}.init.conf"
    mode "0644"
  end
end

bash "create storage" do
  code <<-EOH
    dd if=/dev/zero of=/srv/swift-disk bs=1M count=0 seek=20000
    mkfs.xfs -f -i size=1024 /srv/swift-disk
    mkdir -p /srv/node/sdb1
    mount /srv/swift-disk /srv/node/sdb1
    mkdir -p /var/run/swift
  EOH
  not_if { File.exist?("/srv/swift-disk") } 
end

# create the swift config files
#%w{account-server object-server container-server}.each do |service|
%w{account object container}.each do |service_name|
  service_config_name = service_name + "-server"
  template "/etc/swift/#{service_config_name}.conf" do
    source "#{service_config_name}-conf.erb"
    owner "swift"
    group "swift"
    variables({ 
      :uid => node[:swift][:user],
      :gid => node[:swift][:group],
      :storage_net_ip => storage_ip,
      :workers => node[:cpu][:total],  ## could allow multiple servers on the same machine
      :admin_key => node[:swift][:cluster_admin_pw],
      :log_level => log_level
    })    
    notifies :restart, "service[swift-#{service_name}]"
  end
end

execute "swift permissions on /srv/" do
  command "chown -R swift:swift /srv/node /etc/swift"
end

# this cron job checks for bad drives and unmounts them.  If we're gonna wait a wihle to replace the drive, then
# the operator should remove the drive from the rings until we've got a new one ready.
## Create the drive audit server configuraiton file
cookbook_file "/etc/swift/drive-audit.conf" do
  source "drive-audit.conf"
  mode "0644"
end

cron "swift-disk-audit" do
  minute "12"
  command "/usr/bin/swift-drive-audit /etc/swift/drive-audit.conf"
end

directory "/var/cache/swift" do
  owner "swift"
  group "swift"
  mode "0755"
  action :create
end

file "/var/cache/swift/object.recon" do
  owner "swift"
  group "swift"
  mode "0755"
  action :create
end

cron "swift-recon" do
  minute "*/5"
  user "swift"
  command "/usr/bin/swift-recon-cron /etc/swift/object-server/object-server.conf"
end

# Fetch rings
execute "sync rings from ring-builder" do
  command "rsync -a #{node[:swift][:ring_builder_ip]}::proxy-rings/*.ring.gz /etc/swift/" 
end

execute "swift permissions on /srv/" do
  command "chown -R swift:swift /srv/node /etc/swift"
end

# name each of the service swift-<service>
%w{ account object container }.each { |x| 
  service "swift-#{x}" do
    only_if do
      File.exists?("/etc/swift/#{x}.ring.gz")
    end
    action [:enable, :start]
    provider Chef::Provider::Service::Upstart
  end
}

Chef::Log.info("END Storage Recipe")
