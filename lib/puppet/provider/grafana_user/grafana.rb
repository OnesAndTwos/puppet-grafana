require 'json'
require 'uri'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'grafana'))

Puppet::Type.type(:grafana_user).provide(:grafana, parent: Puppet::Provider::Grafana) do
  desc 'Support for Grafana users'

  defaultfor kernel: 'Linux'

  def users
    response = send_request('GET', format('%s/users', resource[:grafana_api_path]))

    begin
      users = JSON.parse(response.body)

      users.map { |x| x['id'] }.map do |id|
        response = send_request('GET', format('%s/users/%s', resource[:grafana_api_path], id))

        user = JSON.parse(response.body)
        {
            id: id,
            name: user['login'],
            full_name: user['name'],
            email: user['email'],
            theme: user['theme'],
            password: nil,
            is_admin: user['isGrafanaAdmin'] ? :true : :false
        }
      end
    rescue JSON::ParserError
      raise format('Fail to parse response: %s', response.body)
    end
  end

  def user
    @user = users.find { |x| x[:name] == resource[:name] } unless @user
    @user
  end

  attr_writer :user

  def name
    user[:name]
  end

  def name=(value)
    resource[:name] = value
    save_user
  end

  def full_name
    user[:full_name]
  end

  def full_name=(value)
    resource[:full_name] = value
    save_user
  end

  def email
    user[:email]
  end

  def email=(value)
    resource[:email] = value
    save_user
  end

  def theme
    user[:theme]
  end

  def theme=(value)
    resource[:theme] = value
    save_user
  end

  def password
    user[:password]
  end

  def password=(value)
    resource[:password] = value
    save_user
  end

  # rubocop:disable Style/PredicateName
  def is_admin
    user[:is_admin]
  end

  def is_admin=(value)
    resource[:is_admin] = value
    save_user
  end
  # rubocop:enable Style/PredicateName

  def save_user
    is_admin = resource[:is_admin] == :true
    data = {
        login: resource[:name],
        name: resource[:full_name],
        email: resource[:email],
        password: resource[:password],
        theme: resource[:theme]
    }

    if user.nil?
      send_request 'POST', "#{resource[:grafana_api_path]}/admin/users", data
    else
      send_request 'PUT', "#{resource[:grafana_api_path]}/users/#{user[:id]}", data
    end

    send_request 'PUT', "#{resource[:grafana_api_path]}/admin/users/#{user[:id]}/password", password: data[:password]
    send_request 'PUT', "#{resource[:grafana_api_path]}/admin/users/#{user[:id]}/permissions", isGrafanaAdmin: is_admin

    resource[:org_roles].each_pair do |org_name, role_name|

      org_response = send_request 'GET', "#{resource[:grafana_api_path]}/orgs/name/#{URI::encode(org_name)}"
      organisation = JSON.parse(org_response.body, symbolize_names: true)
      send_request 'PATCH', "#{resource[:grafana_api_path]}/orgs/#{organisation[:id]}/users/#{user[:id]}", role: role_name

    end

    self.user = nil
  end

  def delete_user
    send_request('DELETE', format('%s/admin/users/%s', resource[:grafana_api_path], user[:id]))
    self.user = nil
  end

  def create
    save_user
  end

  def destroy
    delete_user
  end

  def exists?
    user

  end
end