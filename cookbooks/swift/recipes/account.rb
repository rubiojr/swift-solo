#
# Copyright 2011, Dell

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

package "swift-account" do
  action [ :install ]
    options "--force-yes"
end

%w{swift-account swift-account-auditor swift-account-reaper swift-account-replicator}.each do |svc|
  service svc do
    action [ :disable ]
  end
end



## temporary workaround for swift-account package issue present in 1.3
## rather than apt-get install (which fails)
#execute "get swift-account" do
#  command "apt-get install --allow-unauthenticated -d swift-account" # This will fail, but it gets the image local
#  returns 100 
#end
#execute "force install" do
#  command 'dpkg --force-overwrite -i "/var/cache/apt/archives/swift-account_1.3-rc+bzr266-0ubuntu0ppa1~maverick1_all.deb"' 
#end
