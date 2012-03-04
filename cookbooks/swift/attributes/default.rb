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
### The cluster hash is shared among all nodes in a swift cluster.
### can be generated using od -t x8 -N 8 -A n </dev/random
#default[:swift][:cluster_hash]="fa8bea159b55bd7e"
default[:swift][:swift_hash_path_suffix]="xxxxxxxxxxxxxxxx"
### super user password - used for managing users.
default[:swift][:cluster_admin_pw]= "testpass"
### how many replicas should be made for each object
default[:swift][:replicas]= 3
## minimum amount of time a partition should stay put, in hours
default[:swift][:min_part_hours]= 1
## number of bits to represent the partitions count 
default[:swift][:partitions]= 18

### the uid/gid to be used for swift processes
default[:swift][:user]= "swift"
default[:swift][:group]= "swift"
override[:swift][:log_level] = "INFO"

default[:swift][:swift_account]= "AUTH_<hash_from_slog_account>"
default[:swift][:swift_user]= "syslog"
default[:swift][:swift_passwd]= "<password>"
default[:swift][:os_user]= "syslog"

default[:swift][:config] = {}
default[:swift][:config][:environment] = "default"

### where to find IP for admin use (public IPs)
#default[:swift][:admin_ip_expr] = "node[:ipaddress]" 
#default[:swift][:admin_ip_expr] = "get_ip_by_interface(node,'eth0')"w
# the eth0 interfaces are public - admin server could also be private, if you like
default[:swift][:admin_ip_expr] = "node['network']['interfaces']['eth0']['addresses'].select { |address, data| data['family'] == 'inet' }[0][0]"
#default[:swift][:admin_ip_expr] = "node[:ipaddress]" 

### where to find IP for admin use (private IPs)
#default[:swift][:storage_ip_expr] = "node[:ipaddress]" 
#default[:swift][:storage_ip_expr] = "get_ip_by_interface(node,'eth1')"
default[:swift][:storage_ip_expr] = "node['network']['interfaces']['eth1']['addresses'].select { |address, data| data['family'] == 'inet' }[0][0]"
#default[:swift][:storage_ip_expr] = "node[:ipaddress]" 

# expression to find a hash of possible disks to be used.
default[:swift][:disk_enum_expr]= 'node[:block_device]'
# expression accepting a k,v pair for evaluation. if expression returns true, then the disk will be used.
# by default, use any sdX or hdX that is not the first one (which will hold the OS).
default[:swift][:disk_test_expr]= 'k =~/sd[^a]/ or k=~/hd[^a]/'      

# repo stuff
#default[:swift][:repo][:name] = 'swift-core-ppa'
#default[:swift][:repo][:uri] = 'http://ppa.launchpad.net/swift-core/release/ubuntu'
#default[:swift][:repo][:keyserver] = 'keyserver.ubuntu.com'
#default[:swift][:repo][:key] = '3FD32ED0E38B0CFA59495557C842BD46562598B4'

# this is the current stable build from Rackspace
default[:swift][:repo][:name] = 'crashsite'
default[:swift][:repo][:uri] = 'http://crashsite.github.com/swift_debian/lucid'

# it makes little sense to update the :app_environment (munin recipe) 
# from this place.  I have to address this elsewhere
override[:app_environment] = "munin_#{node[:swift][:swift_hash_path_suffix]}"

default[:swift][:storage_nodes] = {}
default[:swift][:ring_builder_ip] = "127.0.0.1"
default[:swift][:proxy_admin_password] = "$admin$"
