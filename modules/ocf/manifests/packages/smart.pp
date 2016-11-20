class ocf::packages::smart {
  # install smartmontools
  package { 'smartmontools': }

  file {
    # enable smartd
    '/etc/default/smartmontools':
      content => 'start_smartd=yes',
      require => Package['smartmontools'],
      notify  => Service['smartmontools'],
    ;
    # configure smartd to monitor all devices and mail root
    # monitor most attributes except ordinary temperature changes
    '/etc/smartd.conf':
      content => 'DEVICESCAN -d removable -a -I 194 -W 0,45,55 -m root',
      require => Package['smartmontools'],
      notify  => Service['smartmontools'],
    ;
  }

  service { 'smartmontools':
    require   => Package['smartmontools'],
  }
}
