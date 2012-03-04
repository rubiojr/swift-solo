#
# Initially based on the proxy recipe from Dell Inc. and
# Andi Abes
#
# Sergio Rubio <rubiojr@frameos.org>
#
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

Chef::Log.info("START Proxy recipe")

include_recipe 'apt'
include_recipe 'swift::default'

storage_ip = Evaluator.get_ip_by_type(node, :storage_ip_expr)
public_ip = Evaluator.get_ip_by_type(node, :admin_ip_expr)

# this is a nice command line script to give you an overview of the
# status of the proxy
cookbook_file "/root/proxy_stats.sh" do
  source "proxy_stats.sh"
  mode "0755"
end

# munin config stuff for all proxies
####################################
####################################

cookbook_file "/etc/munin/plugin-conf.d/traffic_accounting" do
  source "traffic_accounting.conf"
  mode "0644"
  notifies :restart, resources(:service => "munin-node")
end

cookbook_file "/etc/munin/plugins/traffic_accounting" do
  source "traffic_accounting.pl"
  mode "0755"
  notifies :restart, resources(:service => "munin-node")
end

execute "apply_iptables_configs_proxy" do
  cwd "/etc/swift"
  #group node[:swift][:group]
  #user node[:swift][:user]
  command "/bin/bash /etc/swift/iptables_proxy.conf"
  action :nothing
  supports :run => true
  notifies :restart, resources(:service => "munin-node"), :immediately
end

#
# FIXME: we are not using this stuff right now
# HACK
storage_servers = []
# END HACK
## Create the proxy server munin iptables configuraiton file
template "/etc/swift/iptables_proxy.conf" do
  source "iptables_proxy.conf.erb"
  mode "0644"
  group node[:swift][:group]
  owner node[:swift][:user]
  variables( {
       :storage_nodes_ips => storage_servers
  })
  notifies :run, resources(:execute => "apply_iptables_configs_proxy"), :immediately
end

# Install the basics of the Swift Proxy system
##############################################
%w{libxml2-dev libxslt1-dev build-essential memcached swift swift-proxy}.each do |pkg|
  package pkg do
    action :upgrade
    options "--force-yes"
  end
end

#
# we need this for the test-swift script
#
gem_package "fog"

#
# Create the SSL cert
#
execute "create auth cert" do
  cwd "/etc/swift"
  creates "/etc/swift/cert.crt"
  group node[:swift][:group]
  user node[:swift][:user]
  command <<-EOH
  /usr/bin/openssl req -new -x509 -nodes -out cert.crt -keyout cert.key -batch &>/dev/null 0</dev/null
  EOH
  not_if  {::File.exist?("/etc/swift/cert.crt") } 
end

log_level = 'INFO'
if ( node[:swift][:log_level] )
  log_level = node[:swift][:log_level]
end

## Create the memcache server configuraiton file
template "/etc/memcached.conf" do
  source "memcached.conf.erb"
  mode "0644"
  variables( {
       :listen => storage_ip,
       :debug  => node[:swift][:debug],
       :user   => node[:swift][:user],
  })  
end

service "memcached" do
  supports :status => true, :start => true, :stop => true, :restart => true
  action [:enable, :start]
  subscribes :restart, resources(:template => "/etc/memcached.conf")
end

servers = "#{storage_ip}:11211"

#
## Create the proxy server configuraiton file
#
template "/etc/swift/proxy-server.conf" do
  source "proxy-server.conf.erb"
  mode "0644"
  group node[:swift][:group]
  owner node[:swift][:user]
  workers = node[:cpu][:total] * 2
  variables( {
       :admin_key =>     node[:swift][:cluster_admin_pw],
       :memcached_ips => servers,
       :localip =>       public_ip,
       :user =>          node[:swift][:user],
       :log_level =>     log_level,
       :workers =>       workers
  })  
end

#
# Upload a script to test the proxy
#
template "/root/test-swift" do
  source "test-swift.erb"
  mode "0755"
  variables( {
       :localip =>       storage_ip,
  })  
end

#
# This will be run in a swift-proxy node without the
# ring-builder recipe. It won't compute the rings.
# I won't run if the node is a ring-builder node also.
#
# If the ring-builder isn't running, the cookbook will fail 
# here
#
execute "copy rings from ring-builder node" do
  Chef::Log.info "Fetching rings from ring-builder #{node[:swift][:ring_builder_ip]}"
  command "rsync -az #{node[:swift][:ring_builder_ip]}::ring/*.ring.gz /etc/swift/"
  not_if { node.run_list.include?("recipe[swift::ring-builder]") }
end

#
# Fix permissions just in case
#
execute "swift permissions on /etc/swift/" do
  command "chown -R swift:swift /etc/swift"
end

#
# Start the service
#
service "swift-proxy" do
  action [:enable, :start ]
  subscribes :restart, resources(:template => "/etc/swift/proxy-server.conf")
  provider Chef::Provider::Service::Upstart
  only_if { File.exist?("/etc/swift/object.ring.gz") }
end
