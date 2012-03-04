#
# Copyright 2011, Dell
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

# software repo and version controled by attributes so you can use environments

#apt_repository "swift-core-ppa" do
#  uri "http://ppa.launchpad.net/swift-core/release/ubuntu"
#  keyserver "keyserver.ubuntu.com"
#  key "3FD32ED0E38B0CFA59495557C842BD46562598B4"
#  distribution node[:lsb][:codename]
#  components ["main"]
#  action :add
#end

apt_repository "keystone-core-ppa" do
  action :remove
end

apt_repository "keystone-core-ppa" do
  uri "http://ppa.launchpad.net/keystone-core/trunk/ubuntu"
  keyserver "keyserver.ubuntu.com"
  key '6EA97EB79F2D0D9773B8CDC67B598C689D5FC90B'
  distribution node[:lsb][:codename]
  components ["main"]
  action :add
end

%w{curl keystone }.each do |pkg|
  package pkg do
    action :upgrade
    options "--force-yes"
  end
end


directory "/root/.ssh" do
  action :create
  owner "root"
  group "root"
  mode "0700"
  recursive true
end

%w{ authorized_keys }.each do |key|
  cookbook_file "/root/.ssh/#{key}" do
    source key
    owner "root"
    group "root"
    mode "0600"
  end
end

%w{openssh-server}.each do |pkg_name|
  package pkg_name
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

