#
# Copyright 2011, Dell
#
# Modified by Sergio Rubio, BVox.net
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
# Author: andi abes
#
#include_recipe 'snmp'
#node[:snmp][:full_systemview] = "set"

include_recipe 'munin::client'

include_recipe 'apt'

cookbook_file "/root/resetswift" do
  source "resetswift"
end

package 'curl'
package 'openssh-server'
package 'swift'

user "swift" do
  supports :manage_home => true
  action [ :create ]
  home "/home/swift"
  shell "/bin/bash"
  comment "swift User"
  #system true
end

directory "/etc/swift" do
  action :create
  owner "swift"
  group "swift"
  mode "0755"
end

template "/etc/swift/swift.conf" do
  owner "swift"
  group "swift"
  source "swift.conf.erb"  
 variables( {
       :swift_hash_path_suffix => node[:swift][:swift_hash_path_suffix]
 })
end

directory "/root/.ssh" do
  action :create
  owner "root"
  group "root"
  mode "0700"
  recursive true
end

#%w{ authorized_keys }.each do |key|
#  cookbook_file "/root/.ssh/#{key}" do
#    source key
#    owner "root"
#    group "root"
#    mode "0600"
#  end
#end

# change some kernel params to support mad fast networking
# and lots of connections
execute "sysctl_reload" do
  command "sysctl -p"
  action :nothing
end

cookbook_file "/etc/sysctl.d/20-openstack-swift.conf" do
  source "20-openstack-swift-sysctl.conf"
  mode "0644"
  notifies :run, resources(:execute => "sysctl_reload"), :immediately
end


# rsync needs a nice clean /etc/hosts file so it doesn't look everything up all the time
hosts_hash = {}
env_filter = " AND swift_config_environment:#{node[:swift][:config][:environment]}"
all_swift_nodes = search(:node, "roles:swift-*#{env_filter}")
all_swift_nodes.each { |swnode|
    storage_ip = Evaluator.get_ip_by_type(swnode, :storage_ip_expr)
    admin_ip = Evaluator.get_ip_by_type(swnode, :admin_ip_expr)

    hosts_hash[storage_ip] = swnode[:hostname] 
    hosts_hash[admin_ip] = swnode[:hostname] 
}

node.set[:hosts][:entries] = hosts_hash
include_recipe 'hosts'

directory "/var/log/swift/hourly" do 
  group       "adm"
  owner       "syslog"
  mode        "2755"
  recursive  true
end

