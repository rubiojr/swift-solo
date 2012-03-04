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

local_ip = Evaluator.get_ip_by_type(node, :storage_ip_expr)

bash "swift-proxy: creating default rings" do
  cwd "/etc/swift"
  code <<-EOH
    swift-ring-builder object.builder create 18 1 1
    swift-ring-builder container.builder create 18 1 1
    swift-ring-builder account.builder create 18 1 1
  EOH
  not_if { File.exist?("/etc/swift/object.builder") }
end

bash "swift-proxy: adding local node to the rings" do
  cwd "/etc/swift"
  code <<-EOH
    swift-ring-builder object.builder add z#{node[:swift][:zone]}-#{local_ip}:6000/sdb1 1
    swift-ring-builder container.builder add z#{node[:swift][:zone]}-#{local_ip}:6001/sdb1 1
    swift-ring-builder account.builder add z#{node[:swift][:zone]}-#{local_ip}:6002/sdb1 1
    swift-ring-builder object.builder rebalance
    swift-ring-builder container.builder rebalance
    swift-ring-builder account.builder rebalance
  EOH
  not_if { File.exist?("/etc/swift/object.builder") }
end

execute "swift permissions on /srv/" do
  command "chown -R swift:swift /etc/swift"
end

