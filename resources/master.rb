#
# Cookbook Name:: jenkins
# Resource:: master
#
# Author:: Seth Chisamore <schisamo@opscode.com>
#
# Copyright 2013, Opscode, Inc.
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

actions :create, :destroy, :enable, :restart

def initialize(*args)
  super
  @action = :create
end

attribute :name, :kind_of => String, :name_attribute => true
attribute :user, :kind_of => String, :default => 'jenkins'
attribute :group, :kind_of => String, :default => 'jenkins'

attribute :home, :kind_of => String, :default => '/opt/jenkins'
attribute :data_dir, :kind_of => String, :default => '/opt/jenkins/data'
attribute :log_dir, :kind_of => String, :default => '/var/log/jenkins'
attribute :port, :kind_of => Integer, :default => 8080

# attribute :conf_dir, :kind_of => String, :default => '/etc/logstash'
# attribute :dst_dir, :kind_of => String, :default => '/opt/logstash'

attribute :url, :kind_of => String, :required => true
attribute :version, :kind_of => String, :default => '1.503'
attribute :checksum, :kind_of => String, :required => true

# attribute :checksum, :kind_of => String, :required => true
# attribute :nofiles, :kind_of => Fixnum, :default => 1024
