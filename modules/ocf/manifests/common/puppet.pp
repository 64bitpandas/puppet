class ocf::common::puppet {

  package { ['facter', 'puppet']:
    ensure  => latest,
    require => Exec['aptitude update']
  }
  exec { 'puppet-fix_bug7680':
    command => 'sed -i "s/metadata.links == :manage/resource[:links] == :manage/g" /usr/lib/ruby/vendor_ruby/puppet/type/file/source.rb',
    onlyif  => 'grep "metadata.links == :manage" /usr/lib/ruby/vendor_ruby/puppet/type/file/source.rb',
    require => Package['puppet'],
  }

  # enable puppet agent
  file { '/etc/default/puppet':
    content => 'START=yes',
    notify  => Service['puppet'],
  }

  # configure puppet agent
  # set environment to match server and disable cached catalog on failure
  augeas { '/etc/puppet/puppet.conf':
    context => '/files/etc/puppet/puppet.conf',
    changes => [
               "set agent/environment $::environment",
               'set agent/usecacheonfailure false',
               ],
    require => Package['augeas-tools', 'libaugeas-ruby', 'puppet'],
    notify  => Service['puppet'],
  }

  service { 'puppet':
    require   => Package['puppet'],
  }

  # create share directories
  file {
    '/opt/share':
      ensure => directory,
    ;
    '/opt/share/puppet':
      ensure  => directory,
      recurse => true,
      purge   => true,
      force   => true,
      backup  => false,
    ;
  }

  # install augeas
  package { [ 'augeas-tools', 'libaugeas-ruby', ]: }

  # install custom scripts
  file {
    '/usr/local/sbin/puppet-ls':
      mode    => 0755,
      source  => 'puppet:///contrib/common/puppet-ls',
      require => Package['puppet'],
  }

}
