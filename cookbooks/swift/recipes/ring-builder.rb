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

%w{ object container account }.each do |s|
  execute "create #{s}.builder" do
    cwd "/etc/swift"
    command "swift-ring-builder #{s}.builder create #{node[:swift][:partitions]} #{node[:swift][:replicas]} #{node[:swift][:min_part_hours]}"
    not_if { File.exist?("/etc/swift/#{s}.builder") }
  end
end

( node[:swift][:storage_nodes] || [] ).each do |snode|
  %w{ object:6000 container:6001 account:6002 }.each do |s|
    node_ip = snode.first
    node_values = snode.last
    server_name = s.split(":").first
    server_port = s.split(":").last
    execute "ring-builder: adding node #{node_ip}" do
      Chef::Log.info "adding z#{node_values[:zone]}-#{node_ip}:#{server_port}/#{node_values[:dev]} #{node_values[:weight]}"
      cwd "/etc/swift"
      command "swift-ring-builder #{server_name}.builder add z#{node_values[:zone]}-#{node_ip}:#{server_port}/#{node_values[:dev]} #{node_values[:weight]}"
      not_if { File.exist?("/etc/swift/#{server_name}.ring.gz") }
    end
  end
end

%w{ object container account }.each do |s|
  execute "ring-builder: rebalancing #{s}.builder" do
    cwd "/etc/swift"
    command "swift-ring-builder #{s}.builder rebalance"
    not_if { File.exist?("/etc/swift/#{s}.ring.gz") }
  end
end
 
execute "swift permissions on /etc/swift/" do
  command "chown -R swift:swift /etc/swift"
end
