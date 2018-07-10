Puppet::Type.newtype(:grafana_user) do
  @doc = 'Manage users in Grafana'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The username of the user.'
  end

  newparam(:grafana_api_path) do
    desc 'The absolute path to the API endpoint'
    defaultto '/api'

    validate do |value|
      unless value =~ %r{^/.*/?api$}
        raise ArgumentError, format('%s is not a valid API path', value)
      end
    end
  end

  newparam(:grafana_url) do
    desc 'The URL of the Grafana server'
    defaultto ''

    validate do |value|
      unless value =~ %r{^https?://}
        raise ArgumentError, format('%s is not a valid URL', value)
      end
    end
  end

  newparam(:grafana_user) do
    desc 'The username for the Grafana server'
  end

  newparam(:grafana_password) do
    desc 'The password for the Grafana server'
  end

  newparam(:org_roles) do
    desc 'The organisations and roles for the user'
  end

  newparam(:full_name) do
    desc 'The full name of the user.'
  end

  newproperty(:password) do
    desc 'The password for the user'
  end

  newproperty(:email) do
    desc 'The email for the user'
  end

  newproperty(:theme) do
    desc 'The theme for the user'
  end

  newproperty(:is_admin) do
    desc 'Whether the user is a grafana admin'
    newvalues(:true, :false)
    defaultto :false
  end

  autorequire(:service) do
    'grafana-server'
  end
end
