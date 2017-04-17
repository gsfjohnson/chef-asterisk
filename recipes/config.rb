#
# Cookbook Name:: asterisk
# Recipe:: config
#

def data_bag_items(bag_name)
  begin
    data_bag(bag_name).map do |id|
      return data_bag_item bag_name, id
    end
  rescue Net::HTTPServerException
    return {}
  end
end

users = data_bag_items(:asterisk_users)
dialplan_contexts = data_bag_items(:asterisk_contexts)
config_dir = "#{node['asterisk']['prefix']['conf']}/asterisk"

if ['rhel', 'fedora'].include?(node['platform_family'])
  lib_dir = node['kernel']['machine'] == 'x86_64' ? 'lib64' : 'lib'
else
  lib_dir = 'lib'
end

directory config_dir

template "#{config_dir}/asterisk.conf" do
  source 'asterisk.conf.erb'
  mode 0644
  notifies :reload, resources('service[asterisk]')
  variables(
    :lib_dir => lib_dir
  )
end

%w{sip manager extensions}.each do |template_file|
  template "#{config_dir}/#{template_file}.conf" do
    source "#{template_file}.conf.erb"
    mode 0644
    variables :users => users, :dialplan_contexts => dialplan_contexts
    notifies :reload, resources('service[asterisk]')
  end
end
