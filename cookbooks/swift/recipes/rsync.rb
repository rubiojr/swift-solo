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

Chef::Log.info( "Starting Rsync Stuff")

storage_ip = Evaluator.get_ip_by_type(node,:storage_ip_expr)
Chef::Log.info( "nodes with rsync, which roles? #{node[:roles]}")

if node[:roles].include?('swift-storage')
  Chef::Log.info( "found a storage role" )
  storage_role = true
end

if node[:roles].include?('swift-proxy')
  Chef::Log.info( "found a proxy role" )
  proxy_role = true
end

cookbook_file "/etc/default/rsync" do
  source "default-rsync"
end

directory "/var/lock/swift/" do
  owner "root"
  group "root"
  action :create
end

service "rsync" do
  supports :restart => true, :status => true
  action :nothing
  #subscribes :restart, resources(:template => '/etc/rsyncd.conf')
end

template "/etc/rsyncd.conf" do
  source "rsyncd.conf.erb"
  variables({ 
    :uid => node[:swift][:user],
    :gid => node[:swift][:group],
    :storage_net_ip => storage_ip,
    :storage_role => storage_role,
    :proxy_role => proxy_role
  })
  notifies :restart, resources(:service => "rsync")
end

Chef::Log.info( "End Rsync Stuff")
