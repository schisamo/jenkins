#
# Cookbook Name:: jenkins
# Provider:: master
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

use_inline_resources

def load_current_resource
  new_resource.user
  new_resource.group
  new_resource.home
  new_resource.log_dir
  new_resource.port

  new_resource.url
  new_resource.version
  new_resource.checksum
  @run_context.include_recipe 'runit'
  @run_context.include_recipe 'java::openjdk'
end

action :create do
  @run_context.include_recipe 'runit'
  @run_context.include_recipe 'java::openjdk'
  create_user_and_group
  fetch_jenkins_war
  # create_service_script
  service_test(:nothing)
  new_resource.updated_by_last_action(true)
end

action :enable do
  # enable_service
  service_test(:enable)
  new_resource.updated_by_last_action(true)
end

action :destroy do
  disable_service
  new_resource.updated_by_last_action(true)
end

action :restart do
  # restart_service
  service_test(:restart)
  new_resource.updated_by_last_action(true)
end

private

def fetch_jenkins_war
  war_path = jenkins_war_path(new_resource.home, new_resource.version)
  home_dir = new_resource.home
  data_dir = new_resource.data_dir
  plugins_dir = ::File.join(data_dir, "plugins")
  log_dir = new_resource.log_dir
  [
    home_dir,
    data_dir,
    plugins_dir,
    log_dir
  ].each do |dir_name|
    directory dir_name do
      owner new_resource.user
      group new_resource.group
      mode  00755
      recursive true
    end
  end
  remote_file war_path do
    source new_resource.url
    checksum new_resource.checksum
    owner new_resource.user
    group new_resource.group
    mode 00644
  end
end

def create_user_and_group
  group new_resource.group

  user new_resource.user do
    gid new_resource.group
  end
end

def service_test(a)

  ruby_block "block_until_operational" do
    block do
      Chef::Log.info "Waiting until Jenkins is listening on port #{new_resource.port}"
      until JenkinsHelper.service_listening?(new_resource.port) do
        sleep 1
        Chef::Log.debug(".")
      end

      Chef::Log.info "Waiting until the Jenkins API is responding"
      test_url = URI.parse("http://localhost:#{new_resource.port}/api/json")
      until JenkinsHelper.endpoint_responding?(test_url) do
        sleep 1
        Chef::Log.debug(".")
      end
    end
    action :nothing
  end

  war_path = jenkins_war_path(new_resource.home, new_resource.version)
  runit_service jenkins_service(new_resource.name) do
    cookbook 'jenkins'
    run_template_name 'jenkins'
    log_template_name 'jenkins'
    action a
    options(
      :home => new_resource.home,
      :war_path => war_path,
      :data_dir => new_resource.data_dir,
      :name => new_resource.name,
      :user => new_resource.user,
      :port => new_resource.port
    )
    notifies :create, "ruby_block[block_until_operational]", :immediately
  end
end

def create_service_script
  war_path = jenkins_war_path(new_resource.home, new_resource.version)
  runit_service jenkins_service(new_resource.name) do
    cookbook 'jenkins'
    run_template_name 'jenkins'
    log_template_name 'jenkins'
    action :nothing
    options(
      :home => new_resource.home,
      :war_path => war_path,
      :data_dir => new_resource.data_dir,
      :name => new_resource.name,
      :user => new_resource.user,
      :port => new_resource.port
    )
  end
end

def enable_service
  runit_service jenkins_service(new_resource.name) do
    action [:enable, :start]
    notifies :create, "ruby_block[block_until_operational]", :immediately
  end

  ruby_block "block_until_operational" do
    block do
      Chef::Log.info "Waiting until Jenkins is listening on port #{new_resource.port}"
      until JenkinsHelper.service_listening?(new_resource.port) do
        sleep 1
        Chef::Log.debug(".")
      end

      Chef::Log.info "Waiting until the Jenkins API is responding"
      test_url = URI.parse("http://localhost:#{new_resource.port}/api/json")
      until JenkinsHelper.endpoint_responding?(test_url) do
        sleep 1
        Chef::Log.debug(".")
      end
    end
    action :nothing
  end
end

def disable_service
  runit_service jenkins_service(new_resource.name) do
    action [:disable, :stop]
  end
end

def restart_service
  runit_service jenkins_service(new_resource.name) do
    action :restart
  end.run_action(:restart)
end

# Name/Path Helpers

def jenkins_service(instance_name)
  "jenkins_#{instance_name}"
end

def jenkins_war_path(instance_home, version)
  ::File.join(instance_home, "jenkins_#{version}.war")
end
