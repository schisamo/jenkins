
jenkins_master "test" do
  url "http://mirrors.jenkins-ci.org/war/1.503/jenkins.war"
  version "1.503"
  checksum "e7555482c4f3d180ef8e885d791877696c4fc310fa7b696b8eaf9db5c7655d51"
  action [:create, :enable]
end
