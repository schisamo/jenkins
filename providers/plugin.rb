#
# Cookbook Name:: jenkins
# Provider:: plugin
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

def load_current_resource
  new_resource.name
  new_resource.version
  new_resource.path
  new_resource.url
  new_resource.master
end

action :install do
  fetch_jenkins_plugin(:create_if_missing)
  new_resource.updated_by_last_action(true)
end

action :update do
  fetch_jenkins_plugin(:nothing)
  check_for_updated_version
  new_resource.updated_by_last_action(true)
end

action :remove do
  delete_plugin
end

private

def fetch_jenkins_plugin(action)
  plugin_path = jenkins_plugin_path
  plugin_url = jenkins_plugin_url
  remote_file plugin_path do
    source plugin_url
    owner new_resource.master.user if new_resource.master
    group new_resource.master.group if new_resource.master
    backup false
    action action
  end
end

def check_for_updated_version
  plugin_path = jenkins_plugin_path
  plugin_url = jenkins_plugin_url
  http_request "HEAD #{plugin_url}" do
    message ""
    url plugin_url
    action :head
    if File.exists?(path)
      headers "If-Modified-Since" => File.mtime(plugin_path).httpdate
    end
    notifies :create, "remote_file[#{plugin_path}]", :immediately
  end
end

def delete_plugin
  plugin_path = jenkins_plugin_path
  file plugin_path do
    action :delete
  end
end

# Name/Path Helpers

def jenkins_plugin_path
  if new_resource.path.nil?
    # TODO - better validation
    raise "You need to declare a master" if new_resource.master.nil?
    ::File.join(new_resource.master.data_dir, "plugins", "#{new_resource.name}.hpi")
  else
    new_resource.path
  end
end

def jenkins_plugin_url
  if new_resource.url.nil?
    version = new_resource.version || 'latest'
    url = "http://mirrors.jenkins-ci.org"
    url << "/plugins/#{new_resource.name}/#{version}/#{new_resource.name}.hpi"
    url
  else
    new_resource.url
  end
end
