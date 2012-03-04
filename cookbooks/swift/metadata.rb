#
# Original cookbook from Andi Abes, Judd Maltin
#
# Copyright 2011, Dell
#
# Heavily tweaked to work with knife/chef-solo
# by Sergio Rubio <rubiojr@frameos.org>
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

maintainer       "Sergio Rubio"
maintainer_email "rubiojr@frameos.org"
license          "Apache 2.0"
description      "Installs/Configures OpenStack Swift"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1"
depends          "memcached"
depends          "apt"
depends          "munin"
depends          "ntp"
depends          "hosts"

supports "ubuntu", ">= 12.04"
